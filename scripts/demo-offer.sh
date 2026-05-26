#!/usr/bin/env bash
# Sweep the offer endpoint across all five mock items in the same ZIP, so you
# can see how the pricing agent actually varies its offer with item type
# (mattress vs sofa vs desk vs dining set vs floor lamp).

set -eo pipefail
BASE="${BASE:-http://127.0.0.1:8787}"
ZIP="${ZIP:-02116}"

ITEMS=(
  "WF-ORDER-8821:Mattress + bed frame (142 lb, $549 retail, medium pkg)"
  "WF-ORDER-8822:Sectional sofa     (218 lb, $1299 retail, hard pkg)"
  "WF-ORDER-8823:Writing desk        (64 lb,  $349 retail, easy pkg)"
  "WF-ORDER-8824:Dining set 6-seat   (196 lb, $899 retail, hard pkg)"
  "WF-ORDER-8825:Arc floor lamp      (22 lb,  $189 retail, easy pkg)"
)

printf "%-30s | %4s | %3s | %4s | %4s | %3s | %4s | source\n" \
  "item" "sign" "day" "maxD" "bnty" "pho" "tot"
printf '%78s\n' '' | tr ' ' '-'

for entry in "${ITEMS[@]}"; do
  id="${entry%%:*}"
  label="${entry#*:}"
  json=$(curl -s --max-time 60 -X POST "$BASE/api/lastscrew/offer" \
    -H 'content-type: application/json' \
    -d "{\"orderId\":\"$id\",\"zip\":\"$ZIP\"}")
  sign=$(echo "$json" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("signingBonusUsd","?"))')
  day=$(echo "$json"  | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("dailyStorageUsd","?"))')
  maxd=$(echo "$json" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("maxStorageDays","?"))')
  bnty=$(echo "$json" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("resaleBountyUsd","?"))')
  pho=$(echo "$json"  | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("photoBonusUsd","?"))')
  tot=$(echo "$json"  | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("projectedMaxEarningsUsd","?"))')
  src=$(echo "$json"  | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("source","?"))')
  printf "%-26s | \$%3s | \$%2s | %3sd | \$%3s | \$%2s | \$%3s | %s\n" \
    "${label:0:26}" "$sign" "$day" "$maxd" "$bnty" "$pho" "$tot" "$src"
done

echo
echo "Tool-call trace for the first item:"
curl -s --max-time 60 -X POST "$BASE/api/lastscrew/offer" \
  -H 'content-type: application/json' \
  -d "{\"orderId\":\"WF-ORDER-8821\",\"zip\":\"$ZIP\"}" \
  | python3 -c 'import sys,json;d=json.load(sys.stdin);print(json.dumps(d.get("toolCalls",[]),indent=2))'
