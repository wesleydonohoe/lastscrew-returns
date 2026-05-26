# Cloudflare Workers × Subconscious — Hackathon Starter

Build an AI agent on Cloudflare Workers that runs on **cron**, **API calls**, **webhooks**, or a **dashboard button** — powered by the [Subconscious API](https://docs.subconscious.dev).

## Quick start

### 1. Install dependencies

```bash
npm install
```

### 2. Add your Subconscious API key

Get a key at [subconscious.dev/platform](https://www.subconscious.dev/platform), then:

```bash
cp .dev.vars.example .dev.vars
# Edit .dev.vars and set SUBCONSCIOUS_API_KEY
```

### 3. Create a KV namespace (for agent config + run history)

```bash
npx wrangler kv namespace create AGENT_KV
npx wrangler kv namespace create AGENT_KV --preview
```

Copy the `id` values into `wrangler.toml` under `[[kv_namespaces]]`.

### 4. Run locally

```bash
npm run dev
```

Open [http://localhost:8787](http://localhost:8787) for the dashboard.

### 5. Deploy

```bash
npm run deploy
```

Set production secrets:

```bash
npx wrangler secret put SUBCONSCIOUS_API_KEY
# Optional webhook auth:
npx wrangler secret put WEBHOOK_SECRET
```

---

## Install the Subconscious skill (for AI assistants)

Give Cursor, Claude Code, or Codex deep knowledge of the Subconscious API:

```bash
npx skills add https://github.com/subconscious-systems/skills --skill subconscious-dev
```

This repo already includes the skill at `.agents/skills/subconscious-dev/`. See [AGENTS.md](./AGENTS.md) for architecture notes.

---

## What's included

| Feature | How it works |
|---------|----------------|
| **AI agent** | OpenAI-compatible chat completions against `api.subconscious.dev/v1` with a local tool loop |
| **Manage logic** | Edit system prompt, instructions, tools, and thinking mode via dashboard or `PUT /api/agent/config` (stored in KV) |
| **Button trigger** | Dashboard "Run now" → `POST /api/run` |
| **API trigger** | `POST /api/run` with optional `{ "instructions": "..." }` |
| **Webhook trigger** | `POST /api/webhook` with event payload (optional `x-webhook-secret` header) |
| **Cron trigger** | Scheduled via `wrangler.toml` — runs hourly by default |

---

## Project structure

```
src/
  index.ts              # Hono routes + cron handler
  types.ts              # Agent config types + defaults
  subconscious/client.ts  # Subconscious API wrapper
  agent/
    runner.ts           # Agent tool loop
    tools.ts            # Example tools — add yours here
    store.ts            # KV persistence
public/
  index.html            # Hackathon dashboard
.agents/skills/
  subconscious-dev/     # Bundled Subconscious API skill
```

---

## API reference

### `GET /api/agent/config`

Returns the current agent configuration.

### `PUT /api/agent/config`

Update agent logic. Example:

```bash
curl -X PUT http://localhost:8787/api/agent/config \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Agent",
    "systemPrompt": "You are a research assistant.",
    "instructions": "Summarize the top 3 AI news stories.",
    "enabledTools": ["get_time", "fetch_url"],
    "enableThinking": false
  }'
```

### `POST /api/run`

Trigger the agent manually:

```bash
curl -X POST http://localhost:8787/api/run \
  -H "Content-Type: application/json" \
  -d '{"instructions": "What should our team build next?"}'
```

### `POST /api/webhook`

Trigger from an external event (GitHub, Stripe, custom service):

```bash
curl -X POST http://localhost:8787/api/webhook \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: your-secret" \
  -d '{
    "event": "issue.created",
    "payload": { "title": "Add dark mode", "repo": "hackathon-demo" }
  }'
```

### `GET /api/runs`

List recent agent runs with outputs and token usage.

---

## Customize for your hackathon

### Add a tool

Edit `src/agent/tools.ts`:

```typescript
export const TOOL_REGISTRY = {
  my_tool: {
    name: "my_tool",
    description: "What this tool does",
    parameters: { type: "object", properties: { query: { type: "string" } }, required: ["query"] },
    execute: async (args) => ({ result: `You asked: ${args.query}` }),
  },
  // ...
};
```

Enable it in the dashboard or set `enabledTools: ["my_tool"]` in config.

### Change the cron schedule

Edit `wrangler.toml`:

```toml
[triggers]
crons = ["*/15 * * * *"]  # every 15 minutes
```

Update `cronInstructions` in config for scheduled-specific behavior.

### Enable deep reasoning

Set `enableThinking: true` in config. The model prepends a thinking preamble (slower, more tokens). See the skill docs for details.

---

## Subconscious API

- **Base URL:** `https://api.subconscious.dev/v1`
- **Model:** `subconscious/tim-qwen3.6-27b`
- **Auth:** `Authorization: Bearer $SUBCONSCIOUS_API_KEY`
- **Tools:** Standard OpenAI function calling — executed in your Worker, not server-side

Docs: [docs.subconscious.dev](https://docs.subconscious.dev) · Playground: [subconscious.dev/playground](https://www.subconscious.dev/playground)

---

## Hackathon ideas

- **On-call agent** — webhook from PagerDuty → agent triages and posts to Slack
- **Daily standup bot** — cron pulls GitHub issues → agent writes standup summary
- **Research scout** — cron + `fetch_url` tool monitors sources and logs findings
- **Event responder** — API endpoint users hit to get personalized recommendations

---

## License

MIT — build something great at the hackathon!
