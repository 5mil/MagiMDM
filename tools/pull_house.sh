#!/bin/sh
# Run on tank. Pulls DeepSeek-R1 1.5B + OpenStax/GSM8K.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

if command -v ollama >/dev/null; then
  echo "==> ollama pull deepseek-r1:1.5b"
  ollama pull deepseek-r1:1.5b
  ollama pull llama3.2:1b || true
  ollama list
else
  echo "Ollama not installed. curl -fsSL https://ollama.com/install.sh | sh"
  echo "then: sudo systemctl enable --now ollama && re-run $0"
fi

chmod +x tools/oer_fetch.sh tools/synth_local.sh tools/arcis_ollama.sh 2>/dev/null || true
./tools/oer_fetch.sh core || true
echo "done"
