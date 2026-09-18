#!/bin/sh
# Run from the USB tree so data/mdm.db stays on the stick.
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$HERE"
export PATH="$HERE/zig:$PATH"
BIN=$HERE/zig-out/bin/zig-mdm
if [ ! -x "$BIN" ]; then
  echo "no binary — run ./BUILD.sh first" >&2
  exit 1
fi
mkdir -p data
echo "MagiMDM from USB  $HERE"
exec "$BIN"
