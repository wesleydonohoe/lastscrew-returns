export interface ToolDefinition {
  name: string;
  description: string;
  parameters: Record<string, unknown>;
  execute: (args: Record<string, unknown>) => Promise<unknown> | unknown;
}

// Mock data store — in a real build this is Wayfair order/inventory/CRM data.
// Five items with deliberately varied retail / weight / packaging difficulty so
// the pricing agent's offers diverge in obvious ways across item types.
const MOCK_ITEMS: Record<string, ItemDetails> = {
  // Wes's actual orders, lifted from his Wayfair "My Orders" page.
  "WF-ORDER-8820": {
    orderId: "WF-ORDER-8820",
    sku: "WF-HARLOW-TWN-WHT",
    name: "Harlow Solid Wood Platform Bed",
    brand: "Red Barrel Studio®",
    imageAsset: "HarlowBed",
    retailPriceUsd: 329,
    customerPaidUsd: 289,
    assemblyTimeMinutes: 68,
    packagingDifficulty: "medium",
    dimensions: 'Twin 41"W x 78"L x 14"H',
    weightLbs: 78,
    category: "bedroom",
    deliveredAt: "2026-05-26",
    returnReason: "doesnt_fit",
    status: "delivered",
    lastScrewEligible: true,
    estPayoutRange: { low: 95, high: 145 },
  },
  "WF-ORDER-8821": {
    orderId: "WF-ORDER-8821",
    sku: "WF-SLP-12MED-Q",
    name: 'Sleep by Wayfair™ 12" Memory Foam Mattress + Platform Bed',
    brand: "Sleep by Wayfair™",
    imageAsset: "MattressHero",
    retailPriceUsd: 549,
    customerPaidUsd: 489,
    assemblyTimeMinutes: 92,
    packagingDifficulty: "medium",
    dimensions: 'Queen 63"W x 83"L x 18"H',
    weightLbs: 142,
    category: "bedroom",
    deliveredAt: "2026-05-17",
    returnReason: "doesnt_fit",
    status: "delivered",
    lastScrewEligible: true,
    estPayoutRange: { low: 120, high: 175 },
  },
  "WF-ORDER-8826": {
    orderId: "WF-ORDER-8826",
    sku: "WF-LUCERA-TWN-WHT",
    name: "Lucera Mid-Century Bobbin Bed",
    brand: "August Grove®",
    imageAsset: "LuceraBed",
    retailPriceUsd: 419,
    customerPaidUsd: 369,
    assemblyTimeMinutes: 84,
    packagingDifficulty: "hard",
    dimensions: 'Twin 42"W x 80"L x 36"H',
    weightLbs: 96,
    category: "bedroom",
    deliveredAt: "2026-05-23",
    returnReason: "doesnt_fit",
    status: "delivered",
    lastScrewEligible: true,
    estPayoutRange: { low: 130, high: 195 },
  },
  "WF-ORDER-8822": {
    orderId: "WF-ORDER-8822",
    sku: "WF-SOFA-3SEAT-VLV",
    name: "Velvet 3-Seat Sectional Sofa",
    brand: "Wade Logan®",
    imageAsset: "VelvetSofa",
    retailPriceUsd: 1299,
    customerPaidUsd: 1099,
    assemblyTimeMinutes: 75,
    packagingDifficulty: "hard",
    dimensions: '112"W x 70"D x 34"H',
    weightLbs: 218,
    category: "living",
    deliveredAt: "2026-05-19",
    returnReason: "color_mismatch",
    status: "delivered",
    lastScrewEligible: true,
    estPayoutRange: { low: 180, high: 245 },
  },
  "WF-ORDER-8823": {
    orderId: "WF-ORDER-8823",
    sku: "WF-DESK-MCM-WAL",
    name: "Mid-Century Walnut Writing Desk",
    brand: "George Oliver®",
    imageAsset: "WalnutDesk",
    retailPriceUsd: 349,
    customerPaidUsd: 299,
    assemblyTimeMinutes: 38,
    packagingDifficulty: "easy",
    dimensions: '48"W x 24"D x 30"H',
    weightLbs: 64,
    category: "office",
    deliveredAt: "2026-05-21",
    returnReason: "doesnt_fit",
    status: "delivered",
    lastScrewEligible: false,
    ineligibleReason: "Final-sale item — Wayfair return policy excludes this SKU from Last Screw.",
  },
  "WF-ORDER-8824": {
    orderId: "WF-ORDER-8824",
    sku: "WF-DINING-6P-OAK",
    name: "Farmhouse Oak Dining Set (table + 6 chairs)",
    brand: "Three Posts™",
    imageAsset: "FarmhouseDining",
    retailPriceUsd: 899,
    customerPaidUsd: 779,
    assemblyTimeMinutes: 124,
    packagingDifficulty: "hard",
    dimensions: 'Table 72"W x 40"D x 30"H',
    weightLbs: 196,
    category: "dining",
    deliveredAt: "2026-05-18",
    returnReason: "changed_mind",
    status: "delivered",
    lastScrewEligible: false,
    ineligibleReason: "Open damage claim on this order — resolve with Wayfair Support first.",
  },
  "WF-ORDER-8825": {
    orderId: "WF-ORDER-8825",
    sku: "WF-LAMP-ARC-BRS",
    name: 'Brass Arc Floor Lamp 68" Adjustable',
    brand: "Mercer41™",
    imageAsset: "ArcFloorLamp",
    retailPriceUsd: 189,
    customerPaidUsd: 159,
    assemblyTimeMinutes: 14,
    packagingDifficulty: "easy",
    dimensions: '68"H x 36" arc',
    weightLbs: 22,
    category: "lighting",
    deliveredAt: "2026-05-22",
    returnReason: "wrong_color",
    status: "delivered",
    lastScrewEligible: false,
    ineligibleReason: "Below the $200 Last Screw payout floor — standard return is faster.",
  },
};

export function listMockItems(): ItemDetails[] {
  // Sort newest delivery first.
  return Object.values(MOCK_ITEMS).sort((a, b) =>
    b.deliveredAt.localeCompare(a.deliveredAt),
  );
}

export interface ItemDetails {
  orderId: string;
  sku: string;
  name: string;
  brand: string;
  imageAsset: string;
  retailPriceUsd: number;
  customerPaidUsd: number;
  assemblyTimeMinutes: number;
  packagingDifficulty: "easy" | "medium" | "hard";
  dimensions: string;
  weightLbs: number;
  category: string;
  deliveredAt: string;
  returnReason: string;
  status: "delivered" | "in_transit" | "returned";
  /** Whether this item can use the Last Screw host program. */
  lastScrewEligible: boolean;
  /** When ineligible, why — shown in the UI. */
  ineligibleReason?: string;
  /** Rough payout estimate ($X-$Y) shown on the eligible card before full agent run. */
  estPayoutRange?: { low: number; high: number };
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
