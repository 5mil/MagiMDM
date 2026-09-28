#!/bin/sh
# House production: permissions, unit, password reminder. Run as the desk user + sudo for unit.
set -e
cd "$(dirname "$0")/.."
chmod 700 data 2>/dev/null || mkdir -p data && chmod 700 data
chmod 600 data/mdm.db 2>/dev/null || true
chmod 700 zig-out/bin/zig-mdm 2>/dev/null || true
echo "1. Change admin password in Settings after login. Default changeme is not production."
echo "2. sudo ufw allow from 192.168.0.0/16 to any port 8787 proto tcp"
echo "3. Install unit:"
echo "   sudo cp deploy/systemd/magimdm.service /etc/systemd/system/"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable --now magimdm"
echo "4. ./tools/doctor.sh"
echo "Do not port-forward 8787 on the router."
