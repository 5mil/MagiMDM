#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")/../deploy/moodle" && pwd)
cd "$HERE"
if [ ! -f .env ]; then
  cp .env.example .env
  echo "wrote $HERE/.env — change passwords"
fi
docker compose up -d
echo "Moodle http://127.0.0.1:8888  (first boot is slow)"
echo "MagiMDM stays at http://127.0.0.1:8787"
