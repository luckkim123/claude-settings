"""Tests for scripts/docx_inspect.py."""
import json
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).parent.parent / "scripts" / "docx_inspect.py"
FIXTURES = Path(__file__).parent / "fixtures"


def _run(*args):
    result = subprocess.run(
        [sys.executable, str(SCRIPT), *map(str, args)],
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    return json.loads(result.stdout)


def test_plain_body_is_low_risk():
    out = _run(FIXTURES / "plain_body.docx")
    assert out["risk"] == "low"
    assert out["signals"]["has_header"] is False
    assert out["signals"]["has_footer"] is False


def test_header_with_many_user_styles_is_high_risk():
    out = _run(FIXTURES / "with_header_styles.docx")
    assert out["risk"] == "high"
    assert out["signals"]["has_header"] is True
    assert out["signals"]["user_style_count"] >= 10


def test_table_only_is_medium_risk():
    out = _run(FIXTURES / "with_table.docx")
    assert out["risk"] == "medium"
    assert out["signals"]["has_table"] is True
    assert out["signals"]["has_header"] is False


def test_compare_two_identical_files_reports_match():
    p = FIXTURES / "plain_body.docx"
    out = _run(p, "--compare", p)
    assert "compare" in out
    # Comparing a file with itself → all members must match
    for entry in out["compare"].values():
        if entry["a"] is not None:
            assert entry["match"] is True


def test_compare_two_different_files_reports_mismatch():
    a = FIXTURES / "plain_body.docx"
    b = FIXTURES / "with_header_styles.docx"
    out = _run(a, "--compare", b)
    # document.xml should differ (different bodies)
    assert out["compare"]["word/document.xml"]["match"] is False
