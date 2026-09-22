#!/usr/bin/env bash
# Reverse face search from the shell. Needs curl and jq.
#
#   export TRACE_KEY=trk_live_...
#   ./quickstart.sh photo.jpg
#
# Get a key at https://traceaifacescan.app -> Panel -> API

set -euo pipefail

BASE="https://traceaifacescan.app/api/v1"
IMAGE="${1:?usage: quickstart.sh <image>}"
AUTH="Authorization: Bearer ${TRACE_KEY:?set TRACE_KEY first}"

# Credits left?
curl -fsS -H "$AUTH" "$BASE/account" | jq '{credits, scan_cost}'

# Start the scan. The image hash as Idempotency-Key makes a retry free.
IDEM=$(shasum -a 256 "$IMAGE" | cut -d' ' -f1)
SCAN=$(curl -fsS -X POST "$BASE/scans" \
  -H "$AUTH" -H "Idempotency-Key: $IDEM" \
  -F "image=@$IMAGE")

ID=$(jq -r .id <<<"$SCAN")
LOCKED=$(jq -r .locked <<<"$SCAN")

if [ "$LOCKED" = "true" ]; then
  echo "No credits: scan is locked. Top up, then:"
  echo "  curl -X POST $BASE/scans/$ID/reveal -H \"\$AUTH\""
  exit 1
fi

# Poll until it finishes.
while :; do
  SCAN=$(curl -fsS -H "$AUTH" "$BASE/scans/$ID")
  STATUS=$(jq -r .status <<<"$SCAN")
  if [ "$STATUS" = "done" ] || [ "$STATUS" = "failed" ]; then break; fi
  sleep 2
done

if [ "$STATUS" = "failed" ]; then
  echo "Scan failed: $(jq -r .error_code <<<"$SCAN")" >&2
  exit 1
fi

jq -r '.matches[] | select(.tier == "strong" or .tier == "near_certain")
       | "\(.score)  \(.platform)  \(.handle // "-")  \(.url)"' <<<"$SCAN"

# Delete the photo now instead of waiting for expires_at:
#   curl -X DELETE "$BASE/scans/$ID" -H "$AUTH"
