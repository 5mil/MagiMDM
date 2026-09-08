#!/bin/sh
set -eu
DB=${ZIGMDM_DB:-/var/lib/zigmdm/mdm.sqlite}
OUT=${1:-/srv/mdm/audit-export.csv}
mkdir -p "$(dirname "$OUT")"
sqlite3 -header -csv "$DB" "SELECT created_at,action,target_type,target_id,detail_json FROM audit_log ORDER BY id" > "$OUT"
echo "$OUT"
