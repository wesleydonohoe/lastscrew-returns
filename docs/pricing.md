# Pricing: how the Subconscious agent reasons

The host offer is **not** a hardcoded formula. The Worker hands a
problem statement to a Subconscious ReAct agent with three tools; the agent
plans, calls tools, and emits a constrained JSON offer.

Source of truth: `src/lastscrew/offer.ts` (instructions),
`src/agent/tools.ts` (tools), `src/agent/loop.ts` (the harness).

## Tools the agent can call

| Tool | Returns | Where the data comes from |
|------|---------|--------------------------|
| `get_item_details(orderId)` | SKU, retail price, assembly time, packaging difficulty, weight, dimensions, return reason | Currently mock data in `tools.ts`. In production, hit Wayfair's order service. |
| `get_local_demand(sku, zip)` | interested shoppers (last 14d), expected days-to-claim, acceptable assembled-discount % | Mock derived from a `sku:zip` hash so the demo is deterministic. Replace with the catalog-demand service. |
| `get_warehouse_pressure(zip, weightLbs)` | nearest FC utilization %, return-shipping cost from this ZIP, restock cost, **savedIfHostShipsDirect** | Mock; replace with FC telemetry. |

The agent emits the offer as `final_answer.content` JSON. The harness parses
and returns. If parsing fails, the local fallback (`fallbackOffer` in
`src/lastscrew/offer.ts`) reproduces a similar policy directly.

## The instructions

See `OFFER_INSTRUCTIONS` in `src/lastscrew/offer.ts`. Notable constraints:

- `signingBonusUsd ∈ [20, 75]`
- `dailyStorageUsd ∈ [1, 6]`
- `maxStorageDays ∈ [7, 21]`
- `resaleBountyUsd ∈ [25, 120]`
- `photoBonusUsd ∈ [5, 20]`
- Total earnings must be **at most 70%** of `savedIfHostShipsDirect`.

That last constraint is what guarantees the program is net-positive for
Wayfair before the resale revenue is even counted.

## Why an agent and not a formula

Three reasons:

1. **The signals are heterogeneous.** Item, demand, and FC pressure don't
   compose cleanly into one closed-form expression. The agent can reason
   about, e.g., "high FC pressure + low local demand = lean on signing bonus,
   short max-storage-days."
2. **Policy iteration is fast.** Tune the prompt, redeploy the worker, and
   you can A/B new pricing without a model retrain.
3. **Reasoning is auditable.** The `reasoning` field on `HostOffer` is
   surfaced in the iOS app and recorded in the agent run log, so a finance
   reviewer can see *why* this customer got $187 vs another's $230.

## Iteration ideas

- Add a `seasonal_lift` tool — return demand multipliers for category/season.
- Add a `host_history` tool — past acceptance + completion rate by user.
- Sample N offers and pick the median to dampen agent variance.
- Replace the mock catalog/demand tools with real Wayfair endpoints behind
  the same interface — the agent prompt doesn't need to change.
