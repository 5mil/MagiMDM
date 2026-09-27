#!/bin/sh
# Build a folder to copy onto an official installer USB (not a cracked ISO).
# Optional third arg is an os_fetch.sh id; ISO is downloaded first into data/iso.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-/tmp/magimdm-usb}
PLATFORM=${2:-linux}
OS_ID=${3:-}
TOKEN=${TOKEN:-}
MDM_URL=${MDM_URL:-http://192.168.50.143:8787}

if [ -n "$OS_ID" ]; then
  "$ROOT/tools/os_fetch.sh" "$OS_ID"
fi

rm -rf "$OUT"
mkdir -p "$OUT/zigmdm" "$OUT/iso-hint"

if [ "$PLATFORM" = windows ]; then
  cp "$ROOT"/agent-pc/windows/*.ps1 "$OUT/zigmdm/"
  cp "$ROOT/agent-pc/windows/Autounattend.xml" "$OUT/Autounattend.xml"
  printf 'MDM_URL=%s\nTOKEN=%s\nIMAGE_SLUG=windows11-student\n' "$MDM_URL" "$TOKEN" > "$OUT/zigmdm/enroll.env"
  "$ROOT/tools/os_fetch.sh" windows-official > "$OUT/iso-hint/WINDOWS_SOURCE.txt"
  echo "Copy Autounattend.xml and zigmdm/ onto a USB written from a Microsoft Win11 ISO." > "$OUT/README.txt"
else
  cp "$ROOT/agent-pc/linux/zigmdm-agent.sh" "$OUT/zigmdm/"
  cp "$ROOT/agent-pc/linux/zigmdm-agent.service" "$OUT/zigmdm/"
  cp "$ROOT/agent-pc/linux/apply-policy.sh" "$OUT/zigmdm/" 2>/dev/null || true
  cp "$ROOT/agent-pc/linux/autoinstall.yaml" "$OUT/user-data" 2>/dev/null || true
  printf 'MDM_URL=%s\nTOKEN=%s\nIMAGE_SLUG=linux-debian12-student\n' "$MDM_URL" "$TOKEN" > "$OUT/zigmdm/enroll.env"
  echo "Write the official ISO from data/iso/ with dd or Startup Disk Creator, then copy zigmdm/ onto that stick." > "$OUT/README.txt"
  ls -1 "$ROOT/data/iso" 2>/dev/null | tee "$OUT/iso-hint/DOWNLOADED.txt" || true
fi

echo "USB payload: $OUT"
echo "ISOs (if fetched): $ROOT/data/iso"
