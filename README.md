# claude-settings

Personal Claude Code environment, synced across all my machines (macOS / Linux / Windows) via git.

The promise: **fix or improve a setting on one machine, push, then `git pull` on every other machine to get it instantly** — symlinks make changes take effect without re-running anything.

---

## Quick Start (new machine)

```bash
# 1. Clone (anywhere; ~/claude-settings recommended)
git clone https://github.com/luckkim123/claude-settings.git ~/claude-settings
cd ~/claude-settings

# 2. Run the installer
./install.sh                  # macOS / Linux
# pwsh ./install.ps1          # Windows

# (Optional) If you later add an MCP server that needs an API key:
#   cp secrets/secrets.example.env secrets/secrets.env
#   $EDITOR secrets/secrets.env
#   ./install.sh   # re-render mcp.json
```

That's it. `~/.claude/settings.json` and `~/.tmux.conf` are now symlinks pointing into the repo. `~/.claude/mcp.json` is rendered from the template using your `secrets.env`.

To get future updates: `git pull`. No re-install needed (unless you added new secrets).

---

## What lives where

| Path in repo | Symlink target | Purpose |
|---|---|---|
| `claude/settings.json` | `~/.claude/settings.json` | User-level Claude Code settings (hooks, plugins, thinking, permissions) |
| `claude/mcp.template.json` | rendered into `~/.claude/mcp.json` | MCP server config — `${VAR}` placeholders filled from `secrets.env` |
| `shell/tmux.conf` | `~/.tmux.conf` | tmux config (Unix only) |
| `platform/macos/` | (varies) | macOS-only extras |
| `platform/linux/` | (varies) | Linux-only extras |
| `platform/windows/` | (varies) | Windows-only extras |
| `templates/` | not installed | Boilerplate for new project `.claude/` and `settings.local.json` |
| `secrets/secrets.env` | (read by installer) | **Gitignored.** Real API keys |

### What is NOT here

- `~/.claude/plugins/` — plugins auto-sync via Claude Code's marketplace; tracking them in git would fight the harness
- `~/.claude/settings.local.json` — per-machine overrides (extra plugins, disabled plugins, machine-only permissions); see "Per-machine local plugins" below
- Project-level `.claude/` directories (e.g. `<repo>/.claude/`) — those belong to that project's git repo (see `templates/`)

---

## Per-machine local plugins

`claude/settings.json` lists only the plugins enabled on **every** machine. Machine-specific plugins live in `~/.claude/settings.local.json`, which Claude Code merges on top of the common file by `enabledPlugins` key. The file is gitignored (`*.local.json`).

**Add a per-machine plugin:**

```bash
cp templates/settings.local.example.json ~/.claude/settings.local.json
$EDITOR ~/.claude/settings.local.json   # add only the plugins you want here
```

**Disable a common plugin on this machine only:**

```jsonc
// ~/.claude/settings.local.json
{
  "enabledPlugins": {
    "linear@claude-plugins-official": false
  }
}
```

**Promotion to common** (when a plugin proves useful on a second machine): move the entry from your `settings.local.json` into the repo's `claude/settings.json`, commit, push, then pull on the other machines.

---

## The Sync Workflow

```
machine A: edit something                  machine B (and C, D, ...)
  $EDITOR claude/settings.json    ─┐         git pull     # done
                                   │         # symlinks pick up the new content
  git commit -am "msg" && push  ───┘         # automatically
```

If you add a new MCP server that requires an API key:

```
# 1. on the editing machine: add server entry to claude/mcp.template.json
#    using ${VAR_NAME} placeholder + add VAR_NAME to secrets/secrets.example.env
# 2. on each machine after pulling:
$EDITOR secrets/secrets.env       # add the real value
./install.sh                      # re-renders mcp.json
```

---

## Repo Structure

```
claude-settings/
├── README.md
├── install.sh / install.ps1     # OS-aware installers (idempotent, with backups)
├── .gitignore
│
├── claude/                      # ~/.claude/* (Claude Code itself)
│   ├── settings.json
│   └── mcp.template.json
│
├── shell/                       # Unix shell config
│   └── tmux.conf
│
├── platform/                    # OS-specific extras
│   ├── macos/
│   ├── linux/
│   └── windows/
│
├── templates/                   # boilerplate for new project .claude/ + machine-local
│   ├── project-settings.json
│   ├── project-CLAUDE.md
│   ├── project-gitignore
│   └── settings.local.example.json
│
└── secrets/
    ├── secrets.example.env      # template, committed
    └── secrets.env              # real keys, gitignored
```

---

## Management Rules

1. **Universal vs project-specific** — only universal goes here. If a setting is meaningful only inside one repo (e.g. an Obsidian vault hook, a Python project's pyright config), it belongs in that repo's own `.claude/`. Use `templates/` for the starting boilerplate.
2. **No secrets in git, ever** — anything sensitive belongs in `secrets/secrets.env`. Reference it from `mcp.template.json` as `${VAR_NAME}`. The installer renders the template at install time.
3. **Idempotent installer** — `install.sh` may be re-run any time. Existing non-symlink files at target paths are moved to `~/.claude/.backup-YYYYMMDD-HHMMSS/`.
4. **Symlinks by default, copy fallback** — Unix uses symlinks so `git pull` is enough. Windows tries symlink first, falls back to copy if no admin/Developer Mode.
5. **OS gating** — anything that only makes sense on one OS goes under `platform/<os>/`. The main installer skips others automatically.
6. **Document the path** — when you add a new file, add a row to the "What lives where" table above.
7. **Plugins are not tracked** — `~/.claude/plugins/` is auto-synced by Claude Code. Listing plugin names inside `claude/settings.json` (`enabledPlugins`) is the only thing we sync about them.

---

## Adding a New Setting

```
1. drop the file under claude/, shell/, or platform/<os>/
2. add a `link_or_copy` (or `Link-OrCopy`) line in install.sh / install.ps1
3. add a row to the "What lives where" table in this README
4. commit, push, pull on other machines, run install.sh once
```

If it's a **secret**, instead:

```
1. add the variable to secrets/secrets.example.env (with a placeholder)
2. reference it in claude/mcp.template.json as ${VAR}
3. on each machine, edit secrets/secrets.env to add the real value, then ./install.sh
```

---

## Troubleshooting

**Symlink already exists and points to old location**
The installer detects this and replaces it. If a symlink already resolves to the correct repo source the installer skips it (idempotent).

**A plugin I had enabled disappeared after `git pull`**
It was likely per-machine — moved to `~/.claude/settings.local.json` on the editing machine. Add it to your own local file:
```jsonc
// ~/.claude/settings.local.json
{ "enabledPlugins": { "the-plugin@claude-plugins-official": true } }
```
Then restart Claude Code. The plugin itself is still installed under `~/.claude/plugins/`; only its enabled flag was scoped per-machine.

**`mcp.json` has literal `${VAR}` strings after install**
Either `secrets/secrets.env` doesn't exist, or the variable name doesn't match. Re-check both files and re-run.

**Windows: "operation requires elevation"**
Either run PowerShell as Administrator, enable Developer Mode (Settings > Privacy > For developers), or pass `-Copy` to fall back to copy mode.

**Backup directory keeps piling up**
Safe to delete old `~/.claude/.backup-*` folders once you've confirmed the new install works.

---

## Reverting

Every install backs up overwritten files to `~/.claude/.backup-YYYYMMDD-HHMMSS/`. To revert:

```bash
rm ~/.claude/settings.json
mv ~/.claude/.backup-YYYYMMDD-HHMMSS/settings.json ~/.claude/
```

---

**License**: Personal — feel free to fork, but secrets and machine-specific paths are mine.
