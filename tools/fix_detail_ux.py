#!/usr/bin/env python3
"""Fix detail page UX: column layout, full API fields, header from response."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APPROVAL = ROOT / "lib/FE/approval_screen"


def extract_item_field_meta(method_body: str) -> tuple[list[str], dict[str, str]]:
    keys: list[str] = []
    labels: dict[str, str] = {}
    for m in re.finditer(
        r"ApprovalInfoField\('([^']+)',\s*\(?(?:e|item)\['([^']+)'\]",
        method_body,
    ):
        label, key = m.group(1), m.group(2)
        if key not in keys:
            keys.append(key)
        labels[key] = label
    return keys, labels


def rewrite_item_detail_fields(text: str) -> str:
    pattern = re.compile(
        r"(\s*)List<ApprovalInfoField> _itemDetailFields\(dynamic e\) \{\s*"
        r"return \[[\s\S]*?\];\s*\}",
        re.MULTILINE,
    )

    def repl(match: re.Match[str]) -> str:
        indent = match.group(1)
        keys, labels = extract_item_field_meta(match.group(0))
        if not keys:
            return match.group(0)
        labels_literal = ",\n".join(
            f"{indent}      '{k}': '{v}'" for k, v in labels.items()
        )
        keys_literal = ", ".join(f"'{k}'" for k in keys)
        return (
            f"{indent}List<ApprovalInfoField> _itemDetailFields(dynamic e) {{\n"
            f"{indent}  return approvalFieldsFromRecord(\n"
            f"{indent}    e,\n"
            f"{indent}    priorityKeys: const [{keys_literal}],\n"
            f"{indent}    labels: const {{\n{labels_literal}\n{indent}    }},\n"
            f"{indent}  );\n"
            f"{indent}}}"
        )

    return pattern.sub(repl, text)


def fix_listview_to_column(text: str) -> str:
    text = text.replace(
        "return ListView(\n          children: [",
        "return ApprovalDetailItemsColumn(\n          count: dataaa.length,\n          children: [",
    )
    text = text.replace(
        "return ListView(\n          children: <Widget>[",
        "return ApprovalDetailItemsColumn(\n          count: dataaa.length,\n          children: <Widget>[",
    )
    # Remove duplicate ApprovalItemsHeader when wrapped
    text = re.sub(
        r"ApprovalDetailItemsColumn\(\s*count: dataaa\.length,\s*children: \[\s*ApprovalItemsHeader\(count: dataaa\.length[^)]*\),\s*",
        "ApprovalDetailItemsColumn(\n          count: dataaa.length,\n          children: [\n            ",
        text,
    )
    text = text.replace(
        "          ],\n        );\n      },\n    );\n  }",
        "          ],\n        );\n      },\n    );\n  }",
    )
    return text


def remove_body_container(text: str) -> str:
    return re.sub(
        r"body: Container\(\s*"
        r"color: ApprovalTheme\.background,\s*"
        r"padding: const EdgeInsets\.fromLTRB\(12, 10, 12, 0\),\s*"
        r"child: (_buildBody\(\)),\s*\),",
        r"body: \1,",
        text,
    )


def add_api_header_state(text: str) -> str:
    if "_apiHeader" in text:
        return text
    if "ApprovalInfoPanel" not in text:
        return text
    text = re.sub(
        r"(class _\w+State extends State<\w+> \{[^\n]*\n)",
        r"\1  Map<String, dynamic>? _apiHeader;\n",
        text,
        count=1,
    )
    return text


def inject_header_capture(text: str) -> str:
    if "_apiHeader" not in text:
        return text
    if "_apiHeader =" in text:
        return text

    patterns = [
        (
            r"(final caConfirmData = json\.decode\(getData\.body\);)",
            r"\1\n      final _data = caConfirmData['data'];\n"
            r"      if (_data is Map && _data['header'] is Map) {\n"
            r"        _apiHeader = Map<String, dynamic>.from(_data['header']);\n"
            r"      }",
        ),
        (
            r"(final responseData = json\.decode\(getData\.body\);)",
            r"\1\n      final _data = responseData['data'];\n"
            r"      if (_data is Map && _data['header'] is Map) {\n"
            r"        _apiHeader = Map<String, dynamic>.from(_data['header']);\n"
            r"      }",
        ),
    ]
    for pat, repl in patterns:
        if re.search(pat, text) and "_apiHeader = Map" not in text:
            text = re.sub(pat, repl, text, count=1)
            break
    return text


def add_extra_record_to_panel(text: str) -> str:
    if "extraRecord: _apiHeader" in text:
        return text
    if "_apiHeader" not in text:
        return text
    return re.sub(
        r"(ApprovalInfoPanel\([\s\S]*?reason: [^,\n]+),",
        r"\1,\n          extraRecord: _apiHeader,",
        text,
        count=1,
    )


def main() -> None:
    updated: list[str] = []
    for path in sorted(APPROVAL.rglob("*2.dart")):
        if "ApprovalDetailScaffold" not in path.read_text(encoding="utf-8"):
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        text = rewrite_item_detail_fields(text)
        text = fix_listview_to_column(text)
        text = remove_body_container(text)
        text = add_api_header_state(text)
        text = inject_header_capture(text)
        text = add_extra_record_to_panel(text)
        if text != original:
            path.write_text(text, encoding="utf-8")
            updated.append(path.relative_to(ROOT).as_posix())

    print(f"Updated {len(updated)} detail files")
    for f in updated:
        print(f"  {f}")


if __name__ == "__main__":
    main()
