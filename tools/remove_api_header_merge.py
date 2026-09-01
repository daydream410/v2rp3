#!/usr/bin/env python3
"""Remove extraRecord merge and unused _apiHeader from approval detail pages."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPROVAL = ROOT / "lib/FE/approval_screen"


def clean_file(path: Path) -> bool:
    text = path.read_text()
    orig = text

    text = re.sub(r"\n\s*extraRecord: _apiHeader,", "", text)
    text = re.sub(r"  Map<String, dynamic>\? _apiHeader;\n", "", text)
    text = re.sub(
        r"\n\s*_apiHeader = Map<String, dynamic>\.from\(_data\['header'\]\);",
        "",
        text,
    )

    if text != orig:
        path.write_text(text)
        print(f"OK: {path.relative_to(ROOT)}")
        return True
    return False


def main():
    files = sorted(APPROVAL.rglob("*2.dart"))
    n = sum(1 for f in files if clean_file(f))
    print(f"Cleaned {n} files")


if __name__ == "__main__":
    main()
