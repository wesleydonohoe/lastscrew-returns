# Track 1 example — Consumer Shopping Experience

A complete example for **Track 1**: an agent that helps customers discover furniture.

Based on the same ReAct loop pattern as [hack-cli-starter](https://github.com/subconscious-systems/subconscious/tree/main/examples/hack-cli-starter) — tools listed in the system prompt, structured JSON output each turn.

## What this example does

1. Configures the agent as a Wayfair shopping assistant
2. Uses the `search_catalog` tool (mock catalog in `src/agent/tools.ts`)
3. Logs merchandising notes via `log_note`
4. Runs two sample customer queries

## Try it

```bash
# Terminal 1
npm run dev

# Terminal 2
bash examples/shopping-assistant/run.sh
```

Or step by step:

```bash
# 1. Load the example config
curl -X PUT http://localhost:8787/api/agent/config \
  -H "Content-Type: application/json" \
  -d @examples/shopping-assistant/config.json

# 2. Ask the agent
curl -X POST http://localhost:8787/api/run \
  -H "Content-Type: application/json" \
  -d '{"instructions": "I need a desk for a small home office under $400."}'
```

Open **http://localhost:8787** to run the same queries from the dashboard.

## Files

| File | Purpose |
|------|---------|
| `config.json` | Agent persona, instructions, enabled tools |
| `run.sh` | Loads config + runs sample queries |
| `../../src/agent/tools.ts` | `search_catalog` mock tool — swap for a real API |

## Extend it

**Swap mock data for real catalog API** — edit `search_catalog` in `src/agent/tools.ts`:

```typescript
execute: async (args) => {
  const response = await fetch(`https://your-api/search?q=${args.query}`);
  return response.json();
},
```

**Add a webhook trigger** — simulate a "product viewed" event:

```bash
curl -X POST http://localhost:8787/api/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "event": "product.viewed",
    "payload": { "sku": "WF-1001", "customerId": "cust_42", "views": 3 }
  }'
```

**Prototype locally with the CLI starter** — same Subconscious API, terminal REPL:

```bash
git clone https://github.com/subconscious-systems/subconscious
cd subconscious/examples/hack-cli-starter
npm install && npm run build && npm link
export SUBCONSCIOUS_API_KEY=your_key
sub
```

Use the CLI to iterate on prompts and tools, then port the working logic into this Worker for triggers and deployment.

## Agent loop (same pattern as hack-cli-starter)

```
User message
    ↓
Model returns JSON: { action: "tool_call", tool, arguments }
    OR           { action: "final_answer", content }
    ↓
If tool_call → run tool in Worker → feed result back → loop
If final_answer → done
```

Implementation: `src/agent/loop.ts` (Worker) · [src/agent/loop.ts in hack-cli-starter](https://github.com/subconscious-systems/subconscious/blob/main/examples/hack-cli-starter/src/agent/loop.ts) (CLI)
