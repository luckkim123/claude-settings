#!/usr/bin/env python3
"""score_aggregate.py — combine N reviewer JSON outputs + venue YAML → gate decision.

Usage:
    score_aggregate.py --venue venues/iros.yaml --inputs review1.json review2.json ...
    score_aggregate.py --venue venues/iros.yaml --inputs-dir reviews/

Output (stdout JSON):
    {
      "weighted_score": float,
      "per_reviewer": {agent: score, ...},
      "passed": bool,
      "critical_count": int,
      "priority_queue": [up to 5 findings, sorted],
      "human_escalation": [findings needing human action]
    }

Gate: weighted_score >= venue.quality_threshold AND critical_count == 0.

Stdlib only (yaml fallback to a tiny parser if PyYAML missing).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

try:
    import yaml  # type: ignore
except ImportError:
    yaml = None  # type: ignore[assignment]

AGENT_TO_KEY = {
    "paper-logic-reviewer": "logic",
    "paper-prose-reviewer": "prose",
    "paper-citation-verifier": "citation",
    "paper-figure-auditor": "figure",
    "paper-latex-linter": "lint",
}

SEVERITY_RANK = {"critical": 0, "important": 1, "minor": 2}


def load_yaml(path: Path) -> dict[str, Any]:
    if yaml is None:
        raise SystemExit("PyYAML required (pip install pyyaml).")
    return yaml.safe_load(path.read_text())


def load_reviewer_json(path: Path) -> dict[str, Any] | None:
    """Robust: extract the first valid JSON object from the file even if wrapped in prose."""
    text = path.read_text(encoding="utf-8")
    # Try direct parse
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    # Strip ```json fences
    if "```" in text:
        for chunk in text.split("```"):
            chunk = chunk.strip()
            if chunk.startswith("json"):
                chunk = chunk[4:].strip()
            try:
                return json.loads(chunk)
            except json.JSONDecodeError:
                continue
    # Find first { ... } block by brace matching
    start = text.find("{")
    while start != -1:
        depth = 0
        for i in range(start, len(text)):
            c = text[i]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    try:
                        return json.loads(text[start:i + 1])
                    except json.JSONDecodeError:
                        break
        start = text.find("{", start + 1)
    return None


def aggregate(reviewer_outputs: list[dict[str, Any]], venue: dict[str, Any]) -> dict[str, Any]:
    weights: dict[str, float] = venue.get("review_weights", {})
    threshold: float = venue.get("quality_threshold", 80)

    per_reviewer: dict[str, int] = {}
    weighted_sum = 0.0
    weight_total = 0.0
    all_findings: list[dict[str, Any]] = []
    parse_failures: list[str] = []

    for r in reviewer_outputs:
        agent_raw = r.get("agent")
        agent: str = str(agent_raw) if agent_raw else ""
        key = AGENT_TO_KEY.get(agent)
        if not key:
            parse_failures.append(f"unknown agent: {agent_raw!r}")
            continue
        score = r.get("score")
        if not isinstance(score, (int, float)):
            parse_failures.append(f"{agent}: missing/invalid score")
            continue
        w = float(weights.get(key, 1.0))
        per_reviewer[agent] = int(score)
        weighted_sum += score * w
        weight_total += w
        for f in r.get("findings", []):
            f = dict(f)
            f["_agent"] = agent
            all_findings.append(f)

    weighted_score = weighted_sum / weight_total if weight_total > 0 else 0.0
    critical = [f for f in all_findings if f.get("severity") == "critical"]
    passed = weighted_score >= threshold and len(critical) == 0

    # Priority queue: severity ASC, then fixable_by_llm DESC, then keep first
    priority = sorted(
        all_findings,
        key=lambda f: (
            SEVERITY_RANK.get(f.get("severity", "minor"), 2),
            0 if f.get("fixable_by_llm") else 1,
        ),
    )[:5]

    # Escalation: not fixable by LLM (regardless of severity)
    escalation = [f for f in all_findings if not f.get("fixable_by_llm")]

    out: dict[str, Any] = {
        "weighted_score": round(weighted_score, 2),
        "threshold": threshold,
        "per_reviewer": per_reviewer,
        "passed": passed,
        "critical_count": len(critical),
        "total_findings": len(all_findings),
        "priority_queue": priority,
        "human_escalation": escalation,
    }
    if parse_failures:
        out["parse_failures"] = parse_failures
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--venue", type=Path, required=True)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--inputs", nargs="+", type=Path)
    g.add_argument("--inputs-dir", type=Path)
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    venue = load_yaml(args.venue)

    paths: list[Path] = list(args.inputs) if args.inputs else sorted(args.inputs_dir.glob("*.json"))
    reviewer_outputs: list[dict[str, Any]] = []
    failed_files: list[str] = []
    for p in paths:
        obj = load_reviewer_json(p)
        if obj is None:
            failed_files.append(str(p))
            continue
        reviewer_outputs.append(obj)

    result = aggregate(reviewer_outputs, venue)
    if failed_files:
        result.setdefault("parse_failures", []).extend(f"file unparseable: {f}" for f in failed_files)

    text = json.dumps(result, ensure_ascii=False, indent=2)
    if args.out:
        args.out.write_text(text)
        print(f"wrote {args.out}")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
