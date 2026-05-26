#!/usr/bin/env bash
# Hit the offer endpoint three times across different ZIPs so you can see how
# the agent's reasoning shifts with local demand + FC pressure.

set -euo pipefail
BASE="${BASE:-http://127.0.0.1:8787}"

for zip in 02116 94110 78704; do
  echo "── ZIP $zip ──"
  curl -s -X POST "$BASE/api/lastscrew/offer" \
    -H 'content-type: application/json' \
    -d "{\"orderId\":\"WF-ORDER-8821\",\"zip\":\"$zip\"}" \
    | jq '.'
  echo
done
