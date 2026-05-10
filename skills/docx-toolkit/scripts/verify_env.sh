#!/usr/bin/env bash
# Verify environment for docx-toolkit. Prints a JSON summary and exits 0 if
# the toolkit can run *some* sub-skill, 1 if no sub-skill is usable.
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SKILL_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# Pick a Python: prefer skill-local venv, then any python3 on PATH.
if [[ -x "$SKILL_DIR/.venv/bin/python" ]]; then
  PY="$SKILL_DIR/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PY="$(command -v python3)"
else
  echo '{"ok": false, "reason": "python3 not found"}'
  exit 1
fi

INFO=$("$PY" "$SCRIPT_DIR/detect_os.py")
echo "$INFO" | "$PY" -m json.tool

OS=$(echo "$INFO" | "$PY" -c "import sys,json;print(json.load(sys.stdin)['os'])")
WORD=$(echo "$INFO" | "$PY" -c "import sys,json;print(json.load(sys.stdin)['word_available'])")
UVX=$(echo "$INFO" | "$PY" -c "import sys,json;print(json.load(sys.stdin)['uvx_available'])")
PANDOC=$(echo "$INFO" | "$PY" -c "import sys,json;print(json.load(sys.stdin)['pandoc_available'])")

WARNINGS=()

# python-docx is required for every sub-skill except docx-review live mode.
if ! "$PY" -c "import docx" >/dev/null 2>&1; then
  WARNINGS+=("python-docx not installed (\`uv pip install python-docx\`)")
fi

# uvx is required for docx-review live mode (word-mcp-live).
[[ "$UVX" == "True" ]] || WARNINGS+=("uvx not on PATH — docx-review live mode unavailable (\`brew install uv\`)")

# pandoc is optional but recommended for docx-create MD path.
[[ "$PANDOC" == "True" ]] || WARNINGS+=("pandoc not on PATH — docx-create Markdown path falls back to python-docx only")

# OS-specific checks.
case "$OS" in
  macos)
    if [[ "$WORD" != "True" ]]; then
      WARNINGS+=("Microsoft Word for Mac not detected — docx-format-clone (mac path) and docx-review live mode unavailable")
    fi
    # Probe AppleScript automation (non-fatal — first run requires user grant)
    if ! osascript -e 'return 1' >/dev/null 2>&1; then
      WARNINGS+=("AppleScript not responding — check System Settings → Privacy & Security → Automation")
    fi
    ;;
  windows)
    [[ "$WORD" == "True" ]] || WARNINGS+=("Microsoft Word for Windows not detected — docx-format-clone (win path) unavailable")
    ;;
  linux)
    WARNINGS+=("Linux: only headless sub-skills (create, edit, template) supported")
    ;;
esac

if [[ ${#WARNINGS[@]} -eq 0 ]]; then
  echo "==> docx-toolkit env: OK"
  exit 0
fi

echo "==> docx-toolkit env: ${#WARNINGS[@]} warning(s)"
for w in "${WARNINGS[@]}"; do
  echo "  - $w"
done

# Exit 0 as long as *some* path is usable; only fail hard if nothing works.
if "$PY" -c "import docx" >/dev/null 2>&1; then
  exit 0
fi
echo "==> ERROR: python-docx missing — no sub-skill is usable"
exit 1
