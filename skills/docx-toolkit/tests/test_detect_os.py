"""Tests for scripts/detect_os.py."""
import json
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).parent.parent / "scripts" / "detect_os.py"


def _run():
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    return json.loads(result.stdout)


def test_detect_os_returns_known_os():
    data = _run()
    assert data["os"] in {"macos", "windows", "linux"}


def test_detect_os_reports_word_availability_as_bool():
    data = _run()
    assert isinstance(data["word_available"], bool)


def test_detect_os_reports_uvx_availability_as_bool():
    data = _run()
    assert isinstance(data["uvx_available"], bool)


def test_detect_os_reports_pandoc_availability_as_bool():
    data = _run()
    assert isinstance(data["pandoc_available"], bool)
