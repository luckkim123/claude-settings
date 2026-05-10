# docx-toolkit

A Claude Code skill bundle for creating, editing, reviewing, templating, and format-cloning `.docx` files. Mac/Win primary, Linux headless fallback.

## Status

Phase 0 (skeleton) — under active development. See `docs/plans/2026-05-10-docx-toolkit-plan.md` in the user's vault for roadmap.

## Layout

- `SKILL.md` — top-level router (Phase 7)
- `scripts/` — common utilities (`detect_os.py`, `docx_inspect.py`, `verify_env.sh`)
- `lib/` — Python helpers + seed `.docx` files
- `sub-skills/` — 5 specialized sub-skills (create / edit / review / template / format-clone)
- `references/` — lazy-loaded knowledge files
- `tests/` — pytest unit tests + integration scenarios

## Install

Run from `~/claude-settings/`:

```bash
bash install.sh    # symlinks this skill to ~/.claude/skills/docx-toolkit/
```

Then verify:

```bash
bash ~/.claude/skills/docx-toolkit/scripts/verify_env.sh
```

## Dependencies

- Homebrew (mac): `uv`, `pandoc`
- Python (managed by uv): `python-docx`, `docxtpl`, `pytest`
- Optional: Microsoft Word (mac/win) — required for `docx-review` (live mode) and `docx-format-clone`
- Optional: `word-mcp-live` (auto-installed via `uvx` when needed)

## License

MIT for this skill. See `NOTICE.md` for upstream attributions (word-format-skill Apache 2.0, word-mcp-live MIT).
