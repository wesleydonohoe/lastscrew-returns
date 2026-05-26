export interface ToolDefinition {
  name: string;
  description: string;
  parameters: Record<string, unknown>;
  execute: (args: Record<string, unknown>) => Promise<unknown> | unknown;
}

// Mock data store — in a real build this is Wayfair order/inventory/CRM data.
// Keyed by orderId so the iOS demo can drive the whole pricing flow off a single ID.
const MOCK_ITEMS: Record<string, ItemDetails> = {
  "WF-ORDER-8821": {
    orderId: "WF-ORDER-8821",
    sku: "WF-SLP-12MED-Q",
    name: 'Sleep by Wayfair™ 12" Medium Memory Foam Mattress + Platform Bed',
    retailPriceUsd: 549,
    customerPaidUsd: 489,
    assemblyTimeMinutes: 92,
    packagingDifficulty: "medium",
    dimensions: 'Queen 63"W x 83"L x 18"H',
    weightLbs: 142,
    category: "bedroom",
    deliveredAt: "2026-05-17",
    returnReason: "doesnt_fit",
  },
};

export interface ItemDetails {
  orderId: string;
  sku: string;
  name: string;
  retailPriceUsd: number;
  customerPaidUsd: number;
  assemblyTimeMinutes: number;
  packagingDifficulty: "easy" | "medium" | "hard";
  dimensions: string;
  weightLbs: number;
  category: string;
  deliveredAt: string;
  returnReason: string;
}

export function getMockItem(orderId: string): ItemDetails | undefined {
  return MOCK_ITEMS[orderId];
}

export const TOOL_REGISTRY: Record<string, ToolDefinition> = {
  get_time: {
    name: "get_time",
    description: "Get the current UTC date and time",
    parameters: { type: "object", properties: {} },
    execute: () => ({ utc: new Date().toISOString(), timezone: "UTC" }),
  },

  get_item_details: {
    name: "get_item_details",
    description:
      "Look up an item by Wayfair orderId. Returns SKU, retail price, assembly time, packaging difficulty, weight, dimensions, return reason.",
    parameters: {
      type: "object",
      properties: {
        orderId: { type: "string", description: "Wayfair order ID, e.g. WF-ORDER-8821" },
      },
      required: ["orderId"],
    },
    execute: (args) => {
      const orderId = String(args.orderId ?? "");
      const item = MOCK_ITEMS[orderId];
      if (!item) return { error: `Unknown orderId: ${orderId}` };
      return item;
    },
  },

  get_local_demand: {
    name: "get_local_demand",
    description:
      "Estimate local buyer demand for a SKU near a ZIP. Returns interested shoppers (last 14d), expected days-to-claim, and assembled-discount they'd accept.",
    parameters: {
      type: "object",
      properties: {
        sku: { type: "string" },
        zip: { type: "string", description: "5-digit US ZIP code" },
      },
      required: ["sku", "zip"],
    },
    execute: (args) => {
      const sku = String(args.sku ?? "");
      const zip = String(args.zip ?? "");
      // Hash zip+sku into a stable pseudo-random signal so the demo is deterministic.
      const seed = simpleHash(`${sku}:${zip}`);
      const interestedShoppers = 4 + (seed % 18); // 4–21
      const expectedDaysToClaim = 3 + (seed % 11); // 3–13
      const acceptableAssembledDiscountPct = 18 + (seed % 13); // 18–30%
      return {
        sku,
        zip,
        interestedShoppers,
        expectedDaysToClaim,
        acceptableAssembledDiscountPct,
      };
    },
  },

  get_warehouse_pressure: {
    name: "get_warehouse_pressure",
    description:
      "Get Wayfair fulfillment-center pressure for a ZIP. Returns nearest FC utilization (%), return-shipping cost from this ZIP, and inbound-restock cost.",
    parameters: {
      type: "object",
      properties: {
        zip: { type: "string" },
        weightLbs: { type: "number" },
      },
      required: ["zip", "weightLbs"],
    },
    execute: (args) => {
      const zip = String(args.zip ?? "");
      const weight = Number(args.weightLbs ?? 0);
      const seed = simpleHash(zip);
      const fcUtilizationPct = 72 + (seed % 25); // 72–96%
      // Return shipping scales with weight; assume freight tier above 100lb.
      const returnShippingUsd = Math.round(
        (weight > 100 ? 6.5 : 2.1) * Math.sqrt(weight) + 22,
      );
      const inboundRestockUsd = Math.round(returnShippingUsd * 0.35) + 14;
      return {
        zip,
        fcUtilizationPct,
        returnShippingUsd,
        inboundRestockUsd,
        savedIfHostShipsDirect: returnShippingUsd + inboundRestockUsd,
      };
    },
  },

  log_packaging_check: {
    name: "log_packaging_check",
    description:
      "Record a packaging QA verdict for an order. Use after verifying photos meet the checklist. Returns the saved record.",
    parameters: {
      type: "object",
      properties: {
        orderId: { type: "string" },
        verdict: { type: "string", enum: ["pass", "fail", "needs_more_photos"] },
        notes: { type: "string" },
      },
      required: ["orderId", "verdict"],
    },
    execute: (args) => ({
      saved: true,
      orderId: String(args.orderId ?? ""),
      verdict: String(args.verdict ?? ""),
      notes: String(args.notes ?? ""),
      savedAt: new Date().toISOString(),
    }),
  },
};

function simpleHash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (h * 31 + s.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

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
