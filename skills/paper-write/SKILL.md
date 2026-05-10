---
name: paper-write
description: End-to-end LaTeX academic paper writing skill with multi-agent review and venue-aware orchestration. Use when user asks to "write a paper end-to-end", "/paper-write", "논문 자동 작성", or wants to take a project from concept to submission-ready LaTeX with quality gates. Coordinates research → outline → Korean LaTeX → review → English → submission.
disable-model-invocation: true
---

# Paper-Write Orchestrator

End-to-end paper writing pipeline with multi-agent review, critic-fixer loop, and venue-aware configuration.

> **Status**: Phase 1 (skeleton). Stages ⑤–⑦ orchestration is wired in Phase 4–5. Stage 0 (dry-run) is functional now.

## Invocation

```
/paper-write <project_path> --venue <venue_key>
```

Examples:
- `/paper-write iros_2026 --venue iros`
- `/paper-write bachelor_thesis_2026 --venue kaist_thesis`

If `--venue` is omitted, ask the user. Do NOT guess.

## Stage 0 — Dry-Run (current Phase 1 capability)

1. Resolve `<project_path>` against `0_Project/in_progress/` if not absolute
2. Load `venues/<venue_key>.yaml` — fail loudly if missing or schema-invalid
3. Verify `template_dir` exists in vault
4. Verify `<project>/paper/` exists
5. Print loaded venue config + project state summary
6. STOP — no LaTeX generation yet (Phase 5)

## 7-Stage Workflow (Phases 2–5 will fill these in)

```
① research              → research skill (delegated)
② outline + 노트        → paper-organize skill (delegated)
   🛑 checkpoint 1: outline approval
③ 노트 → 한국어 LaTeX   → write skill, Stage 2 (delegated)
④ 컴파일 + 자가 수정    → scripts/compile.sh + paper-latex-linter
⑤ 멀티 리뷰 + 루프     → 5 reviewers (parallel) → score_aggregate → paper-fixer
   🛑 checkpoint 2: Korean score + "proceed to English?"
⑥ 한→영 번역           → write skill, Stage 3 (delegated)
⑤' 영어 라운드          → 5 reviewers (re-run on English)
⑦ 제출 패키지          → extras handling (zip, cover_letter, checklist)
   🛑 checkpoint 3: final confirmation
```

## Key References

- **`references/workflow.md`** — Detailed stage-by-stage procedure (Phase 5)
- **`references/handoff-schema.md`** — Reviewer→fixer JSON schema (Phase 3)
- **`references/checkpoint-format.md`** — Checkpoint UI/report format (Phase 5)
- **`venues/venue-template.yaml`** — Template for adding a new venue
- **Design doc**: `docs/plans/2026-05-10-paper-write-skill-design.md`

## Sub-Agents (created in Phases 2–4)

| Agent | Model | Role |
|---|---|---|
| `paper-logic-reviewer` | opus | Logic, structure, contributions, devil's advocate |
| `paper-prose-reviewer` | opus | Academic English, clarity, tone |
| `paper-citation-verifier` | sonnet | DOI verification, citation appropriateness |
| `paper-figure-auditor` | sonnet | Caption-body consistency, label/ref matching |
| `paper-latex-linter` | haiku | Compile errors, overfull, undefined refs |
| `paper-fixer` | opus | **Only agent with write permission** — applies fixes |

## Principles (do not violate)

- **Diagnosis ≠ prescription** — Reviewers never edit `.tex`. Only `paper-fixer` writes.
- **Delegate, don't absorb** — Existing `research`, `paper-organize`, `write` skills are called, not reimplemented.
- **Declarative venue config only** — No arbitrary code paths in venue YAML. Unknown `extras` flags must error.
- **Hard gates can't be bypassed** — `weighted_score >= threshold AND critical_findings == 0`. Never force-pass.
- **Human escalation is mandatory** — When fixer can't fix (`fixable_by_llm: false`), surface to user. Never lie that it's done.
