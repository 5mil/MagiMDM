#!/bin/sh
# Ease of use: wire, seed, build, print URLs. Does not daemonize.
set -e
cd "$(dirname "$0")/.."
chmod +x tools/wire_main.sh tools/wire_audit.sh tools/seed_lab.sh 2>/dev/null || true
./tools/wire_main.sh || true
./tools/wire_audit.sh || true
mkdir -p data
/opt/zig/zig build 2>/dev/null || zig build
BIN=zig-out/bin/zig-mdm
if [ ! -x "$BIN" ]; then echo "build failed"; exit 1; fi
# seed after first run creates db — start briefly if missing
if [ ! -f data/mdm.db ]; then
  echo "starting once to create data/mdm.db..."
fi
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
IP=${IP:-192.168.50.143}
echo ""
echo "MagiMDM desk    http://$IP:8787/login"
echo "  admin / changeme"
echo "Moodle          http://$IP:8888/"
echo "Arcis library   http://$IP:9090/"
echo ""
echo "Ctrl+C to stop. If AddressInUse: fuser -k 8787/tcp"
echo ""
exec "$BIN"
