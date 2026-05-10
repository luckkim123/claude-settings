# Reviewer → Aggregator Handoff Schema

All `paper-*-reviewer` agents and `paper-fixer` MUST emit a single JSON object matching this schema as their final output. Free-form text only inside `summary`/`evidence`/`score_rationale` fields. No prose before or after the JSON.

## Top-level structure

```json
{
  "agent": "paper-logic-reviewer",
  "version": "1.0",
  "round": 2,
  "target_file": "main.tex",
  "lang": "ko",
  "score": 78,
  "score_rationale": "<= 1 sentence per deduction, plain text",
  "findings": [ /* array of finding objects, see below */ ],
  "summary": "<= 3 sentences, plain text"
}
```

### Field semantics

| Field | Type | Required | Notes |
|---|---|---|---|
| `agent` | string | yes | Must equal one of: `paper-logic-reviewer`, `paper-prose-reviewer`, `paper-citation-verifier`, `paper-figure-auditor`, `paper-latex-linter` |
| `version` | string | yes | Schema version. Currently `"1.0"`. |
| `round` | integer ≥1 | yes | Critic-fixer round number, supplied by orchestrator |
| `target_file` | string | yes | Relative path from project root, e.g. `paper/latex/main.tex` |
| `lang` | `"ko"` \| `"en"` | yes | Language of the file being reviewed |
| `score` | integer 0–100 | yes | Reviewer's holistic score for THIS dimension only |
| `score_rationale` | string | yes | Why this score, deductions enumerated |
| `findings` | array | yes | May be empty. Each item per "Finding object" below. |
| `summary` | string | yes | High-level take, plain text, ≤3 sentences |

## Finding object

```json
{
  "id": "logic-r2-001",
  "severity": "critical",
  "location": "sec:methodology, lines 142-160",
  "issue": "Contribution 2 (real-time inference)의 latency 측정이 본문에 없음",
  "evidence": "abstract에서 '30Hz real-time' 주장, experiments에 측정 결과 없음",
  "suggestion": "Table 2에 inference latency column 추가 또는 contribution 2 표현 약화",
  "fixable_by_llm": false
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | Format: `<agent_short>-r<round>-<NNN>`. `agent_short` ∈ {logic, prose, cite, figure, lint}. Same logical issue across rounds MUST keep the same `<NNN>` so escalation tracker can detect repetition. |
| `severity` | enum | yes | `critical` (blocks gate, weight 10) / `important` (weight 3) / `minor` (weight 1) |
| `location` | string | yes | Section ref + line range or figure/table label. Be specific enough that fixer can find it. |
| `issue` | string | yes | One-sentence problem statement |
| `evidence` | string | yes | Direct quote from the .tex or specific observable (e.g., "Table 2 has no latency column"). Lets fixer verify before acting. |
| `suggestion` | string | yes | Concrete fix. If unfixable, describe what action is required (e.g., "rerun experiment X"). |
| `fixable_by_llm` | boolean | yes | `true` if a text edit to the .tex/bib alone can fix it. `false` for missing experiments, missing figures, fundamental contribution gaps — these go to human escalation. |

## Hard rules

1. **Output is JSON only.** No markdown wrappers, no commentary, no preamble. The orchestrator parses with `json.loads`. If parsing fails the reviewer's output is treated as an empty findings list AND a warning is logged.
2. **No invented evidence.** Every `evidence` field must quote or describe something verifiable in the input. Hallucinated evidence is worse than no finding.
3. **Severity discipline.** `critical` only when the paper would fail review at this venue. `minor` for nits a copy-editor would catch. When in doubt, downgrade.
4. **`fixable_by_llm` honesty.** Setting `true` for things that actually require new experiments or figures will cause the fixer to fabricate. Defaulting to `false` is safer.
5. **`id` stability.** When re-reviewing after a fixer pass, if the same logical issue persists, reuse the same `<NNN>` suffix. New issues get fresh numbers. The orchestrator's escalation tracker uses these IDs.
6. **No `.tex` modification.** Reviewer agents have read-only tools (`Read`, `Grep`, `Glob`, `Bash` for compilation only). Only `paper-fixer` writes.

## Aggregator output (for reference)

`scripts/score_aggregate.py` produces:

```json
{
  "weighted_score": 84.2,
  "per_reviewer": {"paper-logic-reviewer": 85, "paper-prose-reviewer": 72, ...},
  "passed": true,
  "critical_count": 0,
  "priority_queue": [ /* up to 5 findings, sorted by severity then fixable then round-age */ ],
  "human_escalation": [ /* findings with fixable_by_llm=false OR same id alive ≥3 rounds */ ]
}
```

Gate condition: `weighted_score >= venue.quality_threshold AND critical_count == 0`. Both required.
