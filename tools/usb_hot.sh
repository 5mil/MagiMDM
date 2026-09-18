#!/bin/sh
# Pack a hot-plug MagiMDM console onto a USB directory.
# Usage: ./tools/usb_hot.sh /mnt/e/MagiMDM-USB [--with-zig]
set -eu
DEST=${1:?destination directory}
shift || true
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
mkdir -p "$DEST"/data "$DEST"/zig-out/bin
# sources the binary needs at runtime / compile time
for d in src web sql tools policies agent agent-pc parent-app docs; do
  if [ -d "$ROOT/$d" ]; then
    rm -rf "$DEST/$d"
    cp -a "$ROOT/$d" "$DEST/$d"
  fi
done
for f in build.zig build.zig.zon; do
  [ -f "$ROOT/$f" ] && cp "$ROOT/$f" "$DEST/$f"
done
if [ -x "$ROOT/zig-out/bin/zig-mdm" ]; then
  cp "$ROOT/zig-out/bin/zig-mdm" "$DEST/zig-out/bin/zig-mdm"
fi
cp "$ROOT/tools/usb_hot_RUN.sh" "$DEST/RUN.sh"
cp "$ROOT/tools/usb_hot_BUILD.sh" "$DEST/BUILD.sh"
chmod +x "$DEST/RUN.sh" "$DEST/BUILD.sh"
case "${1:-}" in
  --with-zig)
    ZVER=${ZIG_VERSION:-0.16.0}
    mkdir -p "$DEST/zig"
    if [ ! -x "$DEST/zig/zig" ]; then
      echo "downloading Zig $ZVER onto the stick..."
      curl -L "https://ziglang.org/download/$ZVER/zig-linux-x86_64-$ZVER.tar.xz" | tar -xJ --strip-components=1 -C "$DEST/zig"
    fi
    ;;
esac
echo "USB console at $DEST"
echo "  cd $DEST && ./BUILD.sh && ./RUN.sh"
