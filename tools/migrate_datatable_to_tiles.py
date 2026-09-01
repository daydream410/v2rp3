#!/usr/bin/env python3
"""Convert DataTable2 in approval detail pages to compact item tiles."""
from __future__ import annotations

import re
from pathlib import Path
from typing import List, Optional, Tuple

ROOT = Path(__file__).resolve().parents[1]
APPROVAL = ROOT / "lib/FE/approval_screen"


def find_matching_paren(content: str, open_idx: int) -> int:
    depth = 0
    i = open_idx
    in_str: Optional[str] = None
    escape = False
    while i < len(content):
        c = content[i]
        if in_str:
            if escape:
                escape = False
            elif c == "\\":
                escape = True
            elif c == in_str:
                in_str = None
        elif c in ("'", '"'):
            in_str = c
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def find_matching_brace(content: str, open_idx: int) -> int:
    depth = 0
    i = open_idx
    in_str: Optional[str] = None
    escape = False
    while i < len(content):
        c = content[i]
        if in_str:
            if escape:
                escape = False
            elif c == "\\":
                escape = True
            elif c == in_str:
                in_str = None
        elif c in ("'", '"'):
            in_str = c
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def extract_datatables(content: str) -> List[str]:
    tables: List[str] = []
    idx = 0
    while True:
        pos = content.find("DataTable2(", idx)
        if pos == -1:
            break
        paren = content.find("(", pos)
        end = find_matching_paren(content, paren)
        if end == -1:
            break
        tables.append(content[pos : end + 1])
        idx = end + 1
    return tables


def parse_column_labels(table: str) -> List[str]:
    m = re.search(r"columns:\s*const\s*\[", table)
    if not m:
        return []
    start = m.end()
    end = table.find("],", start)
    if end == -1:
        return []
    cols = table[start:end]
    labels: List[str] = []
    for part in re.split(r"DataColumn2?\(", cols)[1:]:
        texts = re.findall(r"Text\(\s*'([^']*)'", part)
        if not texts:
            texts = re.findall(r'Text\(\s*"([^"]*)"', part)
        label = " ".join(t for t in texts if t).strip()
        labels.append(label or f"Field {len(labels) + 1}")
    return labels


def strip_text_style_arg(text_args: str) -> str:
    m = re.match(r"^(.+),\s*style:\s*const TextStyle", text_args, re.DOTALL)
    if m:
        return m.group(1).strip()
    return text_args.strip()


def extract_datacell_exprs(cells_block: str) -> List[str]:
    exprs: List[str] = []
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
        full = cells_block[start : j - 1].strip()
        exprs.append(strip_text_style_arg(full))
        i = j
    return exprs


def parse_item_table(table: str) -> Optional[Tuple[str, List[str], List[str], bool, str]]:
    m = re.search(
        r"rows:\s*dataaa\s*\.map\(\s*\(\s*(\w+)\s*\)\s*=>", table, re.DOTALL
    )
    if not m:
        return None
    row_var = m.group(1)
    selectable = "onSelectChanged" in table
    cells_m = re.search(r"cells:\s*\[", table[m.start() :])
    if not cells_m:
        return None
    cells_start = m.start() + cells_m.end()
    cells_end = table.find("]))", cells_start)
    if cells_end == -1:
        cells_end = table.find("])", cells_start)
    if cells_end == -1:
        return None
    cells_block = table[cells_start:cells_end]
    labels = parse_column_labels(table)
    exprs = extract_datacell_exprs(cells_block)
    if not exprs:
        return None
    if len(labels) < len(exprs):
        labels += [f"Field {i + 1}" for i in range(len(labels), len(exprs))]
    elif len(labels) > len(exprs):
        labels = labels[: len(exprs)]
    key = "urutan"
    km = re.search(r'selectedDetails\.contains\(\w+\["(\w+)"\]\)', table)
    if km:
        key = km.group(1)
    return row_var, labels, exprs, selectable, key


def parse_summary_table(table: str) -> Optional[Tuple[List[str], List[str]]]:
    if "dataaa.map" in table:
        return None
    m = re.search(r"rows:\s*\[\s*DataRow", table)
    if not m:
        return None
    labels = parse_column_labels(table)
    cells_m = re.search(r"cells:\s*\[", table[m.start() :])
    if not cells_m:
        return None
    cells_start = m.start() + cells_m.end()
    cells_end = table.find("])", cells_start)
    if cells_end == -1:
        return None
    exprs = extract_datacell_exprs(table[cells_start:cells_end])
    if not exprs:
        return None
    if len(labels) < len(exprs):
        labels += [f"Field {i + 1}" for i in range(len(labels), len(exprs))]
    elif len(labels) > len(exprs):
        labels = labels[: len(exprs)]
    return labels, exprs


def cell_to_value(expr: str) -> str:
    e = re.sub(r"\s+", " ", expr.strip())
    while "NumberFormat.currency" in e:
        m = re.match(
            r"NumberFormat\.currency\(\s*locale:\s*'eu',\s*symbol:\s*''\s*\)\.format\((.+)\)$",
            e,
        )
        if m:
            inner = m.group(1).strip()
            return f"ApprovalTheme.currencyFmt.format({inner})"
        m = re.match(
            r"NumberFormat\.currency\(\s*locale:\s*'eu',\s*symbol:\s*'%'\s*\)\.format\((.+)\)$",
            e,
        )
        if m:
            inner = m.group(1).strip()
            return f"'${{{inner}}}%'"
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


def pick_title(labels: List[str], exprs: List[str]) -> str:
    for l, ex in zip(labels, exprs):
        if "itemname" in ex or l == "Item Name":
            return ex
    for l, ex in zip(labels, exprs):
        if "itemcoa" in ex or "Account" in l or l == "Item ID":
            return ex
    for l, ex in zip(labels, exprs):
        if "ket" in ex or "Desc" in l or "Remarks" in l:
            return ex
    return exprs[0]


def pick_amount(exprs: List[str], labels: List[str]) -> Optional[str]:
    for ex, l in zip(exprs, labels):
        low = (ex + l).lower()
        if "amount" in low and "taxamount" not in low.replace("tax", ""):
            return cell_to_value(ex)
    for ex in exprs:
        if "['amount']" in ex or '["amount"]' in ex:
            return cell_to_value(ex)
    for ex, l in zip(exprs, labels):
        if "total" in l.lower() and "NumberFormat" in ex:
            return cell_to_value(ex)
    return None


def pick_subtitle(exprs: List[str], labels: List[str]) -> str:
    for ex in exprs:
        if "['ket']" in ex or '["ket"]' in ex:
            return "dataaa[i]['ket']?.toString() ?? ''"
    for ex, l in zip(exprs, labels):
        if "harga" in ex or "price" in l.lower():
            if any("qty" in x for x in exprs):
                return "'${ApprovalTheme.formatQty(dataaa[i])} · ${ApprovalTheme.currencyFmt.format(dataaa[i]['harga'] ?? 0)}'"
    for ex in exprs:
        if re.search(r"\['qty'\]|\[\"qty\"\]", ex) and "qtymu" not in ex and "qtyit" not in ex:
            return "ApprovalTheme.formatQty(dataaa[i])"
    if len(exprs) > 1:
        ex = exprs[1]
        if ex.startswith("e["):
            field = ex.split("[")[1].split("]")[0].strip("'\"")
            return f"dataaa[i]['{field}']?.toString() ?? ''"
    return "''"


def pick_amount_expr(exprs: List[str], labels: List[str]) -> str:
    picked = pick_amount(exprs, labels)
    if not picked:
        return "''"
    # Convert e[...] expressions to dataaa[i][...]
    return re.sub(r"\be\[", "dataaa[i][", picked)


def build_detail_fields_fn(labels: List[str], exprs: List[str]) -> str:
    lines = ["  List<ApprovalInfoField> _itemDetailFields(dynamic e) {", "    return ["]
    for label, expr in zip(labels, exprs):
        safe_label = label.replace("'", "\\'") or f"Field"
        val = cell_to_value(expr)
        lines.append(f"      ApprovalInfoField('{safe_label}', {val}),")
    lines += ["    ];", "  }", ""]
    return "\n".join(lines)


def build_summary_widget(title: str, labels: List[str], exprs: List[str]) -> str:
    fields = []
    for label, expr in zip(labels, exprs):
        safe_label = label.replace("'", "\\'") or "Value"
        val = cell_to_value(expr)
        fields.append(f"ApprovalInfoField('{safe_label}', {val}),")
    fields_str = "\n                ".join(fields)
    return f"""ApprovalSummarySection(
              title: '{title}',
              fields: [
                {fields_str}
              ],
            )"""


def build_item_list_body(
    selectable: bool,
    selection_key: str,
    title_expr: str,
    subtitle_expr: str,
    amount_expr: str,
) -> str:
    title_dart = re.sub(r"\be\[", "dataaa[i][", title_expr)
    if "?" in title_dart:
        title_dart = f"({title_dart}).toString()"
    elif title_dart.startswith("dataaa[i]["):
        title_dart = f"{title_dart}?.toString() ?? '-'"
    else:
        title_dart = f"({title_dart}).toString()"
    hint = "Select items or tap for detail" if selectable else "Tap item for detail"
    tile = "ApprovalSelectableItemTile" if selectable else "ApprovalCompactItemTile"

    selection_block = ""
    if selectable:
        selection_block = f"""
                selected: selectedDetails.contains(dataaa[i]['{selection_key}']),
                onSelected: (v) {{
                  setState(() {{
                    final id = dataaa[i]['{selection_key}'];
                    if (v == true) {{
                      selectedDetails.add(id);
                      selectedGak = true;
                    }} else {{
                      selectedDetails.remove(id);
                      if (selectedDetails.isEmpty) {{
                        selectedGak = false;
                        _selectionAction = '';
                      }}
                    }}
                  }});
                }},"""

    return f"""  Widget _buildBody() {{
    return FutureBuilder(
      future: dataFuture,
      builder: (context, snapshot) {{
        if (snapshot.hasError) {{
          return Center(child: Text('Error Loading Data', style: TextStyle(color: Colors.grey.shade500)));
        }}
        if (snapshot.connectionState == ConnectionState.waiting) {{
          return Center(child: CircularProgressIndicator(color: ApprovalTheme.primary));
        }}
        return ListView(
          children: [
            ApprovalItemsHeader(count: dataaa.length, hint: '{hint}'),
            for (var i = 0; i < dataaa.length; i++)
              {tile}(
                index: i + 1,{selection_block}
                title: {title_dart},
                subtitle: {subtitle_expr},
                amount: {amount_expr},
                onTap: () {{
                  final e = dataaa[i];
                  showApprovalItemDetail(
                    context: context,
                    index: i + 1,
                    title: {title_dart},
                    fields: _itemDetailFields(e),
                  );
                }},
              ),
          ],
        );
      }},
    );
  }}"""


def find_build_body_span(content: str) -> Optional[Tuple[int, int]]:
    m = re.search(r"\n  Widget _buildBody\(\) \{", content)
    if not m:
        return None
    brace = content.find("{", m.end() - 1)
    end = find_matching_brace(content, brace)
    if end == -1:
        return None
    return m.start(), end + 1


def migrate_file(path: Path) -> bool:
    content = path.read_text()
    if "DataTable2(" not in content:
        return False
    if "ApprovalCompactItemTile" in content and "DataTable2(" not in content:
        return False

    tables = extract_datatables(content)
    item_table = None
    summaries: List[Tuple[List[str], List[str]]] = []
    for t in tables:
        parsed = parse_item_table(t)
        if parsed:
            item_table = parsed
        else:
            sm = parse_summary_table(t)
            if sm:
                summaries.append(sm)

    if not item_table:
        print(f"SKIP no item table: {path.name}")
        return False

    row_var, labels, exprs, selectable, sel_key = item_table
    title_expr = pick_title(labels, exprs)
    amount_expr = pick_amount_expr(exprs, labels)
    subtitle_expr = pick_subtitle(exprs, labels)

    span = find_build_body_span(content)
    if not span:
        print(f"FAIL no _buildBody: {path.name}")
        return False

    detail_fn = build_detail_fields_fn(labels, exprs)
    body = build_item_list_body(selectable, sel_key, title_expr, subtitle_expr, amount_expr)

    # Insert detail fields before _buildBody
    insert_at = span[0]
    new_content = content[:insert_at] + "\n" + detail_fn + body + content[span[1] :]

    # Add summary widgets at end of ListView children if needed
    if summaries:
        summary_widgets = []
        for i, (sl, se) in enumerate(summaries):
            title = "Sub-Total" if i == 0 else "Summary"
            summary_widgets.append(build_summary_widget(title, sl, se))
        summary_code = ",\n            ".join(summary_widgets)
        new_content = new_content.replace(
            "          ],\n        );\n      },\n    );\n  }}",
            "          " + summary_code + ",\n          ],\n        );\n      },\n    );\n  }}",
            1,
        )

    path.write_text(new_content)
    print(f"OK: {path.relative_to(ROOT)}")
    return True


def main():
    files = sorted(APPROVAL.rglob("*2.dart"))
    ok = 0
    for f in files:
        if migrate_file(f):
            ok += 1
    print(f"Migrated {ok} files")


if __name__ == "__main__":
    main()
