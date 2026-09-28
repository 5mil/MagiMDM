# Free training / library sets (legal only)

Skip building a corpus. Do **not** pull OpenWebMath (14B tokens) onto tank. That is pretrain scale.

House path: `data/library/` (gitignored). Attribution stays next to the files.

```bash
cd ~/magimdm
chmod +x tools/oer_fetch.sh
./tools/oer_fetch.sh core
```

## What `core` gets

| Set | License | Use |
|-----|---------|-----|
| OpenStax Prealgebra 2e PDF | CC BY-NC-SA (current OpenStax) | Library + RAG |
| OpenStax Elementary Algebra 2e PDF | same | Algebra War grounding |
| OpenStax College Algebra 2e PDF | same | College-format hours |
| GSM8K train.jsonl (8.5k grade-school word problems) | MIT | Fine-tune / quiz seed / Algebra War |

Official books: https://openstax.org/subjects/math  
GSM8K: https://github.com/openai/grade-school-math (MIT)

## What we are not fetching

- OpenWebMath / FineMath / huge Common Crawl math — wrong size, mixed licenses under pages.
- Khan video dumps.
- Paid curriculum PDFs.
- Anything without a license line in ATTRIBUTION.txt.

## After download

1. RAG / Arcis P1: point import at `data/library/openstax/` (pdftotext if you need `.txt`).
2. Algebra War: sample GSM8K `question` / `answer` as extra bands later.
3. Fine-tune (optional, later): LoRA on GSM8K only if you have a GPU. Not required to beat Ollama on citations.

`pdftotext` (poppler-utils) turns a book into ingestible text:

```bash
sudo apt install poppler-utils
for f in data/library/openstax/*.pdf; do pdftotext -layout "$f" "${f%.pdf}.txt"; done
```
