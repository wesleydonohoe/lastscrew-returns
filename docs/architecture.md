# Architecture

```
                       iOS (SwiftUI)
                            │
       POST /api/lastscrew/offer    │    POST /api/lastscrew/verify
                            │                    │
                            ▼                    ▼
                ┌─────────────────────────────────────────┐
                │  Cloudflare Worker (Hono on the edge)   │
                │   src/index.ts          ← routes        │
                │   src/lastscrew/offer.ts ← pricing      │
                │   src/baseten/client.ts ← QA            │
                │   src/agent/{loop,tools,store,runner}   │
                └──────┬─────────────────────────┬────────┘
                       │ ReAct loop              │ image POST
                       ▼                         ▼
              ┌─────────────────┐       ┌────────────────────┐
              │  Subconscious    │       │     Baseten        │
              │  pricing brain   │       │  vision QA model   │
              │  (tools: item,   │       │  (Qwen2-VL or      │
              │  demand, FC      │       │  custom Truss)     │
              │  pressure)       │       │                    │
              └─────────────────┘       └────────────────────┘
```

## Why split the AI providers

| Concern | Provider | Why |
|---------|----------|-----|
| Pricing the host offer | Subconscious | Structured reasoning + tool use. The model needs to call `get_item_details` → `get_local_demand` → `get_warehouse_pressure` and produce a constrained JSON object. ReAct loops are exactly what Subconscious is good at. |
| Verifying the packaging photo | Baseten | Hosts the actual vision model. Pick a VLM from Baseten's catalog (Qwen2-VL-7B is a great default) or ship your own Truss. Subconscious is text-only today. |
| Routing + contract | Cloudflare Workers | One backend the iOS app talks to. Edge-deployed, no cold starts that matter for this demo, and the starter we forked already wires Subconscious to a Worker. |

The split also means each piece can degrade independently — the offer agent
can run without Baseten, and the packaging QA can run without Subconscious.

## Worker control flow

`POST /api/lastscrew/offer`

1. Worker constructs lastscrew-specific instructions for the agent (see
   `OFFER_INSTRUCTIONS` in `src/lastscrew/offer.ts`).
2. `runAgentLoop()` runs the ReAct loop against Subconscious with
   `enabledTools = [get_item_details, get_local_demand, get_warehouse_pressure]`.
3. Agent's `final_answer` is parsed as JSON. If parsing fails or no
   Subconscious key is configured, the worker falls back to a deterministic
   offer derived from the same tool outputs.

`POST /api/lastscrew/verify`

1. iOS uploads `imageBase64` (JPEG, ~70% quality).
2. Worker calls Baseten model deployment with the QA prompt + image.
3. Model returns strict JSON (verdict, score, checklist, multiplier).
4. If no Baseten key is configured, the worker calls `mockQA()` keyed on
   `photoDescription` so the demo runs cold.

## Why this works financially

| Today | With lastscrew |
|-------|---------------|
| Return shipping (mattress, freight tier): ~$60–110 | $0 |
| Warehouse intake + QA: ~$25 amortized | replaced by Baseten QA |
| Restock decision: ~30% items go to liquidation | item resold assembled, in-zip, at ~75% retail |
| Customer effort: ~1.5h disassembly + repackaging | ~10 min wrap & photograph |

Even spending $150–200 per host on incentives, Wayfair captures the difference
*and* keeps the customer happy enough to come back. The vision-QA step is what
makes this real — without it the "warehouse intake" leg comes back.

## iOS architecture

- One `NavigationStack` driven by `AppRouter.path: [AppRoute]`.
- Each screen is its own SwiftUI file in `ios/Sources/Lastscrew/Screens/`.
- View models live in `ViewModels/`, are `@MainActor`-isolated, and only
  depend on `APIClient`.
- `APIClient` is a single shared instance; reads `LASTSCREW_API_BASE` from
  Info.plist (set via xcodegen) or scheme env var.
- Camera is `AVFoundation` (live preview, photo capture) with a `PhotosPicker`
  fallback for Simulator runs.

See [`docs/ios.md`](./ios.md) for the navigation graph.
