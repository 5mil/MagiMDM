#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")/../deploy/moodle" && pwd)
cd "$HERE"
if [ ! -f .env ]; then
  cp .env.example .env
  echo "wrote $HERE/.env — change passwords"
fi
docker compose up -d
echo "Moodle LAN http://0.0.0.0:8888  (use tank LAN IP from other PCs)"
echo "MagiMDM stays at port 8787"
