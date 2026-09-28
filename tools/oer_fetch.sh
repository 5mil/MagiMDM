#!/bin/sh
# Fetch small, openly licensed school sets into data/library.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
LIB=$ROOT/data/library
mkdir -p "$LIB/openstax" "$LIB/gsm8k" "$LIB/meta"

need() { command -v "$1" >/dev/null || { echo "need $1"; exit 1; }; }
need wget

attr() {
  cat > "$LIB/meta/ATTRIBUTION.txt" <<'EOF'
OpenStax textbooks: Rice University / OpenStax.
Current books use Creative Commons BY-NC-SA (see each PDF cover).
Download originals: https://openstax.org/
Keep this file beside redistributed copies.

GSM8K: Cobbe et al., MIT License.
https://github.com/openai/grade-school-math
EOF
}

fetch_pdf() {
  name=$1
  url=$2
  dest=$LIB/openstax/$name
  if [ -f "$dest" ]; then echo "have $name"; return; fi
  echo "GET $name"
  wget -c -O "$dest.part" "$url"
  mv "$dest.part" "$dest"
}

# Stable OpenStax WEB PDFs (assets CDN). If a URL 404s, get the current link from openstax.org/details/books/...
core_openstax() {
  fetch_pdf Prealgebra2e-WEB.pdf \
    "https://assets.openstax.org/oscms-prodcms/media/documents/Prealgebra2e-WEB.pdf" || true
  fetch_pdf ElementaryAlgebra2e-WEB.pdf \
    "https://assets.openstax.org/oscms-prodcms/media/documents/ElementaryAlgebra2e-WEB.pdf" || true
  fetch_pdf CollegeAlgebra2e-WEB.pdf \
    "https://assets.openstax.org/oscms-prodcms/media/documents/CollegeAlgebra2e-WEB.pdf" || true
}

core_gsm8k() {
  dest=$LIB/gsm8k/train.jsonl
  if [ -f "$dest" ]; then echo "have gsm8k"; return; fi
  wget -c -O "$dest.part" \
    "https://raw.githubusercontent.com/openai/grade-school-math/master/grade_school_math/data/train.jsonl"
  mv "$dest.part" "$dest"
  wget -c -O "$LIB/gsm8k/test.jsonl" \
    "https://raw.githubusercontent.com/openai/grade-school-math/master/grade_school_math/data/test.jsonl" || true
}

case ${1:-core} in
  core)
    attr
    core_openstax
    core_gsm8k
    ls -lh "$LIB/openstax" "$LIB/gsm8k"
    echo "Next: sudo apt install poppler-utils && pdftotext data/library/openstax/*.pdf"
    ;;
  list)
    echo "core  = 3 OpenStax math PDFs + GSM8K"
    echo "skip  open-web-math (tens of GB)"
    ;;
  *)
    echo "usage: $0 core|list"
    exit 1
    ;;
esac
