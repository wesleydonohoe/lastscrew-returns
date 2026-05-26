import { Hono } from "hono";
import { cors } from "hono/cors";
import {
  executeAgentRun,
  getAgentConfig,
  getRun,
  listRecentRuns,
  saveAgentConfig,
} from "./agent/store";
import { TOOL_REGISTRY, getMockItem, listMockItems } from "./agent/tools";
import { computeHostOffer } from "./lastscrew/offer";
import { runPackagingQA } from "./baseten/client";
import type { AgentConfig, Env } from "./types";

const app = new Hono<{ Bindings: Env }>();

app.use("/api/*", cors());

app.get("/api/health", (c) => {
  return c.json({
    ok: true,
    service: "lastscrew-worker",
    subconscious: Boolean(c.env.SUBCONSCIOUS_API_KEY),
    baseten: Boolean(c.env.BASETEN_API_KEY && c.env.BASETEN_MODEL_ID),
  });
});

// ── lastscrew product endpoints ───────────────────────────────────────────────

app.get("/api/lastscrew/items", (c) => {
  return c.json({
    user: { firstName: "Wes", rewardsBalance: 95.04 },
    items: listMockItems(),
  });
});

app.get("/api/lastscrew/items/:orderId", (c) => {
  const item = getMockItem(c.req.param("orderId"));
  if (!item) return c.json({ error: "Unknown orderId" }, 404);
  return c.json(item);
});

app.post("/api/lastscrew/offer", async (c) => {
  const body = (await c.req.json().catch(() => ({}))) as {
    orderId?: string;
    zip?: string;
  };
  const orderId = body.orderId ?? "WF-ORDER-8821";
  const zip = body.zip ?? "02116";

  const offer = await computeHostOffer({
    orderId,
    zip,
    apiKey: c.env.SUBCONSCIOUS_API_KEY,
  });
  return c.json(offer);
});

app.post("/api/lastscrew/verify", async (c) => {
  const body = (await c.req.json().catch(() => ({}))) as {
    orderId?: string;
    imageBase64?: string;
    imageUrl?: string;
    photoDescription?: string;
  };

  try {
    const result = await runPackagingQA({
      imageBase64: body.imageBase64,
      imageUrl: body.imageUrl,
      photoDescription: body.photoDescription,
      baseteenApiKey: c.env.BASETEN_API_KEY,
      basetenModelId: c.env.BASETEN_MODEL_ID,
      basetenModelName: c.env.BASETEN_MODEL_NAME,
      basetenEndpoint: (c.env.BASETEN_ENDPOINT as "predict" | "openai" | undefined) ?? "predict",
    });
    return c.json({
      orderId: body.orderId ?? null,
      ...result,
    });
  } catch (error) {
    return c.json(
      {
        error: error instanceof Error ? error.message : "QA failed",
      },
      500,
    );
  }
});

// Demo helper: full flow in one call — handy for curl + agent testing.
app.post("/api/lastscrew/demo", async (c) => {
  const body = (await c.req.json().catch(() => ({}))) as {
    orderId?: string;
    zip?: string;
    photoDescription?: string;
  };
  const orderId = body.orderId ?? "WF-ORDER-8821";
  const zip = body.zip ?? "02116";

  const [offer, qa] = await Promise.all([
    computeHostOffer({ orderId, zip, apiKey: c.env.SUBCONSCIOUS_API_KEY }),
    runPackagingQA({
      photoDescription:
        body.photoDescription ?? "box closed and taped, corners padded, label visible",
      baseteenApiKey: c.env.BASETEN_API_KEY,
      basetenModelId: c.env.BASETEN_MODEL_ID,
      basetenModelName: c.env.BASETEN_MODEL_NAME,
      basetenEndpoint: (c.env.BASETEN_ENDPOINT as "predict" | "openai" | undefined) ?? "predict",
    }),
  ]);

  return c.json({ offer, qa });
});

// ── original agent surface ────────────────────────────────────────────────────

app.get("/api/agent/config", async (c) => {
  const config = await getAgentConfig(c.env.AGENT_KV);
  return c.json(config);
});

app.put("/api/agent/config", async (c) => {
  const body = (await c.req.json()) as Partial<AgentConfig>;
  const config = await saveAgentConfig(c.env.AGENT_KV, body);
  return c.json(config);
});

app.get("/api/agent/tools", (c) => {
  const tools = Object.values(TOOL_REGISTRY).map((tool) => ({
    name: tool.name,
    description: tool.description,
    parameters: tool.parameters,
  }));
  return c.json({ tools });
});

app.get("/api/runs", async (c) => {
  const runs = await listRecentRuns(c.env.AGENT_KV);
  return c.json({ runs });
});

app.get("/api/runs/:id", async (c) => {
  const run = await getRun(c.env.AGENT_KV, c.req.param("id"));
  if (!run) return c.json({ error: "Run not found" }, 404);
  return c.json(run);
});

app.post("/api/run", async (c) => {
  const body = (await c.req.json().catch(() => ({}))) as {
    instructions?: string;
    trigger?: "api" | "button";
  };
  const config = await getAgentConfig(c.env.AGENT_KV);
  const instructions = body.instructions ?? config.instructions;
  const run = await executeAgentRun(c.env, body.trigger ?? "api", instructions);
  return c.json(run, run.status === "failed" ? 500 : 200);
});

app.post("/api/webhook", async (c) => {
  const secret = c.env.WEBHOOK_SECRET;
  if (secret) {
    const provided = c.req.header("x-webhook-secret");
    if (provided !== secret) {
      return c.json({ error: "Unauthorized webhook" }, 401);
    }
  }
  const body = (await c.req.json().catch(() => ({}))) as {
    event?: string;
    instructions?: string;
    payload?: unknown;
  };
  const config = await getAgentConfig(c.env.AGENT_KV);
  const eventName = body.event ?? "webhook";
  const instructions =
    body.instructions ??
    `An external event "${eventName}" was received.\n\nPayload:\n${JSON.stringify(body.payload ?? body, null, 2)}\n\nDecide what action to take and respond with a summary.`;
  const run = await executeAgentRun(c.env, "webhook", instructions);
  return c.json(run, run.status === "failed" ? 500 : 200);
});

async function handleScheduled(env: Env): Promise<void> {
  const config = await getAgentConfig(env.AGENT_KV);
  await executeAgentRun(env, "cron", config.cronInstructions);
}

// Serve the static dashboard from /public for everything else.
app.all("*", async (c) => c.env.ASSETS.fetch(c.req.raw));

export default {
  fetch: app.fetch,
  scheduled: async (
    _event: ScheduledController,
    env: Env,
    ctx: ExecutionContext,
  ) => {
    ctx.waitUntil(handleScheduled(env));
  },
};
