#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$HERE"
export PATH="$HERE/zig:$PATH"
if ! command -v zig >/dev/null; then
  echo "zig not on PATH. Install Zig or pack with: ./tools/usb_hot.sh DEST --with-zig" >&2
  exit 1
fi
if ! echo '#include <sqlite3.h>' | cc -E - >/dev/null 2>&1; then
  echo "need libsqlite3 headers on this host: sudo apt install libsqlite3-dev" >&2
fi
zig build
echo "built $HERE/zig-out/bin/zig-mdm"
