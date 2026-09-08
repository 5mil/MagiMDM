#!/bin/sh
set -eu
DB=${ZIGMDM_DB:-/var/lib/zigmdm/mdm.sqlite}
OUT=${1:-/srv/mdm/comms-export.csv}
mkdir -p "$(dirname "$OUT")"
sqlite3 -header -csv "$DB" "SELECT c.ts, d.name, d.uuid, c.direction, c.kind, c.peer, c.allowed, c.body FROM comms_log c JOIN devices d ON d.id=c.device_id ORDER BY c.id" > "$OUT"
echo "$OUT"
