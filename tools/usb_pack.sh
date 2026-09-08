#!/bin/sh
# Build a folder to copy onto installer USB (not an ISO).
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-/tmp/magimdm-usb}
PLATFORM=${2:-linux}
TOKEN=${TOKEN:-}
MDM_URL=${MDM_URL:-http://mdm.home}
rm -rf "$OUT"
mkdir -p "$OUT/zigmdm"
if [ "$PLATFORM" = windows ]; then
  cp "$ROOT"/agent-pc/windows/*.ps1 "$OUT/zigmdm/"
  cp "$ROOT/agent-pc/windows/Autounattend.xml" "$OUT/Autounattend.xml"
  printf 'MDM_URL=%s\nTOKEN=%s\nIMAGE_SLUG=windows11-student\n' "$MDM_URL" "$TOKEN" > "$OUT/zigmdm/enroll.env"
else
  cp "$ROOT/agent-pc/linux/zigmdm-agent.sh" "$OUT/zigmdm/"
  cp "$ROOT/agent-pc/linux/zigmdm-agent.service" "$OUT/zigmdm/"
  cp "$ROOT/agent-pc/linux/apply-policy.sh" "$OUT/zigmdm/" 2>/dev/null || true
  printf 'MDM_URL=%s\nTOKEN=%s\nIMAGE_SLUG=linux-debian12-student\n' "$MDM_URL" "$TOKEN" > "$OUT/zigmdm/enroll.env"
fi
echo "USB payload: $OUT"
