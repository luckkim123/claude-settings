# paper-write Workflow Runbook

The per-stage procedure for the 7-stage pipeline declared in `SKILL.md`. Read this when actually running `/paper-write` — `SKILL.md` is the index, this is the manual.

All paths are vault-relative unless noted. `<project>` = `0_Project/in_progress/<project_path>` after Stage 0 resolution.

---

## Stage 0 — Resolve and dry-run

1. Parse args: `<project_path>`, `--venue <key>`, optional `--lang ko|en`, `--from-stage N`.
2. Resolve `<project_path>`. If not absolute and not found, look under `0_Project/in_progress/`.
3. Load `venues/<key>.yaml` with `yaml.safe_load`. Validate against the template:
   - All required keys present (see `venues/venue-template.yaml`).
   - No unknown keys → **error**, not warning. (Catches typos that would silently disable features.)
   - `quality_threshold ∈ [0, 100]`, `max_review_rounds >= 1`, `regression_threshold >= 0`.
4. Resolve fixed paths: `paper_dir = <project>/paper/`, `main_tex = <paper_dir>/latex/main.tex`, `bib_file = <paper_dir>/latex/references.bib`.
5. If `--from-stage N` given, skip stages `< N` (still print the dry-run).
6. Print:

   ```
   project       : <project>
   venue         : <key>  (<venue.name>)
   main_tex      : <main_tex>           [exists | will create]
   bib_file      : <bib_file>           [exists | will create]
   threshold     : <quality_threshold>  (max_rounds=<N>, regression>=<R>)
   checkpoints   : outline=<bool>, korean_review=<bool>, submission=<bool>
   start_stage   : <stage_number>
   ```

7. Wait for user "go". If user does nothing for one turn, ask explicitly.

---

## Stage 1 — Research (delegated)

**Skill**: `research` (vault-local).

**Inputs**: project topic (read from `<project>/README.md` or ask user), venue's domain hint (`venue.name`).

**Outputs expected** at `<project>/research/`:
- `related_work.md` — table of cited papers with one-line take per paper
- `gaps.md` — what's missing in the literature, framing the contribution

**Pass/fail**: at least one paper in `related_work.md` AND `gaps.md` exists with > 0 bytes.

If skill produces fewer than `venue.min_citations` references, log a warning but continue — citations can be added during writing. Hard-fail only if zero references.

---

## Stage 2 — Outline + section notes (delegated)

**Skill**: `paper-organize`.

**Inputs**: research outputs from Stage 1, `venue.sections` (target structure), `venue.page_limit` (rough budget).

**Outputs expected** at `<project>/paper/notes/`:
- `outline.md` — section tree matching `venue.sections`, plus subsection bullets
- `<section_slug>.md` for each required section — bullet notes, key claims, figure/table placeholders

**Pass/fail**: every section in `venue.required_sections` has a notes file with > 0 bytes.

### 🛑 Checkpoint 1 (if `venue.checkpoints.outline_required`)

Render the outline + word budget per section using template in `references/checkpoint-format.md` and ask user to approve / request changes. Loop on revisions until user says "proceed".

If toggle is `false`: log `"checkpoint 1 skipped per venue config"` and continue.

---

## Stage 3 — Notes → Korean LaTeX (delegated)

**Skill**: `write` Stage 2 (vault-local "write" skill, the existing one).

**Inputs**: notes from Stage 2, `venue` (for `class`, `class_options`, `extra_packages`, `bib_style`, `template_dir`).

**Outputs expected**:
- `<main_tex>` exists and uses `\documentclass[<class_options>]{<class>}`
- One `\input{sections/<slug>}` per required section
- `<bib_file>` exists (may be empty stub initially)

**Pass/fail**: `<main_tex>` parses with `pdflatex -draftmode -halt-on-error` (single pass, no bibtex yet).

---

## Stage 4 — Compile + self-fix loop

This is a small lint-only loop, not the big critic-fixer loop. It exists to make sure Stage 5 reviewers see a buildable PDF.

```
attempts = 0
while attempts < 3:
    bash scripts/compile.sh <main_tex> <venue.compile_engine>
    if exit 0:
        break
    dispatch paper-latex-linter agent on the .log file
    apply linter's suggested fixes via paper-fixer (single-finding mode)
    attempts += 1
else:
    abort: surface compile log + linter findings to user, ask for guidance
```

After this stage you should have a buildable PDF, even if quality is poor. Quality is Stage 5's job.

---

## Stage 5 — Multi-reviewer + critic-fixer loop (Korean)

This is the heart of the skill. Pseudocode is in `SKILL.md` under "Stage 5 — Critic-fixer loop". Operational notes:

### Per-round file layout

```
/tmp/<project_slug>/r<round>/
    paper-logic-reviewer.json
    paper-prose-reviewer.json
    paper-citation-verifier.json
    paper-figure-auditor.json
    paper-latex-linter.json
    aggregate.json
    fixer.json          (only if a fix round happened)
```

`<project_slug>` = basename of project_path with non-`[a-z0-9_]` stripped.

### Dispatching the 5 reviewers in parallel

In **one** Agent tool message, send 5 tool blocks. Each block prompt must include:

- The role/task (one paragraph; the agent's own SKILL has the rest)
- Absolute path to `<main_tex>`
- Absolute path to `<bib_file>` (citation-verifier and logic only)
- The `round` number
- Where to write the JSON output: `/tmp/<project_slug>/r<round>/<agent_name>.json`
- Strict reminder: **JSON only, no prose, conform to `references/handoff-schema.md`**

Wait for all 5 to return before aggregating.

### Aggregating

```bash
python3 .claude/skills/paper-write/scripts/score_aggregate.py \
    --venue .claude/skills/paper-write/venues/<key>.yaml \
    --inputs-dir /tmp/<project_slug>/r<round>/ \
    --out /tmp/<project_slug>/r<round>/aggregate.json
```

Read `aggregate.json` and check end conditions in this order:

1. **Gate pass** (`passed == true`): exit loop, success.
2. **Max rounds** (`round >= venue.max_review_rounds`): exit, surface escalations.
3. **Regression** (`round >= 2 AND prev_score - weighted_score > venue.regression_threshold`): exit, ask user — fixer is hurting.

Otherwise dispatch fixer.

### Dispatching paper-fixer

Single Agent call with one tool block. Prompt must include:

- `aggregate_json_path` (absolute)
- `target_file` (absolute path to `<main_tex>`)
- `bib_file` (absolute)
- `venue_yaml_path` (absolute)
- `round`
- Output path: `/tmp/<project_slug>/r<round>/fixer.json`

Fixer recompiles internally. If `compile_status == "failed"` (after up to 3 rollbacks), exit loop and surface the rollback report — do not start round N+1 on a broken file.

After fixer success: increment `round`, save `prev_score = weighted_score`, loop.

### 🛑 Checkpoint 2 (if `venue.checkpoints.korean_review_required`)

Render aggregate scorecard + any `human_escalation` items using `references/checkpoint-format.md`. Ask user:

- Approve and proceed to English translation?
- Want another round?
- Address an escalation manually first?

If toggle is `false`: log `"checkpoint 2 skipped per venue config"`, proceed to Stage 6.

---

## Stage 6 — Korean → English translation (delegated)

**Skill**: `write` Stage 3.

**Inputs**: Korean `<main_tex>` and section files from Stage 5 (post-fix), `venue` (for terminology consistency hints if any).

**Outputs**: same files, now in English. Old Korean files preserved at `<paper_dir>/latex/_ko_backup/<timestamp>/` (translator skill's responsibility — verify it happened, fail loud if not).

**Pass/fail**: every required section's English file compiles AND no Korean characters (`[ㄱ-힝]`) remain in the .tex source. Run a quick `grep -r '[가-힣]' <paper_dir>/latex/sections/` — should return nothing.

---

## Stage 5' — English critic-fixer loop

Same as Stage 5 but with `lang: "en"` in the dispatch prompts. All reviewers, fixer, aggregator, gate, and regression logic are language-agnostic — only the prompt context changes.

Reviewers' `prose` agent is the most language-sensitive: ensure its prompt explicitly says "review English academic prose", not "review prose".

Same checkpoint 2 format applies, but the question is "approve and proceed to submission packaging?".

---

## Stage 7 — Submission packaging

For each item in `venue.extras`:

| Extra key | Action |
|---|---|
| `source_zip` | Zip `<paper_dir>/latex/` excluding `_ko_backup/`, `.aux`, `.log`, `.out`, `.bbl`, `.blg`, `.synctex.gz`. Place at `<paper_dir>/submission/<project_slug>_source.zip`. |
| `format_checklist` | Generate Markdown checklist comparing the compiled PDF against `venue.page_limit`, `venue.page_hard_limit`, `venue.abstract_words`, `venue.title_max_words`. Output: `<paper_dir>/submission/format_checklist.md`. |
| `cover_letter` | Generate `<paper_dir>/submission/cover_letter.md` from a stub template (only if `cover_letter` is in `extras`). User fills in venue-specific fields. |
| `response_letter` | Only meaningful for resubmissions; stub template at `<paper_dir>/submission/response_letter.md`. |

Unknown `extras` key → **error** (no silent skip). This catches venue YAML typos.

### 🛑 Checkpoint 3 (if `venue.checkpoints.submission_confirm`)

Render submission manifest (file list with sizes + format checklist summary) per `references/checkpoint-format.md`. Ask user to confirm before declaring "ready to submit".

If toggle is `false`: log `"checkpoint 3 skipped per venue config"` and print the manifest anyway.

---

## Resumption (`--from-stage N`)

The pipeline is mostly idempotent at stage boundaries because each stage writes to deterministic paths:

| Resume from | Requires existing |
|---|---|
| 2 | `<project>/research/related_work.md` |
| 3 | `<project>/paper/notes/outline.md` and per-section notes |
| 4 | `<main_tex>` |
| 5 | `<main_tex>` compiles |
| 6 | Stage 5 ended in gate pass (check that the latest `aggregate.json` has `passed: true`) |
| 7 | English `<main_tex>` compiles |

If a precondition is missing, abort with a clear message naming the missing file — don't try to "fix it for them".

---

## Failure modes you'll actually hit

| Symptom | Likely cause | Fix |
|---|---|---|
| Aggregator reports `parse_failures` | A reviewer wrapped its JSON in markdown or chatted | Re-dispatch that reviewer with a stricter prompt |
| Fixer skipped everything as `evidence not found` | File state diverged from reviewer evidence | Re-run reviewers (they had stale view) |
| Compile breaks after fixer round | Fixer's rollback didn't reach the breaking edit | User must manually inspect; do not auto-rollback further |
| Score oscillates (78 → 81 → 75 → 80) | Reviewer non-determinism; trips regression check | Lower `regression_threshold` or accept current best round and exit |
| `verify_bib.py` flags valid arXiv preprint as invalid | CrossRef has no record yet | Citation reviewer should mark `fixable_by_llm: false` with note |

---

## Out-of-scope (don't do)

- Don't edit `<main_tex>` outside the fixer agent. Even "obvious" typos go through a finding → fixer cycle so the audit trail stays complete.
- Don't change `venue.<anything>` mid-run. If user wants different settings, restart with edited YAML.
- Don't skip checkpoints to "save time". The toggle is per-venue YAML for a reason; respect it.
- Don't keep looping past `max_review_rounds`. The cap exists because diminishing returns set in around round 3-4 for most papers.
