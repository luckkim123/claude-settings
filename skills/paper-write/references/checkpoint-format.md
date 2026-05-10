# Checkpoint Output Format

Three human-in-the-loop checkpoints in the paper-write pipeline. Each has a fixed Markdown template so the user always knows what to look at and what to decide.

All checkpoints share these properties:

- **Output to chat as Markdown**, not to a file. The user reads it inline.
- **End with a single explicit question** so the user knows what input is needed.
- **Never auto-proceed.** Wait for the user's response.
- **If toggle is `false`**, do NOT render the checkpoint — log a one-liner instead: `"checkpoint N skipped per venue config"`.

---

## Checkpoint 1 — Outline approval (after Stage 2)

```markdown
## 🛑 Checkpoint 1 — Outline approval

**Project**: <project_path>
**Venue**: <venue.name> (page_limit <N>, abstract <W> words)

### Section tree

- **Introduction** (~<budget> words)
  - <subsection bullet 1>
  - <subsection bullet 2>
- **Related Work** (~<budget> words)
  - ...
- **Methodology** (~<budget> words)
  - ...
- **Experiments** (~<budget> words)
  - ...
- **Conclusion** (~<budget> words)
  - ...

### Notes coverage

| Section | Notes file | Bullets | Has key-claim? |
|---|---|---|---|
| Introduction | notes/introduction.md | 8 | yes |
| Related Work | notes/related_work.md | 12 | yes |
| ... | ... | ... | ... |

**Total budget**: <sum> words / <venue.page_limit * 600> word allowance

---

**Approve and proceed to Stage 3 (Korean LaTeX)?**
- `proceed` — start writing
- `revise: <what to change>` — loop back to paper-organize
- `abort` — stop the pipeline
```

**Word budget heuristic**: ~600 words/page for IEEE conference 2-column 10pt. Adjust based on `venue.class`.

---

## Checkpoint 2 — Korean review pass (after Stage 5, before Stage 6)

This is the most consequential checkpoint — it gates the (expensive) translation stage.

```markdown
## 🛑 Checkpoint 2 — Korean review complete

**Project**: <project_path> | **Round**: <final_round> | **Gate**: ✅ PASSED / ❌ FAILED

### Aggregate scorecard

| Reviewer | Score | Weight | Contribution |
|---|---|---|---|
| paper-logic-reviewer | 82 | 1.0 | 82.0 |
| paper-prose-reviewer | 75 | 0.8 | 60.0 |
| paper-citation-verifier | 88 | 1.0 | 88.0 |
| paper-figure-auditor | 79 | 1.0 | 79.0 |
| paper-latex-linter | 100 | 0.6 | 60.0 |
| **Weighted score** | | | **82.07** / threshold <T> |

**Critical findings remaining**: <N>

### Round-over-round trajectory

| Round | Weighted | Δ | Critical | Findings applied | Compile |
|---|---|---|---|---|---|
| 1 | 70.82 | — | 5 | — | OK |
| 2 | 73.09 | +2.27 | 4 | 2/5 | OK |
| 3 | 82.07 | +8.98 | 0 | 3/4 | OK |

### Remaining human escalations (<N> items)

For each `human_escalation` item from the latest aggregate.json:

- **<finding.id>** [<severity>] — <finding.issue>
  - *Location*: <finding.location>
  - *Why escalated*: <reason; usually fixable_by_llm=false>
  - *Suggested action*: <finding.suggestion>

(If list is empty: "No human escalations remaining.")

### Files

- `main.tex`: <bytes> bytes, last modified <ts>
- `references.bib`: <N> entries, all DOI-verified
- Aggregate JSON: `/tmp/<slug>/r<final>/aggregate.json`

---

**Proceed to Stage 6 (English translation)?**
- `proceed` — translate KO → EN, then re-run reviewers in English
- `another round` — run round <final+1> (only if < max_review_rounds)
- `address: <id>` — pause for user to fix a specific escalation manually
- `abort` — stop here, keep Korean version as-is
```

**If gate failed** (max rounds hit or regression detected): replace the "Proceed?" line with:

```markdown
⚠ Gate did not pass. Reason: <"max_review_rounds reached" | "regression detected (Δ -7.3 > threshold 5)" | "fixer compile failure">

**How to proceed?**
- `accept current` — proceed to Stage 6 with sub-threshold quality (your call)
- `revise: <description>` — describe what to change manually, then resume
- `abort` — stop the pipeline
```

---

## Checkpoint 3 — Submission confirmation (after Stage 7)

```markdown
## 🛑 Checkpoint 3 — Submission package ready

**Project**: <project_path>
**Venue**: <venue.name>
**Final language**: English
**Final score** (English round <N>): <weighted>

### Format checklist

| Constraint | Limit | Actual | Status |
|---|---|---|---|
| Page count | <page_limit> (hard <page_hard_limit>) | <pages> | ✅ / ⚠ / ❌ |
| Abstract words | <abstract_words> ±20% | <words> | ✅ |
| Title words | <title_max_words> | <words> | ✅ |
| Min citations | <min_citations> | <count> | ✅ |
| Self-citation ratio | <self_citation_max_ratio> | <ratio> | ✅ |

### Submission manifest

| File | Size | Notes |
|---|---|---|
| <project>_source.zip | <bytes> | LaTeX sources, no aux/log/bbl |
| main.pdf | <bytes> | Final compiled PDF |
| format_checklist.md | <bytes> | This checklist as a file |
| cover_letter.md | <bytes> | (if extras included) |

All files under: `<paper_dir>/submission/`

### Final pre-flight

- [x] Compile clean (last attempt: <ts>)
- [x] All bib entries DOI-verified (verify_bib.py: 0 unverified)
- [x] No Korean characters in `.tex` source
- [x] No `\todo{}` / `XXX` / `FIXME` markers
- [<bool>] All checkpoint 2 escalations addressed or explicitly waived

---

**Confirm ready for submission?**
- `confirm` — declare done, log to project README
- `revise: <description>` — loop back to a specific stage
- `abort` — keep files but do not declare ready
```

If any pre-flight item is `[ ]`, list which ones above the question and recommend `revise` rather than `confirm`.

---

## Common rendering rules

- Numbers: round to 2 decimals (`weighted_score: 82.07`).
- Status icons: ✅ pass, ⚠ warning (within tolerance), ❌ fail.
- Paths: prefer paths relative to `<project>` for readability; keep `/tmp/` paths absolute since they're system locations.
- Lists with > 10 items: truncate to 10 with "(+ N more)" footer; full list goes to `aggregate.json`.
- Never embed raw JSON in the checkpoint output. JSON belongs in files; checkpoints are human-readable.

## What NOT to put in a checkpoint

- The full `aggregate.json` — too noisy, point to the file path instead.
- Reviewer prose summaries — those are for debugging, not decisions.
- Internal agent dispatch logs — irrelevant to the user's go/no-go choice.
- Speculative next-step suggestions ("you might also want to..."). Stick to the question being asked.

The user is making a decision. Show them only what's needed for that decision.
