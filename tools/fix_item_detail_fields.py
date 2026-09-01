#!/usr/bin/env python3
"""Fix _itemDetailFields labels and currency formatting after tile migration."""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def git_old_content(rel: str) -> str | None:
    try:
        return subprocess.check_output(
            ["git", "show", f"HEAD:{rel}"], cwd=ROOT, text=True
        )
    except subprocess.CalledProcessError:
        return None


def parse_column_labels_from_table(table: str) -> list[str]:
    m = re.search(r"columns:\s*const\s*\[", table)
    if not m:
        return []
    start = m.end()
    end = table.find("],", start)
    if end == -1:
        return []
    cols = table[start:end]
    labels: list[str] = []
    idx = 0
    while idx < len(cols):
        col = cols.find("DataColumn", idx)
        if col == -1:
            break
        next_col = cols.find("DataColumn", col + 10)
        section = cols[col : next_col if next_col != -1 else len(cols)]
        texts = re.findall(r"Text\(\s*'([^']*)'", section)
        label = " ".join(t for t in texts if t).strip()
        labels.append(label or f"Field {len(labels) + 1}")
        idx = next_col if next_col != -1 else len(cols)
    return labels


def labels_for_file(path: Path) -> list[str] | None:
    rel = str(path.relative_to(ROOT))
    old = git_old_content(rel)
    if not old:
        return None
    m = re.search(r"DataTable2\([\s\S]*?rows:\s*dataaa", old)
    if not m:
        return None
    # grab first datatable block roughly
    dt = old[m.start() : old.find(");", m.start()) + 2]
    labels = parse_column_labels_from_table(dt)
    return labels or None


def fix_currency(text: str) -> str:
    text = re.sub(
        r"NumberFormat\.currency\(\s*locale:\s*'eu',\s*symbol:\s*''\s*\)\.format\(([^)]+(?:\([^)]*\))*?)\)",
        r"ApprovalTheme.currencyFmt.format(\1)",
        text,
    )
    text = re.sub(
        r"\(NumberFormat\.currency\([^)]+\)\.format\(([^)]+)\)\)\.toString\(\)",
        r"ApprovalTheme.currencyFmt.format(\1)",
        text,
    )
    return text


def fix_labels_in_detail_fn(text: str, labels: list[str]) -> str:
    m = re.search(
        r"(  List<ApprovalInfoField> _itemDetailFields\(dynamic e\) \{\n    return \[)([\s\S]*?)(    \];\n  \})",
        text,
    )
    if not m:
        return text
    body = m.group(2)
    fields = re.findall(
        r"ApprovalInfoField\('([^']*)',\s*([^)]+(?:\([^)]*\))*?)\),",
        body,
    )
    if not fields:
        return text
    lines = [m.group(1)]
    for i, (_, val) in enumerate(fields):
        label = labels[i] if i < len(labels) else f"Field {i + 1}"
        safe = label.replace("'", "\\'")
        lines.append(f"      ApprovalInfoField('{safe}', {val.strip()}),")
    lines.append(m.group(3))
    return text[: m.start()] + "\n".join(lines) + text[m.end() :]


def fix_file(path: Path) -> bool:
    text = path.read_text()
    if "_itemDetailFields" not in text:
        return False
    labels = labels_for_file(path)
    new = fix_currency(text)
    if labels:
        new = fix_labels_in_detail_fn(new, labels)
    if new != text:
        path.write_text(new)
        print(f"OK: {path.relative_to(ROOT)}")
        return True
    return False


def main():
    files = sorted((ROOT / "lib/FE/approval_screen").rglob("*2.dart"))
    n = sum(1 for f in files if fix_file(f))
    print(f"Fixed {n} files")


if __name__ == "__main__":
    main()
