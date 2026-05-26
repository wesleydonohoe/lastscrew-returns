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

  search_catalog: {
    name: "search_catalog",
    description:
      "Search mock Wayfair furniture by room, style, or keyword. Returns SKU, price, and dimensions.",
    parameters: {
      type: "object",
      properties: {
        query: { type: "string", description: "Search terms, e.g. mid-century desk" },
        room: {
          type: "string",
          enum: ["living", "bedroom", "office", "dining", "outdoor"],
          description: "Room type filter",
        },
        maxPrice: { type: "number", description: "Maximum price in USD" },
      },
      required: ["query"],
    },
    execute: async (args) => {
      const query = String(args.query ?? "").toLowerCase();
      const room = args.room ? String(args.room) : undefined;
      const maxPrice =
        typeof args.maxPrice === "number" ? args.maxPrice : undefined;

      const catalog = [
        {
          sku: "WF-1001",
          name: "Mid-Century Writing Desk",
          room: "office",
          style: "mid-century",
          price: 349,
          dimensions: '48"W x 24"D x 30"H',
        },
        {
          sku: "WF-1002",
          name: "Scandinavian Platform Bed",
          room: "bedroom",
          style: "scandinavian",
          price: 499,
          dimensions: 'Queen 63"W x 83"L',
        },
        {
          sku: "WF-1003",
          name: "Velvet Sectional Sofa",
          room: "living",
          style: "modern",
          price: 899,
          dimensions: '112"W x 70"D',
        },
        {
          sku: "WF-1004",
          name: "Farmhouse Dining Table",
          room: "dining",
          style: "farmhouse",
          price: 629,
          dimensions: '72"W x 40"D x 30"H',
        },
        {
          sku: "WF-1005",
          name: "Compact Home Office Desk",
          room: "office",
          style: "modern",
          price: 199,
          dimensions: '40"W x 20"D x 29"H',
        },
      ];

      let results = catalog.filter((item) => {
        const haystack = `${item.name} ${item.style} ${item.room}`.toLowerCase();
        return haystack.includes(query) || query.split(" ").some((w) => haystack.includes(w));
      });

      if (room) {
        results = results.filter((item) => item.room === room);
      }
      if (maxPrice !== undefined) {
        results = results.filter((item) => item.price <= maxPrice);
      }

      return { query, count: results.length, results: results.slice(0, 5) };
    },
  },

  fetch_url: {
    name: "fetch_url",
    description: "Fetch text content from a public HTTPS URL",
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

export function getEnabledTools(enabledTools: string[]): ToolDefinition[] {
  return enabledTools
    .filter((name) => TOOL_REGISTRY[name])
    .map((name) => TOOL_REGISTRY[name]);
}

export async function executeTool(
  name: string,
  args: Record<string, unknown>,
): Promise<string> {
  const tool = TOOL_REGISTRY[name];
  if (!tool) {
    return JSON.stringify({ error: `Unknown tool: ${name}` });
  }

  try {
    const result = await tool.execute(args);
    return JSON.stringify(result);
  } catch (error) {
    return JSON.stringify({
      error: error instanceof Error ? error.message : "Tool execution failed",
    });
  }
}
