#!/usr/bin/env python3
"""Detect OS and key tool availability for docx-toolkit.

Outputs a JSON object on stdout with:
  - os: "macos" | "windows" | "linux"
  - word_available: bool — Microsoft Word installed?
  - uvx_available: bool — `uvx` CLI on PATH?
  - pandoc_available: bool — `pandoc` CLI on PATH?
"""
import json
import platform
import shutil
import sys
from pathlib import Path

_OS_MAP = {"Darwin": "macos", "Windows": "windows", "Linux": "linux"}


def _word_available(os_name: str) -> bool:
    if os_name == "macos":
        return Path("/Applications/Microsoft Word.app").exists()
    if os_name == "windows":
        # WINWORD.EXE is the Word binary; might also be on PATH only sometimes
        if shutil.which("WINWORD") or shutil.which("WINWORD.EXE"):
            return True
        # common install paths
        for candidate in (
            r"C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE",
            r"C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE",
        ):
            if Path(candidate).exists():
                return True
        return False
    return False


def detect() -> dict:
    os_name = _OS_MAP.get(platform.system(), "linux")
    return {
        "os": os_name,
        "word_available": _word_available(os_name),
        "uvx_available": shutil.which("uvx") is not None,
        "pandoc_available": shutil.which("pandoc") is not None,
    }


if __name__ == "__main__":
    json.dump(detect(), sys.stdout)
