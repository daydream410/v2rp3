#!/usr/bin/env python3
"""Replace tap-to-detail tiles with inline expanded item cards."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPROVAL = ROOT / "lib/FE/approval_screen"


def find_matching_brace(text: str, open_idx: int) -> int:
    depth = 0
    i = open_idx
    while i < len(text):
        c = text[i]
        if c == "(" or c == "{" or c == "[":
            depth += 1
        elif c == ")" or c == "}" or c == "]":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def remove_on_tap_block(tile_args: str) -> tuple[str, str | None]:
    """Remove onTap callback; return (remaining_args, fields_expr)."""
    fields_expr = None
    while True:
        m = re.search(r"\bonTap:\s*\(\)\s*\{", tile_args)
        if not m:
            break
        start = m.start()
        brace_start = tile_args.index("{", m.start())
        brace_end = find_matching_brace(tile_args, brace_start)
        if brace_end == -1:
            break
        block = tile_args[brace_start : brace_end + 1]
        fm = re.search(
            r"showApprovalItemDetail\s*\([\s\S]*?fields:\s*([^,\)]+(?:\([^)]*\))?[^,\)]*),?",
            block,
        )
        if fm:
            fields_expr = fm.group(1).strip()
        tile_args = tile_args[:start] + tile_args[brace_end + 1 :]
        tile_args = re.sub(r",\s*,", ",", tile_args)
        tile_args = re.sub(r",\s*\)", ")", tile_args)

    tile_args = tile_args.strip().rstrip(",").strip()
    return tile_args, fields_expr


def migrate_compact(text: str) -> str:
    result = []
    i = 0
    while True:
        idx = text.find("ApprovalCompactItemTile(", i)
        if idx == -1:
            result.append(text[i:])
            break
        result.append(text[i:idx])
        paren_start = idx + len("ApprovalCompactItemTile(") - 1
        paren_end = find_matching_brace(text, paren_start)
        if paren_end == -1:
            result.append(text[idx:])
            break
        args = text[paren_start + 1 : paren_end]
        new_args, fields_expr = remove_on_tap_block(args)
        if fields_expr:
            if not re.search(r"\bfields:\s*", new_args):
                new_args = new_args.rstrip() + f",\n                fields: {fields_expr}"
        result.append("ApprovalExpandedItemCard(")
        result.append(new_args)
        result.append(")")
        i = paren_end + 1
    return "".join(result)


def migrate_selectable(text: str) -> str:
    result = []
    i = 0
    while True:
        idx = text.find("ApprovalSelectableItemTile(", i)
        if idx == -1:
            result.append(text[i:])
            break
        result.append(text[i:idx])
        paren_start = idx + len("ApprovalSelectableItemTile(") - 1
        paren_end = find_matching_brace(text, paren_start)
        if paren_end == -1:
            result.append(text[idx:])
            break
        args = text[paren_start + 1 : paren_end]
        new_args, fields_expr = remove_on_tap_block(args)
        if fields_expr and not re.search(r"\bfields:\s*", new_args):
            new_args = new_args.rstrip() + f",\n                fields: {fields_expr}"
        result.append("ApprovalSelectableExpandedItemCard(")
        result.append(new_args)
        result.append(")")
        i = paren_end + 1
    return "".join(result)


def migrate_file(path: Path) -> bool:
    text = path.read_text()
    orig = text
    text = migrate_selectable(text)
    text = migrate_compact(text)
    text = re.sub(
        r"hint:\s*'Tap[^']*'",
        "hint: ''",
        text,
    )
    if text != orig:
        path.write_text(text)
        print(f"OK: {path.relative_to(ROOT)}")
        return True
    return False


def main():
    files = sorted(APPROVAL.rglob("*2.dart"))
    n = sum(1 for f in files if migrate_file(f))
    print(f"Migrated {n} files")


if __name__ == "__main__":
    main()
