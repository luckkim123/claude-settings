#!/usr/bin/env bash
# compile.sh — multi-pass LaTeX compilation with bibtex
# Usage: ./compile.sh <main_tex_path> [engine]
#   engine: pdflatex (default) | xelatex | lualatex
# Exit codes:
#   0 — success
#   1 — usage / file missing
#   2 — compile error (see <main>.log)
#   3 — bibtex error (see <main>.blg)

set -u

MAIN="${1:-}"
ENGINE="${2:-pdflatex}"

if [[ -z "$MAIN" ]]; then
  echo "usage: $0 <main_tex_path> [pdflatex|xelatex|lualatex]" >&2
  exit 1
fi
if [[ ! -f "$MAIN" ]]; then
  echo "error: $MAIN not found" >&2
  exit 1
fi

case "$ENGINE" in
  pdflatex|xelatex|lualatex) ;;
  *) echo "error: unknown engine '$ENGINE'" >&2; exit 1 ;;
esac

DIR="$(cd "$(dirname "$MAIN")" && pwd)"
BASE="$(basename "$MAIN" .tex)"
cd "$DIR" || exit 1

run_latex() {
  "$ENGINE" -interaction=nonstopmode -halt-on-error "$BASE.tex" > /dev/null
  return $?
}

run_bibtex() {
  bibtex "$BASE" > /dev/null
  return $?
}

# Pass 1
run_latex || { echo "compile error (pass 1) — see $DIR/$BASE.log" >&2; exit 2; }

# bibtex (only if .bib referenced)
if grep -q '\\bibliography' "$BASE.tex" 2>/dev/null; then
  if ! run_bibtex; then
    echo "bibtex error — see $DIR/$BASE.blg" >&2
    exit 3
  fi
  # Pass 2 + 3 (resolve cross-refs after bibtex)
  run_latex || { echo "compile error (pass 2) — see $DIR/$BASE.log" >&2; exit 2; }
  run_latex || { echo "compile error (pass 3) — see $DIR/$BASE.log" >&2; exit 2; }
else
  # No bib → just one extra pass for refs
  run_latex || { echo "compile error (pass 2) — see $DIR/$BASE.log" >&2; exit 2; }
fi

echo "OK: $DIR/$BASE.pdf"
exit 0
