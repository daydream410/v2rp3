#!/usr/bin/env python3
"""Fix syntax errors from migrate_inline_item_cards.py."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPROVAL = ROOT / "lib/FE/approval_screen"

INLINE_FIELDS = {
    "asmb_app2.dart": """[
                ApprovalInfoField('Item', widget.item?.toString() ?? '-'),
                ApprovalInfoField('Supplier', widget.supplier?.toString() ?? '-'),
                ApprovalInfoField('Location', widget.location?.toString() ?? '-'),
                ApprovalInfoField('Est. Date', _formattedEstDate),
                ApprovalInfoField('Request By', widget.requestor?.toString() ?? '-'),
              ]""",
    "wo_app2.dart": """[
                ApprovalInfoField('WO No', widget.reffno?.toString() ?? '-'),
                ApprovalInfoField('Due Date', _formattedDueDate),
                ApprovalInfoField('Amount',
                    ApprovalTheme.currencyFmt.format(totalPrice)),
                ApprovalInfoField('Project', widget.projectid?.toString() ?? '-'),
                ApprovalInfoField('Location', widget.locationname?.toString() ?? '-'),
                ApprovalInfoField('WIP Account', widget.wipacc?.toString() ?? '-'),
                ApprovalInfoField(
                    'WIP Account Name', widget.wipaccName?.toString() ?? '-'),
                ApprovalInfoField('Request By', widget.username?.toString() ?? '-'),
              ]""",
}


def fix_file(path: Path) -> bool:
    text = path.read_text()
    orig = text

    text = text.replace("_itemDetailFields(e)", "_itemDetailFields(dataaa[i])")

    # Close expanded card before children list ends
    text = re.sub(
        r"(fields: [^\n]+,\n)(          \],)",
        r"\1              ),\n\2",
        text,
    )
    text = re.sub(
        r"(fields: approvalSppbjItemFields\(dataaa\[i\]\),\n)(          \],)",
        r"\1              ),\n\2",
        text,
    )
    text = re.sub(
        r"(fields: _itemDetailFields\(dataaa\[i\]\),\n)(          \],)",
        r"\1              ),\n\2",
        text,
    )

    name = path.name
    if name in INLINE_FIELDS:
        text = re.sub(
            r"fields: \[\s*ApprovalInfoField\('[^']+'\),?\s*\],\s*\n\s*\);",
            f"fields: {INLINE_FIELDS[name]},\n        ),\n      ],\n    );",
            text,
            count=1,
        )

    if text != orig:
        path.write_text(text)
        print(f"OK: {path.relative_to(ROOT)}")
        return True
    return False


def main():
    files = sorted(APPROVAL.rglob("*2.dart"))
    n = sum(1 for f in files if fix_file(f))
    print(f"Fixed {n} files")


if __name__ == "__main__":
    main()
