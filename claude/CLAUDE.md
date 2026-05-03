# CLAUDE.md (user-scope)

Universal behavioral rules for Claude Code, applied across **all** projects and machines.

This file is symlinked to `~/.claude/CLAUDE.md` by the installer. Project-level `CLAUDE.md` files in individual repos add project-specific rules on top of these.

> Source: derived from [Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls (the four principles), plus personal operational limits.

---

## Behavioral Principles

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. If uncertain, ask.
- Multiple interpretations exist? Present them — don't pick silently.
- Simpler approach available? Push back.
- Confused? Stop. Name what's unclear. Ask.

### 2. Simplicity First

**Minimum code/content that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and 50 would do, rewrite.
- Minimize test scripts and temporary file creation.

Test: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what was requested. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Notice unrelated dead code? Mention it — don't delete.
- Only do what user asks, nothing more.

Test: every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

| Instead of... | Transform to... |
|:---|:---|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

## Operational Limits

- **3-Strike Rule**: same approach fails 3 times → change method immediately.
- **15-Min Limit**: stuck > 15 min on one problem → try different approach.

---

## Workflow

- **Skill Utilization**: use available skills (via `/skill-name`) when their expertise matches the task. Skills tell you HOW to approach things — invoke them before acting.
- **Project CLAUDE.md First**: when a project has its own `CLAUDE.md` or `.claude/rules/*`, read it before working. Project rules override these universal ones.
- **Date Awareness**: ALWAYS check current date (shown in `<env>` tags). When year not specified, assume current year or future. NEVER create past-dated artifacts unless explicitly requested.
- **Compound Learnings**: when a task surfaces a non-obvious decision, surprising result, or hard-won fix, log a one-line entry to the auto-memory system (`~/.claude/projects/<project>/memory/`) before ending the task. Reference past learnings when starting similar work — each task should make the next one easier, not harder.
- **Clear on Loop**: if you've corrected the same issue more than twice in one session, the context is polluted with failed approaches. Run `/clear` and restart with a more specific prompt incorporating what you learned. A fresh session with a better prompt almost always outperforms a long session with accumulated corrections.

---

## Tradeoff Note

These guidelines bias toward **caution over speed**. For trivial tasks (typo fixes, obvious one-liners), use judgment — not every change needs the full rigor.

The goal is reducing costly mistakes on non-trivial work, not slowing down simple tasks.

---

**Last Updated**: 2026-05-03
**Managed by**: [`claude-settings`](https://github.com/luckkim123/claude-settings) — edit at `~/claude-settings/claude/CLAUDE.md`, the symlink picks up changes automatically.
