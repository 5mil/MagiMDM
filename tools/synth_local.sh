#!/bin/sh
# Generate CoT traces with a LOCAL Ollama teacher on GSM8K questions.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OLLAMA=${OLLAMA:-http://127.0.0.1:11434}
MODEL=${MODEL:-llama3.2:3b}
SRC=${SRC:-$ROOT/data/library/gsm8k/train.jsonl}
OUTDIR=$ROOT/data/library/synth
LIMIT=${LIMIT:-50}
mkdir -p "$OUTDIR"
OUT=$OUTDIR/cot.jsonl

if [ ! -f "$SRC" ]; then
  echo "run ./tools/oer_fetch.sh core first" >&2
  exit 1
fi

n=0
: > "$OUT"
while IFS= read -r line && [ "$n" -lt "$LIMIT" ]; do
  q=$(printf '%s' "$line" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("question",""))' 2>/dev/null || true)
  [ -n "$q" ] || continue
  n=$((n+1))
  echo "[$n/$LIMIT] $MODEL"
  body=$(python3 -c 'import json,sys; print(json.dumps({"model":sys.argv[1],"stream":False,"messages":[{"role":"user","content":"Solve step by step.\n"+sys.argv[2]}]}))' "$MODEL" "$q")
  resp=$(curl -sS "$OLLAMA/api/chat" -H 'Content-Type: application/json' -d "$body" || true)
  printf '%s\n' "$resp" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(json.dumps({"model":"'"$MODEL"'","q":sys.argv[1],"a":d.get("message",{}).get("content","")}))' "$q" >> "$OUT" 2>/dev/null || true
done < "$SRC"
echo "wrote $OUT ($n rows)"
