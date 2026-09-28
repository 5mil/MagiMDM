#!/bin/sh
# Insert one fake enrolled phone so the desk fleet is not empty.
set -e
cd "$(dirname "$0")/.."
mkdir -p data
DB=data/mdm.db
if [ ! -f "$DB" ]; then
  echo "start zig-mdm once first so data/mdm.db exists"
  exit 1
fi
sqlite3 "$DB" "INSERT OR IGNORE INTO devices(uuid,name,platform,status,last_seen_at) VALUES('lab-android','Lab phone','android','enrolled',datetime('now'));"
sqlite3 "$DB" "SELECT uuid,name,status FROM devices;"
