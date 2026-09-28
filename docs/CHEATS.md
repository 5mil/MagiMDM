# Cheat codes that are legal

DeepSeek’s *useful* trick was: long chain-of-thought, then **distill a small model**. The part that got them in trouble was allegedly farming closed APIs. We do the first. We do not do the second.

No scrapers for ChatGPT / Claude / Grok. No “collect 10M traces from someone else’s ToS.”

## Cheat 1 — take the distillate they *published*

They released small students. Ollama already has them.

```bash
ollama pull deepseek-r1:1.5b
ollama pull deepseek-r1:7b          # only if RAM allows
```

That is R1-style reasoning on this box **without training**. `/ai` will list the tag once pulled.

## Cheat 2 — open CoT sets (already synthesized by others, licensed)

| Set | Size | License | Do on tank? |
|-----|------|---------|-------------|
| GSM8K | 8.5k | MIT | yes — `./tools/oer_fetch.sh core` |
| OpenStax math PDFs | 3 books | CC BY-NC-SA | yes — same |
| NuminaMath-CoT | ~860k / ~1.2 GB | Apache-2.0 | **subset only** |
| OpenMathInstruct-1 | millions | NVIDIA license | skip unless you have a GPU box |
| OpenWebMath | tens of GB | mixed | no |

Numina slice (optional, needs `huggingface-cli`):

```bash
pip install -U huggingface_hub
huggingface-cli download AI-MO/NuminaMath-CoT --include '*.parquet' --local-dir data/library/numina --repo-type dataset
```

Prefer filtering to `gsm8k` / `math` source rows if disk hurts.

## Cheat 3 — self-distill from *your* 7B (the actual DeepSeek method, clean)

You already run `qwen2.5:7b` or `llama3.2:3b` locally. Generate traces **on tank**, train nothing until you want LoRA.

```bash
chmod +x tools/synth_local.sh
# uses GSM8K questions + local Ollama; writes data/library/synth/cot.jsonl
OLLAMA=http://127.0.0.1:11434 MODEL=qwen2.5:7b ./tools/synth_local.sh
```

Use that jsonl later for LoRA on the 1.5B. Teacher and student are both models you host.

## Cheat 4 — do not train if RAG is enough

OpenStax text + citations beats a half-baked LoRA for “explain this lesson.” Training is for Algebra War style *solve*. Library is for *cite*.

## Hard no

- Scripts that hit api.openai.com / other closed chat APIs to build a corpus
- Selling or republishing traces from those APIs
- Pretending Numina/OpenWebMath pages are all CC when they are not — we only pull named licensed sets
