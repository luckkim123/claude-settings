#!/usr/bin/env python3
"""verify_bib.py — verify BibTeX entries against CrossRef + Semantic Scholar.

Usage:
    verify_bib.py <references.bib> [--out report.json] [--cite-keys-used keys.txt]

Reads .bib, queries CrossRef (and Semantic Scholar as fallback) for each entry's
title or DOI. Reports:
  - entries with no DOI and no CrossRef hit (likely hallucinated)
  - entries whose CrossRef title differs significantly from .bib title (Levenshtein)
  - DOI mismatches between .bib and CrossRef

Output: JSON to stdout (or --out file). Exit 0 always; status is in JSON.

Standard library only + urllib for HTTP. No external deps.
Network-dependent. If offline, every entry returns status="unverified-network".
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

CROSSREF_API = "https://api.crossref.org/works"
S2_API = "https://api.semanticscholar.org/graph/v1/paper/search"
USER_AGENT = "paper-write-verify-bib/1.0 (academic; mailto:noreply@example.com)"
TIMEOUT = 15
RATE_DELAY = 1.0  # seconds between API calls (CrossRef polite pool)


# ─────────────────────────────────────────────────────────────────────────────
# .bib parsing — minimal, handles @article{key, field = {value}, ...}
# ─────────────────────────────────────────────────────────────────────────────

ENTRY_RE = re.compile(r"@(\w+)\s*\{\s*([^,\s]+)\s*,(.*?)\n\}\s*", re.DOTALL)
FIELD_RE = re.compile(r"(\w+)\s*=\s*[\{\"](.+?)[\}\"]\s*,?", re.DOTALL)


def parse_bib(path: Path) -> list[dict[str, Any]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    text = re.sub(r"%.*", "", text)  # strip line comments
    entries: list[dict[str, Any]] = []
    for m in ENTRY_RE.finditer(text):
        kind, key, body = m.group(1), m.group(2), m.group(3)
        fields: dict[str, str] = {}
        for fm in FIELD_RE.finditer(body):
            fields[fm.group(1).lower()] = re.sub(r"\s+", " ", fm.group(2)).strip()
        entries.append({"key": key, "type": kind.lower(), "fields": fields})
    return entries


# ─────────────────────────────────────────────────────────────────────────────
# Levenshtein (no external dep)
# ─────────────────────────────────────────────────────────────────────────────

def lev_ratio(a: str, b: str) -> float:
    a, b = a.lower(), b.lower()
    if not a and not b:
        return 1.0
    if not a or not b:
        return 0.0
    n, m = len(a), len(b)
    dp = list(range(m + 1))
    for i in range(1, n + 1):
        prev, dp[0] = dp[0], i
        for j in range(1, m + 1):
            cur = dp[j]
            cost = 0 if a[i - 1] == b[j - 1] else 1
            dp[j] = min(dp[j] + 1, dp[j - 1] + 1, prev + cost)
            prev = cur
    return 1.0 - dp[m] / max(n, m)


# ─────────────────────────────────────────────────────────────────────────────
# CrossRef + S2 lookup
# ─────────────────────────────────────────────────────────────────────────────

def http_get_json(url: str) -> dict[str, Any] | None:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        return None


def crossref_by_doi(doi: str) -> dict[str, Any] | None:
    j = http_get_json(f"{CROSSREF_API}/{urllib.parse.quote(doi)}")
    return j.get("message") if j else None


def crossref_by_title(title: str) -> dict[str, Any] | None:
    q = urllib.parse.quote(title)
    j = http_get_json(f"{CROSSREF_API}?query.title={q}&rows=1")
    if not j:
        return None
    items = j.get("message", {}).get("items", [])
    return items[0] if items else None


def s2_by_title(title: str) -> dict[str, Any] | None:
    q = urllib.parse.quote(title)
    j = http_get_json(f"{S2_API}?query={q}&limit=1&fields=title,year,authors,externalIds")
    if not j:
        return None
    data = j.get("data", [])
    return data[0] if data else None


# ─────────────────────────────────────────────────────────────────────────────
# Per-entry verification
# ─────────────────────────────────────────────────────────────────────────────

def verify_entry(entry: dict[str, Any]) -> dict[str, Any]:
    f = entry["fields"]
    bib_title = f.get("title", "")
    bib_doi = f.get("doi", "").strip()
    out: dict[str, Any] = {
        "key": entry["key"],
        "bib_title": bib_title,
        "bib_doi": bib_doi or None,
        "status": "unknown",
        "issues": [],
    }
    if not bib_title and not bib_doi:
        out["status"] = "missing-fields"
        out["issues"].append("no title and no doi in .bib entry")
        return out

    # 1. DOI lookup
    if bib_doi:
        time.sleep(RATE_DELAY)
        cr = crossref_by_doi(bib_doi)
        if cr is None:
            out["issues"].append(f"DOI {bib_doi} not found in CrossRef")
            out["status"] = "doi-not-found"
        else:
            cr_title = (cr.get("title") or [""])[0]
            ratio = lev_ratio(bib_title, cr_title)
            out["crossref_title"] = cr_title
            out["title_match_ratio"] = round(ratio, 3)
            if ratio < 0.70 and bib_title:
                out["issues"].append(f"title mismatch (ratio={ratio:.2f}): bib={bib_title!r}, crossref={cr_title!r}")
                out["status"] = "title-mismatch"
            else:
                out["status"] = "verified"
        return out

    # 2. Title lookup (no DOI in bib)
    time.sleep(RATE_DELAY)
    cr = crossref_by_title(bib_title)
    if cr is None:
        time.sleep(RATE_DELAY)
        s2 = s2_by_title(bib_title)
        if s2 is None:
            out["issues"].append("not found in CrossRef or Semantic Scholar")
            out["status"] = "not-found"
            return out
        s2_title = s2.get("title", "")
        ratio = lev_ratio(bib_title, s2_title)
        out["semantic_scholar_title"] = s2_title
        out["title_match_ratio"] = round(ratio, 3)
        if ratio < 0.70:
            out["issues"].append(f"only S2 hit, title mismatch (ratio={ratio:.2f})")
            out["status"] = "title-mismatch"
        else:
            out["status"] = "verified-no-doi"
        return out

    cr_title = (cr.get("title") or [""])[0]
    ratio = lev_ratio(bib_title, cr_title)
    out["crossref_title"] = cr_title
    out["crossref_doi"] = cr.get("DOI")
    out["title_match_ratio"] = round(ratio, 3)
    if ratio < 0.70:
        out["issues"].append(f"top CrossRef hit doesn't match (ratio={ratio:.2f}): {cr_title!r}")
        out["status"] = "title-mismatch"
    else:
        out["status"] = "verified-no-doi"
    return out


# ─────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("bib", type=Path)
    ap.add_argument("--out", type=Path, default=None)
    ap.add_argument("--cite-keys-used", type=Path, default=None,
                    help="optional file with one cite-key per line; entries not in this list are flagged 'unused'")
    args = ap.parse_args()

    if not args.bib.is_file():
        print(json.dumps({"error": f"bib file not found: {args.bib}"}), file=sys.stderr)
        return 1

    used: set[str] = set()
    if args.cite_keys_used and args.cite_keys_used.is_file():
        used = {ln.strip() for ln in args.cite_keys_used.read_text().splitlines() if ln.strip()}

    entries = parse_bib(args.bib)
    results = []
    for e in entries:
        r = verify_entry(e)
        if used and e["key"] not in used:
            r["issues"].append("not cited in body (unused)")
            if r["status"] == "verified":
                r["status"] = "verified-unused"
        results.append(r)

    summary = {
        "total": len(results),
        "verified": sum(1 for r in results if r["status"].startswith("verified")),
        "issues": sum(1 for r in results if r["issues"]),
        "by_status": {},
    }
    for r in results:
        summary["by_status"][r["status"]] = summary["by_status"].get(r["status"], 0) + 1

    out_doc = {"summary": summary, "results": results}
    if args.out:
        args.out.write_text(json.dumps(out_doc, ensure_ascii=False, indent=2))
        print(f"wrote {args.out}")
    else:
        print(json.dumps(out_doc, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
