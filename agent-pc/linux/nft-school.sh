#!/bin/sh
# Tight LAN-only example. Edit allowlist before use.
set -eu
mode=${1:-open}
nft flush ruleset 2>/dev/null || true
if [ "$mode" = school ]; then
  nft -f - <<'EOF'
table inet zigmdm {
  chain out {
    type filter hook output priority 0;
    oif lo accept
    ct state established,related accept
    udp dport 53 accept
    tcp dport { 80, 443 } accept
    ip daddr 192.168.0.0/16 accept
    reject
  }
}
EOF
fi
