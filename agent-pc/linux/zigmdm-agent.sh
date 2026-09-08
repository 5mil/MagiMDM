#!/bin/sh
# MagiMDM PC agent — enroll from blank image then poll.
set -eu
CONF=/etc/zigmdm/enroll.env
STATE=/var/lib/zigmdm/device.env
[ -f "$CONF" ] && . "$CONF"
MDM_URL=${MDM_URL:-http://127.0.0.1:8788}
TOKEN=${TOKEN:-}

enroll() {
  name=$(hostname)
  os=$(uname -sr | tr ' ' '-')
  body=$(printf '{"token":"%s","name":"%s","platform":"linux","os_version":"%s","agent_version":"0.1.0-linux"}' "$TOKEN" "$name" "$os")
  resp=$(wget -qO- --header='Content-Type: application/json' --post-data="$body" "$MDM_URL/api/agent/enroll" || true)
  uuid=$(printf '%s' "$resp" | sed -n 's/.*"uuid":"\([^"]*\)".*/\1/p')
  [ -n "$uuid" ] || return 1
  mkdir -p /var/lib/zigmdm
  printf 'UUID=%s\n' "$uuid" > "$STATE"
}

poll() {
  . "$STATE"
  body=$(printf '{"uuid":"%s","agent_version":"0.1.0-linux","extras":{"image":"pending"}}' "$UUID")
  wget -qO- --header='Content-Type: application/json' --post-data="$body" "$MDM_URL/api/agent/poll" || true
}

[ -f "$STATE" ] || enroll
[ -f "$STATE" ] || exit 1
while true; do poll; sleep 60; done
