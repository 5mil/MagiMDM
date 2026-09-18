#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")/../deploy/moodle" && pwd)
cd "$HERE"
docker compose down
