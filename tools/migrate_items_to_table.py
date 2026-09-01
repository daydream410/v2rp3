#!/usr/bin/env python3
"""Migrate item card loops to tableRows."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPROVAL = ROOT / "lib/FE/approval_screen"


def paren_end(text: str, start: int) -> int:
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return i
    return -1


def migrate_file(path: Path) -> bool:
    text = path.read_text()
    orig = text

    # Single-item inline fields (asmb, wo)
    single = re.search(
        r"return ApprovalDetailItemsColumn\(\s*count: 1,\s*children: \[\s*"
        r"ApprovalExpandedItemCard\([\s\S]*?fields:\s*(\[[\s\S]*?\])\s*,?\s*\)\s*,\s*\]\s*,\s*\);",
        text,
    )
    if single and "dataaa.length" not in single.group(0):
        fields = single.group(1).strip()
        text = text[: single.start()] + (
            "return ApprovalDetailItemsColumn(\n"
            "      count: 1,\n"
            f"      tableRows: [{fields}],\n"
            "    );"
        ) + text[single.end() :]
        path.write_text(text)
        print(f"OK single: {path.name}")
        return True

    marker = "for (var i = 0; i < dataaa.length; i++)"
    if marker not in text:
        return False

    selectable = "ApprovalSelectableExpandedItemCard" in text

    # Find fields: ... line inside the for-loop tile
    fm = re.search(
        r"for \(var i = 0; i < dataaa\.length; i\+\+\)\s*\n\s*"
        r"(?:ApprovalExpandedItemCard|ApprovalSelectableExpandedItemCard)\([\s\S]*?"
        r"fields:\s*([^\n]+)",
        text,
    )
    if not fm:
        return False
    fields_call = fm.group(1).strip().rstrip(",")

    # Find children block start
    cm = re.search(
        r"return ApprovalDetailItemsColumn\(\s*\n\s*count: dataaa\.length,\s*\n\s*children: \[\s*\n",
        text,
    )
    if not cm:
        return False

    # Find end of for-loop tile: after fields line, closing ), 
    loop_start = text.find(marker, cm.end())
    tile_type = "ApprovalExpandedItemCard"
    if text.find("ApprovalSelectableExpandedItemCard", loop_start) == loop_start + len(marker) + 1:
        tile_type = "ApprovalSelectableExpandedItemCard"
    tile_open = text.find(tile_type + "(", loop_start)
    if tile_open == -1:
        return False
    tile_close = paren_end(text, tile_open + len(tile_type))
    if tile_close == -1:
        return False

    # Everything after tile until `],` closing children - may have footer widgets
    after_tile = text[tile_close + 1 :]
    footer_match = re.match(r"\s*,\s*\n(\s*)(\w)", after_tile)
    footer = ""
    children_close = ""
    if footer_match and footer_match.group(2)[0].isupper():
        # has footer like ApprovalSummarySection
        footer_start = tile_close + 1 + footer_match.start(1)
        # find closing `],` of children
        close_idx = text.find("\n          ],", footer_start)
        if close_idx != -1:
            footer = text[footer_start:close_idx].lstrip("\n")
            children_close = text[close_idx : close_idx + len("\n          ],")]

    insert = (
        "return ApprovalDetailItemsColumn(\n"
        "          count: dataaa.length,\n"
    )
    if selectable:
        insert += (
            "          selectable: true,\n"
            "          isRowSelected: (i) =>\n"
            "              selectedDetails.contains(dataaa[i]['urutan']),\n"
            "          onRowSelectionChanged: (i, v) {\n"
            "            setState(() {\n"
            "              final id = dataaa[i]['urutan'];\n"
            "              if (v == true) {\n"
            "                selectedDetails.add(id);\n"
            "                selectedGak = true;\n"
            "              } else {\n"
            "                selectedDetails.remove(id);\n"
            "                if (selectedDetails.isEmpty) {\n"
            "                  selectedGak = false;\n"
            "                  _selectionAction = '';\n"
            "                }\n"
            "              }\n"
            "            });\n"
            "          },\n"
        )
    insert += (
        "          tableRows: [\n"
        "            for (var i = 0; i < dataaa.length; i++)\n"
        f"              {fields_call},\n"
        "          ],\n"
    )
    if footer:
        insert += f"          children: [\n{footer}{children_close}\n"
    else:
        insert += "          children: const [],\n        );"

    if footer:
        # replace from return to children close
        close_idx = text.find("\n          ],", tile_close)
        end = close_idx + len("\n          ],")
        # find closing `);` of ApprovalDetailItemsColumn
        end = text.find(");", end) + 2
        text = text[: cm.start()] + insert + text[end:]
    else:
        close_idx = text.find("\n          ],", tile_close)
        end = text.find(");", close_idx) + 2
        text = text[: cm.start()] + insert + text[end:]

    if text != orig:
        path.write_text(text)
        print(f"OK: {path.name}")
        return True
    return False


def main():
    n = 0
    for f in sorted(APPROVAL.rglob("*2.dart")):
        if migrate_file(f):
            n += 1
    print(f"Done: {n}")


if __name__ == "__main__":
    main()
