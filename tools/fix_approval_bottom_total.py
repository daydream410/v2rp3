#!/usr/bin/env python3
"""Ensure getDataa() triggers rebuild so ApprovalDetailBottomBar totals update."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPROVAL = ROOT / "lib/FE/approval_screen"

REFRESH_LINE = "      if (mounted) setState(() {});"


def insert_refresh_before_return(text: str) -> tuple[str, bool]:
    """Insert setState refresh before `return dataaa` inside getDataa()."""
    changed = False
    out: list[str] = []
    in_get_dataa = False
    brace_depth = 0

    for line in text.splitlines(keepends=True):
        if re.match(r"\s*Future<dynamic>\s+getDataa\s*\(\)", line):
            in_get_dataa = True
            brace_depth = 0

        if in_get_dataa:
            brace_depth += line.count("{") - line.count("}")

        stripped = line.strip()
        if (
            in_get_dataa
            and brace_depth > 0
            and stripped == "return dataaa;"
            and REFRESH_LINE not in "".join(out[-5:])
        ):
            indent = line[: len(line) - len(line.lstrip())]
            out.append(f"{indent}{REFRESH_LINE.strip()}\n")
            changed = True

        out.append(line)

        if in_get_dataa and brace_depth <= 0 and stripped == "}":
            in_get_dataa = False

    return "".join(out), changed


def fix_poex(text: str) -> tuple[str, bool]:
    marker = "      // print(dTax);\n      return dataaa;"
    insert = """      var total = 0.0;
      for (var item in dataaa) {
        final amount = item['amount'];
        if (amount != null) total += (amount as num).toDouble();
      }
      totalPrice = total;
      // print(dTax);
      if (mounted) setState(() {});
      return dataaa;"""
    if marker in text and "totalPrice = total" not in text:
        return text.replace(marker, insert), True
    return text, False


def fix_poscm_unapproved(text: str) -> tuple[str, bool]:
    changed = False
    if "totalPrice: totalPrice, itemCount: dataaa.length," in text:
        text = text.replace(
            "totalPrice: totalPrice, itemCount: dataaa.length,",
            "totalPrice: gTTL, itemCount: dataaa.length,",
            1,
        )
        changed = True
    return text, changed


def fix_mu_app(text: str) -> tuple[str, bool]:
    if "      // return dataaa;\n" in text:
        return text.replace("      // return dataaa;\n", f"      {REFRESH_LINE.strip()}\n      return dataaa;\n"), True
    return text, False


def main() -> None:
    updated: list[str] = []

    for path in sorted(APPROVAL.rglob("*2.dart")):
        text = path.read_text(encoding="utf-8")
        if "ApprovalDetailBottomBar" not in text or "getDataa" not in text:
            continue

        original = text
        rel = path.relative_to(ROOT).as_posix()

        text, _ = insert_refresh_before_return(text)

        if rel.endswith("po_ex_approval/poex_app2.dart"):
            text, _ = fix_poex(text)
        if rel.endswith("poscm_unapproved/poscm_unapproved2.dart"):
            text, _ = fix_poscm_unapproved(text)
        if rel.endswith("mu_approval/mu_app2.dart"):
            text, _ = fix_mu_app(text)

        if text != original:
            path.write_text(text, encoding="utf-8")
            updated.append(rel)

    print(f"Updated {len(updated)} files:")
    for f in updated:
        print(f"  {f}")


if __name__ == "__main__":
    main()
