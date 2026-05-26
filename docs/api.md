# Worker API reference

Base URL (local): `http://127.0.0.1:8787`

## `GET /api/health`

```json
{ "ok": true, "service": "lastscrew-worker",
  "subconscious": true, "baseten": false }
```

`subconscious` / `baseten` indicate whether the respective keys are set in
`.dev.vars`. The demo works either way; without keys, the worker uses
fallbacks.

## `GET /api/lastscrew/items/:orderId`

Returns the seed item for a given order id. The demo uses
`WF-ORDER-8821` (the Sleep by Wayfair™ Queen mattress + platform bed).

```json
{
  "orderId": "WF-ORDER-8821",
  "sku": "WF-SLP-12MED-Q",
  "name": "Sleep by Wayfair™ 12\" Medium Memory Foam Mattress + Platform Bed",
  "retailPriceUsd": 549,
  "customerPaidUsd": 489,
  "assemblyTimeMinutes": 92,
  "packagingDifficulty": "medium",
  "dimensions": "Queen 63\"W x 83\"L x 18\"H",
  "weightLbs": 142,
  "category": "bedroom",
  "deliveredAt": "2026-05-17",
  "returnReason": "doesnt_fit"
}
```

## `POST /api/lastscrew/offer`

Compute a host offer. The worker runs the Subconscious ReAct agent with the
lastscrew tools (`get_item_details`, `get_local_demand`,
`get_warehouse_pressure`) and parses a JSON offer out of the final answer.
Falls back to a deterministic local calc if no key is configured.

Request:

```json
{ "orderId": "WF-ORDER-8821", "zip": "02116" }
```

Response (`HostOffer`):

```json
{
  "orderId": "WF-ORDER-8821",
  "zip": "02116",
  "signingBonusUsd": 50,
  "dailyStorageUsd": 3,
  "maxStorageDays": 14,
  "resaleBountyUsd": 90,
  "photoBonusUsd": 15,
  "projectedMaxEarningsUsd": 197,
  "expectedDaysToClaim": 8,
  "reasoning": "Local demand is strong …",
  "source": "subconscious"
}
```

`source` is `"subconscious"` when the agent produced the offer, `"fallback"`
when the local calc was used.

## `POST /api/lastscrew/verify`

Verify a packaging photo. Calls the Baseten-hosted vision model; falls back to
a deterministic mock keyed on `photoDescription` when no Baseten key is set.

Request (any of `imageBase64` / `imageUrl` / `photoDescription`):

```json
{
  "orderId": "WF-ORDER-8821",
  "imageBase64": "<base64 jpeg>",
  "photoDescription": "box closed and taped, corners padded, label visible"
}
```

Response (`PackagingQAResult`):

```json
{
  "orderId": "WF-ORDER-8821",
  "verdict": "pass",
  "score": 0.93,
  "checklist": [
    { "label": "Item fully wrapped", "passed": true, "detail": null },
    { "label": "Corners and edges padded", "passed": true, "detail": null }
  ],
  "notes": "Looks ship-ready. Storage clock starts on carrier scan.",
  "bonusMultiplier": 1.15,
  "source": "baseten"
}
```

`verdict ∈ {pass, needs_work, fail}`. `bonusMultiplier` modulates the
`resaleBountyUsd` from the offer.

## `POST /api/lastscrew/demo`

Convenience: returns both an offer and a QA verdict in one call. Useful for
curl-based smoke tests and for ReAct agents that want to inspect the whole
pipeline at once.

```json
{ "offer": <HostOffer>, "qa": <PackagingQAResult> }
```
