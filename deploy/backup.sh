#!/bin/sh
set -eu
DB=${ZIGMDM_DB:-/var/lib/zigmdm/mdm.sqlite}
DEST=${ZIGMDM_BACKUP:-/srv/mdm/backups}
mkdir -p "$DEST"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 "$DB" "PRAGMA integrity_check;"
  sqlite3 "$DB" ".backup '$DEST/mdm-$stamp.sqlite'"
else
  cp -a "$DB" "$DEST/mdm-$stamp.sqlite"
fi
# keep 90 days
find "$DEST" -name 'mdm-*.sqlite' -mtime +90 -delete
