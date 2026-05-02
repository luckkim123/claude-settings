#!/usr/bin/env bash
# claude-settings installer (macOS / Linux)
# Usage: ./install.sh [--copy] [--dry-run]
#   --copy     Copy files instead of symlinking (less convenient for sync)
#   --dry-run  Show actions without executing

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COPY_MODE=0
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --copy) COPY_MODE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux" ;;
  *) echo "Unsupported OS: $OS — use install.ps1 on Windows" >&2; exit 1 ;;
esac

CLAUDE_HOME="$HOME/.claude"
BACKUP_DIR="$CLAUDE_HOME/.backup-$(date +%Y%m%d-%H%M%S)"

log() { printf '[install] %s\n' "$*"; }
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

backup_if_needed() {
  local target="$1"
  if [[ -L "$target" ]]; then
    run "rm '$target'"
  elif [[ -e "$target" ]]; then
    run "mkdir -p '$BACKUP_DIR'"
    run "mv '$target' '$BACKUP_DIR/'"
    log "backed up: $target -> $BACKUP_DIR/"
  fi
}

link_or_copy() {
  local src="$1" dest="$2"
  [[ -e "$src" ]] || { log "skip (missing source): $src"; return; }
  backup_if_needed "$dest"
  if [[ $COPY_MODE -eq 1 ]]; then
    run "cp -R '$src' '$dest'"
    log "copied:  $dest"
  else
    run "ln -s '$src' '$dest'"
    log "linked:  $dest -> $src"
  fi
}

# 1. ~/.claude/
[[ -d "$CLAUDE_HOME" ]] || run "mkdir -p '$CLAUDE_HOME'"

# 2. user-level settings.json
link_or_copy "$REPO_DIR/claude/settings.json" "$CLAUDE_HOME/settings.json"

# 3. mcp.json — render template with secrets (always copy, never symlink — has live keys)
SECRETS_FILE="$REPO_DIR/secrets/secrets.env"
TEMPLATE="$REPO_DIR/claude/mcp.template.json"
if [[ -f "$SECRETS_FILE" && -f "$TEMPLATE" ]]; then
  backup_if_needed "$CLAUDE_HOME/mcp.json"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "would render: $CLAUDE_HOME/mcp.json"
  else
    set -a; source "$SECRETS_FILE"; set +a
    content="$(cat "$TEMPLATE")"
    while IFS='=' read -r key _; do
      [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
      key="${key// /}"
      value="${!key:-}"
      content="${content//\$\{${key}\}/${value}}"
    done < "$SECRETS_FILE"
    printf '%s\n' "$content" > "$CLAUDE_HOME/mcp.json"
    chmod 600 "$CLAUDE_HOME/mcp.json"
    log "rendered: $CLAUDE_HOME/mcp.json (perm 600)"
  fi
elif [[ -f "$TEMPLATE" ]]; then
  log "WARNING: $SECRETS_FILE not found. Copy secrets/secrets.example.env -> secrets/secrets.env and fill in keys, then re-run."
fi

# 4. shell config (Unix only)
[[ -f "$REPO_DIR/shell/tmux.conf" ]] && link_or_copy "$REPO_DIR/shell/tmux.conf" "$HOME/.tmux.conf"

# 5. platform-specific extra steps
PLATFORM_INSTALLER="$REPO_DIR/platform/$PLATFORM/install.sh"
if [[ -f "$PLATFORM_INSTALLER" ]]; then
  log "running platform installer: $PLATFORM"
  run "bash '$PLATFORM_INSTALLER'"
fi

log "done. ${BACKUP_DIR##*/} created if backups were needed."
