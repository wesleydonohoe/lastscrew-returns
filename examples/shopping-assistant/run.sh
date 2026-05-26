#!/usr/bin/env bash
# Example requests for Track 1 — Consumer Shopping Experience
# Run with: npm run dev  (then in another terminal: bash examples/shopping-assistant/run.sh)

BASE="${BASE_URL:-http://localhost:8787}"

echo "→ Loading shopping assistant config..."
curl -s -X PUT "$BASE/api/agent/config" \
  -H "Content-Type: application/json" \
  -d @examples/shopping-assistant/config.json | jq .

echo ""
echo "→ Running agent: small office desk under \$400..."
curl -s -X POST "$BASE/api/run" \
  -H "Content-Type: application/json" \
  -d '{
    "trigger": "api",
    "instructions": "A customer wants a desk for a small home office under $400. Search the catalog, recommend the best fit, and log a note for the merchandising team if we are missing options."
  }' | jq .

echo ""
echo "→ Running agent: mid-century living room..."
curl -s -X POST "$BASE/api/run" \
  -H "Content-Type: application/json" \
  -d '{
    "instructions": "Customer describes their living room as mid-century modern with warm wood tones. Budget around $900. What sofa should we suggest?"
  }' | jq .
