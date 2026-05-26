// Compute a host offer for a given order + ZIP.
//
// Path 1 (Subconscious available): instruct the ReAct agent to call
//   get_item_details → get_local_demand → get_warehouse_pressure,
// then reason about a fair offer and emit a JSON offer in `final_answer`.
//
// Path 2 (no Subconscious key OR JSON parse fails): deterministic fallback
// computed locally from the same tool outputs. Demo always works.

import { runAgentLoop } from "../agent/loop";
import { TOOL_REGISTRY, getMockItem } from "../agent/tools";

export interface HostOffer {
  orderId: string;
  zip: string;
  signingBonusUsd: number;
  dailyStorageUsd: number;
  maxStorageDays: number;
  resaleBountyUsd: number;
  photoBonusUsd: number;
  projectedMaxEarningsUsd: number;
  expectedDaysToClaim: number;
  reasoning: string;
  source: "subconscious" | "fallback";
}

const OFFER_INSTRUCTIONS = (orderId: string, zip: string) => `You are pricing a "Last Screw" host offer for Wayfair.

The customer wants to return order ${orderId}. Instead of disassembling, they will keep the item assembled, repackage it, and act as a micro-warehouse until a local buyer claims it at a discount.

Wayfair saves money because (a) we skip the return-shipping leg, (b) we skip warehouse intake/QA, (c) the buyer pays for a like-new assembled item. Your job is to size the host's incentive so that:
- Total host earnings are clearly less than Wayfair's logistics savings.
- The signing bonus alone is meaningful so they say yes immediately.
- Daily storage rewards encourage them to keep the item safe, but capped.
- The resale bounty rewards them when a buyer claims the item.

Steps to take this turn:
1. Call get_item_details for orderId="${orderId}".
2. Call get_local_demand for the item's sku and zip="${zip}".
3. Call get_warehouse_pressure for zip="${zip}" with the item's weightLbs.
4. Then emit a SINGLE final_answer whose content is STRICT JSON only — no prose, no backticks — with this exact shape:
{
  "signingBonusUsd": <int>,
  "dailyStorageUsd": <int>,
  "maxStorageDays": <int>,
  "resaleBountyUsd": <int>,
  "photoBonusUsd": <int>,
  "projectedMaxEarningsUsd": <int>,
  "expectedDaysToClaim": <int>,
  "reasoning": "<one short paragraph the host will read>"
}

Constraints:
- signingBonusUsd between 20 and 75.
- dailyStorageUsd between 1 and 6.
- maxStorageDays between 7 and 21.
- resaleBountyUsd between 25 and 120.
- photoBonusUsd between 5 and 20.
- projectedMaxEarningsUsd = signingBonusUsd + dailyStorageUsd*maxStorageDays + resaleBountyUsd + photoBonusUsd.
- Total earnings must be at most 70% of savedIfHostShipsDirect from get_warehouse_pressure.`;

export async function computeHostOffer(args: {
  orderId: string;
  zip: string;
  apiKey?: string;
}): Promise<HostOffer> {
  const { orderId, zip } = args;

  if (args.apiKey) {
    try {
      const result = await runAgentLoop({
        apiKey: args.apiKey,
        systemPrompt:
          "You are LastScrew Pricing — a careful pricing agent. Always use tools to gather facts before deciding numbers.",
        instructions: OFFER_INSTRUCTIONS(orderId, zip),
        enabledTools: [
          "get_item_details",
          "get_local_demand",
          "get_warehouse_pressure",
        ],
        maxSteps: 6,
        maxTokens: 800,
        temperature: 0.4,
        enableThinking: false,
      });
      const parsed = tryParseOffer(result.answer);
      if (parsed) {
        return {
          orderId,
          zip,
          ...parsed,
          source: "subconscious",
        };
      }
    } catch {
      // fall through to fallback
    }
  }

  return fallbackOffer(orderId, zip);
}

function tryParseOffer(
  raw: string,
): Omit<HostOffer, "orderId" | "zip" | "source"> | null {
  try {
    const start = raw.indexOf("{");
    const end = raw.lastIndexOf("}");
    if (start === -1 || end <= start) return null;
    const obj = JSON.parse(raw.slice(start, end + 1)) as Record<string, unknown>;
    const num = (k: string) => Number(obj[k]);
    const signingBonusUsd = num("signingBonusUsd");
    const dailyStorageUsd = num("dailyStorageUsd");
    const maxStorageDays = num("maxStorageDays");
    const resaleBountyUsd = num("resaleBountyUsd");
    const photoBonusUsd = num("photoBonusUsd");
    const expectedDaysToClaim = num("expectedDaysToClaim");
    const reasoning = String(obj.reasoning ?? "");
    if (
      [signingBonusUsd, dailyStorageUsd, maxStorageDays, resaleBountyUsd, photoBonusUsd].some(
        (n) => !Number.isFinite(n),
      )
    ) {
      return null;
    }
    const projectedMaxEarningsUsd =
      Number(obj.projectedMaxEarningsUsd) ||
      signingBonusUsd +
        dailyStorageUsd * maxStorageDays +
        resaleBountyUsd +
        photoBonusUsd;
    return {
      signingBonusUsd,
      dailyStorageUsd,
      maxStorageDays,
      resaleBountyUsd,
      photoBonusUsd,
      projectedMaxEarningsUsd,
      expectedDaysToClaim: Number.isFinite(expectedDaysToClaim) ? expectedDaysToClaim : 7,
      reasoning,
    };
  } catch {
    return null;
  }
}

function fallbackOffer(orderId: string, zip: string): HostOffer {
  const item = getMockItem(orderId);
  const demand = TOOL_REGISTRY.get_local_demand.execute({
    sku: item?.sku ?? "WF-UNKNOWN",
    zip,
  }) as {
    interestedShoppers: number;
    expectedDaysToClaim: number;
    acceptableAssembledDiscountPct: number;
  };
  const pressure = TOOL_REGISTRY.get_warehouse_pressure.execute({
    zip,
    weightLbs: item?.weightLbs ?? 60,
  }) as { savedIfHostShipsDirect: number; fcUtilizationPct: number };

  const saved = pressure.savedIfHostShipsDirect;
  const demandBoost = Math.min(1.4, 0.7 + demand.interestedShoppers * 0.04);
  const signingBonusUsd = Math.max(25, Math.round(saved * 0.18 * demandBoost));
  const dailyStorageUsd = Math.max(2, Math.round(saved * 0.012));
  const maxStorageDays = Math.min(
    21,
    Math.max(7, demand.expectedDaysToClaim + 4),
  );
  const resaleBountyUsd = Math.max(35, Math.round(saved * 0.25 * demandBoost));
  const photoBonusUsd = Math.max(8, Math.round(saved * 0.04));
  const projectedMaxEarningsUsd =
    signingBonusUsd +
    dailyStorageUsd * maxStorageDays +
    resaleBountyUsd +
    photoBonusUsd;

  return {
    orderId,
    zip,
    signingBonusUsd,
    dailyStorageUsd,
    maxStorageDays,
    resaleBountyUsd,
    photoBonusUsd,
    projectedMaxEarningsUsd,
    expectedDaysToClaim: demand.expectedDaysToClaim,
    reasoning: `Local demand is healthy (${demand.interestedShoppers} shoppers nearby, expected claim in ${demand.expectedDaysToClaim} days). FC ${pressure.fcUtilizationPct}% utilized, so skipping the return + restock saves Wayfair roughly $${saved}. We're sharing ~${Math.round(
      (projectedMaxEarningsUsd / saved) * 100,
    )}% of that with you.`,
    source: "fallback",
  };
}
