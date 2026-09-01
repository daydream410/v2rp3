#!/usr/bin/env python3
"""Regenerate _itemDetailFields from git DataTable source."""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def git_old(rel: str) -> str | None:
    try:
        return subprocess.check_output(
            ["git", "show", f"HEAD:{rel}"], cwd=ROOT, text=True
        )
    except subprocess.CalledProcessError:
        return None


def strip_text_style_arg(text_args: str) -> str:
    m = re.match(r"^(.+),\s*style:\s*const TextStyle", text_args, re.DOTALL)
    return m.group(1).strip() if m else text_args.strip()


def extract_datacell_exprs(cells_block: str) -> list[str]:
    exprs: list[str] = []
    i = 0
    while True:
        idx = cells_block.find("DataCell(Text(", i)
        if idx == -1:
            break
        start = idx + len("DataCell(Text(")
        depth = 1
        j = start
        while j < len(cells_block) and depth > 0:
            if cells_block[j] == "(":
                depth += 1
            elif cells_block[j] == ")":
                depth -= 1
            j += 1
        exprs.append(clean_expr(strip_text_style_arg(cells_block[start : j - 1])))
        i = j
    return exprs


def parse_column_labels(cols: str) -> list[str]:
    labels: list[str] = []
    idx = 0
    while idx < len(cols):
        col = cols.find("DataColumn", idx)
        if col == -1:
            break
        nxt = cols.find("DataColumn", col + 10)
        section = cols[col : nxt if nxt != -1 else len(cols)]
        texts = re.findall(r"Text\(\s*'([^']*)'", section)
        label = " ".join(t for t in texts if t).strip()
        labels.append(label or f"Field {len(labels) + 1}")
        idx = nxt if nxt != -1 else len(cols)
    return labels


def parse_item_table(old: str) -> tuple[list[str], list[str]] | None:
    m = re.search(
        r"columns:\s*const\s*\[([\s\S]*?)\],\s*rows:\s*dataaa\s*\.map\(\s*\(\s*\w+\s*\)\s*=>",
        old,
    )
    if not m:
        return None
    labels = parse_column_labels(m.group(1))
    rows_m = re.search(
        r"rows:\s*dataaa\s*\.map\([\s\S]*?cells:\s*\[([\s\S]*?)\]\)\)\s*\.toList\(\)",
        old,
    )
    if not rows_m:
        return None
    exprs = extract_datacell_exprs(rows_m.group(1))
    if not exprs:
        return None
    if len(labels) < len(exprs):
        labels += [f"Field {i + 1}" for i in range(len(labels), len(exprs))]
    return labels[: len(exprs)], exprs


def clean_expr(expr: str) -> str:
    expr = re.sub(r",?\s*//.*$", "", expr, flags=re.M)
    return re.sub(r"\s+", " ", expr.strip())


def cell_to_value(expr: str) -> str:
    e = clean_expr(expr)
    while "NumberFormat.currency" in e:
        m = re.search(
            r"NumberFormat\.currency\(\s*locale:\s*'eu',\s*symbol:\s*''\s*\)\s*\.format\((.+)\)",
            e,
        )
        if m:
            inner = m.group(1).strip()
            e = (
                e[: m.start()]
                + f"ApprovalTheme.currencyFmt.format({inner})"
                + e[m.end() :]
            )
            continue
        m = re.search(
            r"NumberFormat\.currency\(\s*locale:\s*'eu',\s*symbol:\s*'%'\s*\)\s*\.format\((.+)\)",
            e,
        )
        if m:
            inner = m.group(1).strip()
            e = (
                e[: m.start()]
                + f"'${{{inner}}}%'"
                + e[m.end() :]
            )
            continue
        break
    if "?" in e:
        return f"({e}).toString()"
    if ".toString()" in e:
        return f"({e})"
    if e.startswith("e[") or e.startswith("e['"):
        if "??" in e:
            return f"({e}).toString()"
        return f"{e}?.toString() ?? '-'"
    return f"({e}).toString()"


def build_fn(labels: list[str], exprs: list[str]) -> str:
    lines = ["  List<ApprovalInfoField> _itemDetailFields(dynamic e) {", "    return ["]
    for label, expr in zip(labels, exprs):
        safe = label.replace("'", "\\'")
        lines.append(f"      ApprovalInfoField('{safe}', {cell_to_value(expr)}),")
    lines += ["    ];", "  }", ""]
    return "\n".join(lines)


def regenerate(path: Path) -> bool:
    rel = str(path.relative_to(ROOT))
    old = git_old(rel)
    if not old:
        return False
    parsed = parse_item_table(old)
    if not parsed:
        return False
    labels, exprs = parsed
    text = path.read_text()
    m = re.search(
        r"  List<ApprovalInfoField> _itemDetailFields\(dynamic e\) \{[\s\S]*?  \}\n",
        text,
    )
    if not m:
        return False
    new_fn = build_fn(labels, exprs)
    path.write_text(text[: m.start()] + new_fn + text[m.end() :])
    print(f"OK: {rel}")
    return True


def main():
    files = sorted((ROOT / "lib/FE/approval_screen").rglob("*2.dart"))
    n = sum(1 for f in files if regenerate(f))
    print(f"Regenerated {n} files")


if __name__ == "__main__":
    main()
