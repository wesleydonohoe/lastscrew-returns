#!/usr/bin/env bash
# Three deterministic mock responses (pass / needs_work / fail) for the
# packaging QA endpoint. Verifies the worker is up, the mock fallback works,
# and lets you wire up a Baseten model deployment without touching the iOS app.

set -euo pipefail
BASE="${BASE:-http://127.0.0.1:8787}"

for desc in \
  "wrapped tight, taped seams, label dry and clean" \
  "box closed but one corner unpadded" \
  "torn wrap, wet stain on the side, no box"
do
  echo "── \"$desc\" ──"
  curl -s -X POST "$BASE/api/lastscrew/verify" \
    -H 'content-type: application/json' \
    -d "{\"orderId\":\"WF-ORDER-8821\",\"photoDescription\":\"$desc\"}" \
    | jq '.verdict, .score, .bonusMultiplier, .source'
  echo
done
