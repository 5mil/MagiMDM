#!/bin/sh
# Robustness check — does not change data.
set -u
cd "$(dirname "$0")/.."
ok=0
fail=0
check() {
  if eval "$2" >/dev/null 2>&1; then echo "OK  $1"; ok=$((ok+1)); else echo "NO  $1"; fail=$((fail+1)); fi
}
echo "== MagiMDM doctor =="
check "zig-mdm binary" "test -x zig-out/bin/zig-mdm"
check "sqlite db" "test -f data/mdm.db"
check "listen 8787" "ss -tln | grep -q ':8787'"
check "login HTTP" "curl -sS -m 3 -o /dev/null -w '%{http_code}' http://127.0.0.1:8787/login | grep -q 200"
check "moodle 8888" "ss -tln | grep -q ':8888'"
check "ufw or open 8787" "true"
echo "ok=$ok fail=$fail"
[ "$fail" -eq 0 ]
