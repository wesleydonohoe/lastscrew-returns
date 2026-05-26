import type { ChatCompletionTool } from "openai/resources/chat/completions";

export interface ToolDefinition {
  name: string;
  description: string;
  parameters: Record<string, unknown>;
  execute: (args: Record<string, unknown>) => Promise<unknown> | unknown;
}

export const TOOL_REGISTRY: Record<string, ToolDefinition> = {
  get_time: {
    name: "get_time",
    description: "Get the current UTC date and time",
    parameters: {
      type: "object",
      properties: {},
    },
    execute: () => ({
      utc: new Date().toISOString(),
      timezone: "UTC",
    }),
  },

  log_note: {
    name: "log_note",
    description: "Save a short note for the hackathon team to review later",
    parameters: {
      type: "object",
      properties: {
        note: { type: "string", description: "The note to save" },
        priority: {
          type: "string",
          enum: ["low", "medium", "high"],
          description: "How urgent this note is",
        },
      },
      required: ["note"],
    },
    execute: async (args) => {
      const note = String(args.note ?? "");
      const priority = String(args.priority ?? "medium");
      return {
        saved: true,
        note,
        priority,
        savedAt: new Date().toISOString(),
      };
    },
  },

  fetch_url: {
    name: "fetch_url",
    description: "Fetch text content from a public URL (demo tool — add your own logic)",
    parameters: {
      type: "object",
      properties: {
        url: { type: "string", description: "HTTPS URL to fetch" },
      },
      required: ["url"],
    },
    execute: async (args) => {
      const url = String(args.url ?? "");
      if (!url.startsWith("https://")) {
        throw new Error("Only HTTPS URLs are allowed");
      }
      const response = await fetch(url, {
        headers: { "User-Agent": "HackathonAgent/1.0" },
      });
      const text = await response.text();
      return {
        url,
        status: response.status,
        preview: text.slice(0, 500),
      };
    },
  },
};

export function getOpenAITools(enabledTools: string[]): ChatCompletionTool[] {
  return enabledTools
    .filter((name) => TOOL_REGISTRY[name])
    .map((name) => {
      const tool = TOOL_REGISTRY[name];
      return {
        type: "function" as const,
        function: {
          name: tool.name,
          description: tool.description,
          parameters: tool.parameters,
        },
      };
    });
}

export async function executeTool(
  name: string,
  argsJson: string,
): Promise<string> {
  const tool = TOOL_REGISTRY[name];
  if (!tool) {
    return JSON.stringify({ error: `Unknown tool: ${name}` });
  }

  try {
    const args = JSON.parse(argsJson) as Record<string, unknown>;
    const result = await tool.execute(args);
    return JSON.stringify(result);
  } catch (error) {
    return JSON.stringify({
      error: error instanceof Error ? error.message : "Tool execution failed",
    });
  }
}
