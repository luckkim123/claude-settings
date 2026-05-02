#!/usr/bin/env bash
# claude-settings installer (macOS / Linux)
# Usage: ./install.sh [--copy] [--dry-run] [--verbose]
#   --copy     Copy files instead of symlinking (less convenient for sync)
#   --dry-run  Show actions without executing
#   --verbose  Print extra detail (idempotent skips, resolved secrets count)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COPY_MODE=0
DRY_RUN=0
VERBOSE=0

for arg in "$@"; do
  case "$arg" in
    --copy) COPY_MODE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --verbose) VERBOSE=1 ;;
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

log()   { printf '[install] %s\n' "$*"; }
debug() { [[ $VERBOSE -eq 1 ]] && printf '[debug]   %s\n' "$*" || true; }

# run COMMAND ARG... — executes a command as an array (no eval, no shell metachar surprises)
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

backup_if_needed() {
  local target="$1"
  if [[ -L "$target" ]]; then
    run rm "$target"
  elif [[ -e "$target" ]]; then
    run mkdir -p "$BACKUP_DIR"
    run mv "$target" "$BACKUP_DIR/"
    log "backed up: $target -> $BACKUP_DIR/"
  fi
}

# already_linked TARGET SRC — true if TARGET is a symlink resolving to SRC
already_linked() {
  local target="$1" src="$2"
  [[ -L "$target" && "$(readlink "$target")" == "$src" ]]
}

link_or_copy() {
  local src="$1" dest="$2"
  [[ -e "$src" ]] || { log "skip (missing source): $src"; return; }
  if [[ $COPY_MODE -eq 0 ]] && already_linked "$dest" "$src"; then
    debug "already linked: $dest -> $src (skip)"
    return
  fi
  backup_if_needed "$dest"
  if [[ $COPY_MODE -eq 1 ]]; then
    run cp -R "$src" "$dest"
    log "copied:  $dest"
  else
    run ln -s "$src" "$dest"
    log "linked:  $dest -> $src"
  fi
}

# 1. ~/.claude/
[[ -d "$CLAUDE_HOME" ]] || run mkdir -p "$CLAUDE_HOME"

# 2. user-level settings.json
link_or_copy "$REPO_DIR/claude/settings.json" "$CLAUDE_HOME/settings.json"

# 3. mcp.json — render template (substitute ${VAR} from secrets.env if present).
#    Idempotent: skip backup + rewrite when rendered content matches the existing file.
SECRETS_FILE="$REPO_DIR/secrets/secrets.env"
TEMPLATE="$REPO_DIR/claude/mcp.template.json"
if [[ -f "$TEMPLATE" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    log "would render: $CLAUDE_HOME/mcp.json"
  else
    content="$(cat "$TEMPLATE")"
    if [[ -f "$SECRETS_FILE" ]]; then
      set -a; source "$SECRETS_FILE"; set +a
      resolved=0
      while IFS='=' read -r key _; do
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
        key="${key// /}"
        value="${!key:-}"
        if [[ "$content" == *"\${${key}}"* ]]; then
          content="${content//\$\{${key}\}/${value}}"
          resolved=$((resolved + 1))
        fi
      done < "$SECRETS_FILE"
      debug "resolved $resolved \${VAR} placeholder(s) from secrets.env"
    fi
    if [[ "$content" == *'${'* ]]; then
      log "WARNING: unresolved \${...} placeholders remain in mcp.json — check secrets/secrets.env"
    fi
    if [[ -f "$CLAUDE_HOME/mcp.json" ]] && [[ "$content" == "$(cat "$CLAUDE_HOME/mcp.json")" ]]; then
      debug "mcp.json unchanged (skip)"
    else
      backup_if_needed "$CLAUDE_HOME/mcp.json"
      printf '%s\n' "$content" > "$CLAUDE_HOME/mcp.json"
      chmod 600 "$CLAUDE_HOME/mcp.json"
      log "rendered: $CLAUDE_HOME/mcp.json (perm 600)"
    fi
  fi
fi

# 4. shell config (Unix only)
[[ -f "$REPO_DIR/shell/tmux.conf" ]] && link_or_copy "$REPO_DIR/shell/tmux.conf" "$HOME/.tmux.conf"

# 5. platform-specific extra steps
PLATFORM_INSTALLER="$REPO_DIR/platform/$PLATFORM/install.sh"
if [[ -f "$PLATFORM_INSTALLER" ]]; then
  log "running platform installer: $PLATFORM"
  run bash "$PLATFORM_INSTALLER"
fi

# 6. plugin sync — ensure every enabledPlugin in settings.json is installed at
#    user scope. Idempotent: plugins already at user scope are skipped; ones
#    registered at project/local scope (or with stale "unknown" version) are
#    uninstalled and reinstalled at user scope. Skips cleanly if `claude` or
#    `python3` is unavailable (e.g. before Claude Code is installed).
sync_plugins() {
  if ! command -v claude >/dev/null 2>&1; then
    log "skip plugin sync: 'claude' not in PATH (install Claude Code, then re-run)"
    return
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    log "skip plugin sync: 'python3' not available"
    return
  fi

  local enabled
  enabled="$(CLAUDE_HOME="$CLAUDE_HOME" python3 - <<'PY' 2>/dev/null
import json, os
try:
    d = json.load(open(os.path.join(os.environ["CLAUDE_HOME"], "settings.json")))
    for k, v in d.get("enabledPlugins", {}).items():
        if v:
            print(k)
except Exception:
    pass
PY
)" || true

  if [[ -z "$enabled" ]]; then
    debug "no enabledPlugins to sync"
    return
  fi

  # Ensure canonical marketplace exists if any plugin references it
  if echo "$enabled" | grep -q "@claude-plugins-official"; then
    if ! claude plugin marketplace list 2>/dev/null | grep -q claude-plugins-official; then
      log "adding marketplace: anthropics/claude-plugins-official"
      run claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 \
        || log "  WARNING: failed to add marketplace; check network"
    fi
  fi

  local plugin current ok=0 fixed=0 failed=0
  while IFS= read -r plugin || [[ -n "$plugin" ]]; do
    [[ -z "$plugin" ]] && continue
    current="$(PLUGIN="$plugin" CLAUDE_HOME="$CLAUDE_HOME" python3 - <<'PY' 2>/dev/null
import json, os
try:
    d = json.load(open(os.path.join(os.environ["CLAUDE_HOME"], "plugins", "installed_plugins.json")))
    es = d.get("plugins", {}).get(os.environ["PLUGIN"], [])
    print(es[0].get("scope", "") if es else "none")
except Exception:
    print("none")
PY
)"
    if [[ "$current" == "user" ]]; then
      debug "plugin OK (user): $plugin"
      ok=$((ok+1))
      continue
    fi
    if [[ $DRY_RUN -eq 1 ]]; then
      log "would re-register at user scope: $plugin (currently: $current)"
      continue
    fi
    if [[ "$current" != "none" && "$current" != "user" ]]; then
      claude plugin uninstall -s "$current" -y "$plugin" >/dev/null 2>&1 || true
    fi
    if claude plugin install -s user "$plugin" >/dev/null 2>&1; then
      log "plugin reinstalled (user): $plugin"
      fixed=$((fixed+1))
    else
      log "  WARNING: failed to install: $plugin"
      failed=$((failed+1))
    fi
  done <<< "$enabled"

  log "plugin sync: $ok already user-scope, $fixed fixed, $failed failed"
}
sync_plugins

# 7. local-overrides hint
LOCAL_FILE="$CLAUDE_HOME/settings.local.json"
if [[ ! -e "$LOCAL_FILE" ]]; then
  log "hint: no $LOCAL_FILE — see templates/settings.local.example.json for per-machine plugin overrides"
fi

log "done. backup dir created only if a non-symlink file was overwritten."
