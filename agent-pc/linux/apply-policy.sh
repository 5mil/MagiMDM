#!/bin/sh
# Read policy.json and apply school-hours nft + firefox if present.
set -eu
ROOT=/etc/zigmdm
POL=$ROOT/policy.json
[ -f "$POL" ] || exit 0
mode=$(sed -n 's/.*"mode"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$POL" | head -1)
case "$mode" in
  school|exam) [ -x $ROOT/nft-school.sh ] && $ROOT/nft-school.sh school || true ;;
  *) [ -x $ROOT/nft-school.sh ] && $ROOT/nft-school.sh open || true ;;
esac
