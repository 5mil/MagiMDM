#!/bin/sh
# Pull the Ollama stand-ins for families used in https://github.com/5mil/arcis
# Arcis itself loads GGUF in-process. This script does not replace Arcis.
set -eu
TIER=${1:-forma}

need_ollama() {
  command -v ollama >/dev/null || { echo "install Ollama first (docs/AI.md)"; exit 1; }
}

pull() {
  echo "==> ollama pull $1"
  ollama pull "$1"
}

need_ollama

# Forma: inference + RAG (Arcis getting-started uses llama-3.2-1b.gguf)
case $TIER in
  forma)
    pull llama3.2:1b
    pull nomic-embed-text
    ;;
  figura)
    pull llama3.2:1b
    pull llama3.2:3b
    pull nomic-embed-text
    ;;
  visio|full)
    pull llama3.2:1b
    pull llama3.2:3b
    pull nomic-embed-text
    pull qwen2.5:7b
    echo "Whisper/Bark/EnCodec stay outside Ollama (Arcis media/). Use whisper.cpp if you need ASR."
    ;;
  16g)
    pull llama3.2:3b
    pull qwen2.5:7b
    pull nomic-embed-text
    ;;
  *)
    echo "usage: $0 forma|figura|visio|16g"
    exit 1
    ;;
esac

ollama list
