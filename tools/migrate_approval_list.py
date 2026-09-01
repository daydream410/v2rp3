#!/usr/bin/env python3
"""Migrate approval list pages to shared ApprovalListScaffold UI."""
import re
from pathlib import Path

from typing import Optional

ROOT = Path(__file__).resolve().parents[1]
APPROVAL = ROOT / "lib/FE/approval_screen"

LIST_GLOB = ["*_app.dart", "*_confirm.dart", "*unapproved.dart", "*refund.dart", "we_completed.dart"]


def find_list_files():
    files = []
    for pattern in LIST_GLOB:
        files.extend(APPROVAL.rglob(pattern))
    # skip detail pages
    return sorted(
        f for f in files
        if not f.name.endswith("2.dart") and f.name != "approval_screen.dart"
    )


def extract(content: str, path: Path) -> Optional[dict]:
    title_m = re.search(r'middle: const Text\("([^"]+)"\)', content)
    if not title_m:
        title_m = re.search(r'title: const Text\("([^"]+)"\)', content)
    if not title_m:
        print(f"  SKIP {path.name}: no title")
        return None

    ctrl_m = re.search(r"textControllers\.(\w+)\.value", content)
    if not ctrl_m:
        print(f"  SKIP {path.name}: no controller")
        return None

    filter_m = re.search(
        r"\.where\(\(dataaa\) => dataaa\['header'\]\['(\w+)'\]", content
    )
    if not filter_m:
        filter_m = re.search(
            r"\.where\(\(item\) => item\['header'\]\['(\w+)'\]", content
        )
    filter_key = filter_m.group(1) if filter_m else "sppbjno"

    nav_m = re.search(r"(Get\.to\(\(\) => \w+2\([\s\S]*?\)\);)", content)
    if not nav_m:
        print(f"  SKIP {path.name}: no navigation")
        return None
    nav_block = nav_m.group(1)
    nav_block = nav_block.replace("_foundUsers[index]", "item")
    nav_block = nav_block.replace("_foundUsers[index]", "item")

    # Extract getDataa and getDataa2 bodies
    get_dataa = ""
    m = re.search(r"Future<void> getDataa\(\) async \{([\s\S]*?)\n  \}", content)
    if m:
        get_dataa = m.group(1)
    else:
        m = re.search(r"Future<dynamic> getDataa\(\) async \{([\s\S]*?)\n  \}", content)
        if m:
            get_dataa = m.group(1)

    get_dataa2 = ""
    m2 = re.search(r"Future<void> getDataa2\(\) async \{([\s\S]*?)\n  \}", content)
    if m2:
        get_dataa2 = m2.group(2 - 1)  # noqa - use group 1
        get_dataa2 = m2.group(1)

    class_m = re.search(r"class (\w+) extends StatefulWidget", content)
    state_m = re.search(r"class (_\w+State) extends State", content)

    # imports from original (detail import)
    detail_import_m = re.search(
        r"import 'package:v2rp3/FE/approval_screen/[^']+';", content
    )
    detail_import = detail_import_m.group(0) if detail_import_m else ""

    rel_detail = ""
    dm = re.search(r"import '([^']+_app2\.dart)';", content) or re.search(
        r"import '([^']+_confirm2\.dart)';", content
    ) or re.search(r"import '([^']+unapproved2\.dart)';", content) or re.search(
        r"import '([^']+refund2\.dart)';", content
    ) or re.search(r"import '([^']+completed2\.dart)';", content)
    if dm:
        rel_detail = dm.group(1)
    elif detail_import:
        rel_detail = detail_import

    # extra imports (api_name etc)
    extra_imports = []
    for line in content.splitlines():
        if line.startswith("import ") and "approval_ui" not in line:
            if "api_name" in line or "routes/" in line:
                extra_imports.append(line)

    has_api_name = any("api_name" in i for i in extra_imports)

    return {
        "path": path,
        "title": title_m.group(1),
        "controller": ctrl_m.group(1),
        "filter_key": filter_key,
        "nav_block": nav_block,
        "get_dataa": get_dataa,
        "get_dataa2": get_dataa2,
        "class_name": class_m.group(1) if class_m else "Unknown",
        "state_name": state_m.group(1) if state_m else "_UnknownState",
        "rel_detail": rel_detail,
        "extra_imports": extra_imports,
        "has_api_name": has_api_name,
    }


def generate(meta: dict) -> str:
    p = meta["path"]
    rel = p.relative_to(ROOT / "lib")
    depth = len(rel.parts) - 1
    be_prefix = "../" * (depth - 2) if depth > 2 else "../../"
    if "cash_bank" in str(p):
        be_import = f"import '{be_prefix}../../BE/controller.dart';\nimport '{be_prefix}../../BE/reqip.dart';\nimport '{be_prefix}../../BE/resD.dart';\nimport '{be_prefix}../../main.dart';"
    else:
        be_import = f"import '{be_prefix}../../../BE/controller.dart';\nimport '{be_prefix}../../../BE/reqip.dart';\nimport '{be_prefix}../../../BE/resD.dart';\nimport '{be_prefix}../../../main.dart';"

    navbar = f"import '{be_prefix}../navbar/navbar.dart';"
    if "cash_bank" in str(p):
        navbar = f"import '{be_prefix}../../navbar/navbar.dart';"

    detail_imp = meta["rel_detail"]
    if detail_imp and not detail_imp.startswith("import"):
        detail_imp = f"import '{detail_imp}';"

    extra = "\n".join(meta["extra_imports"])

    fk = meta["filter_key"]
    refresh = "getDataa2" if meta["get_dataa2"].strip() else "getDataa"

    get_dataa_method = f"""
  Future<void> getDataa() async {{{meta['get_dataa']}
  }}"""

    get_dataa2_method = ""
    if meta["get_dataa2"].strip() and meta["get_dataa2"].strip() != meta["get_dataa"].strip():
        get_dataa2_method = f"""
  Future<void> getDataa2() async {{{meta['get_dataa2']}
  }}"""
    else:
        get_dataa2_method = "\n  Future<void> getDataa2() async => getDataa();"

    return f"""import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:http/http.dart' as http';
{extra}
{be_import}
{navbar}
{detail_imp}

class {meta['class_name']} extends StatefulWidget {{
  {meta['class_name']}({{Key? key}}) : super(key: key);

  @override
  State<{meta['class_name']}> createState() => {meta['state_name']}();
}}

class {meta['state_name']} extends State<{meta['class_name']}> {{
  static TextControllers textControllers = Get.put(TextControllers());
  static late List dataaa = <CaConfirmData>[];
  static late List _foundUsers = <CaConfirmData>[];
  late Future dataFuture;

  @override
  void initState() {{
    super.initState();
    dataFuture = getDataa();
  }}

  void _runFilter(String enteredKeyword) {{
    List results = [];
    if (enteredKeyword.isEmpty) {{
      results = dataaa;
    }} else {{
      results = dataaa
          .where((item) => item['header']['{fk}']
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }}
    setState(() => _foundUsers = results);
  }}

  void _openDetail(dynamic item) {{
    {meta['nav_block'].replace('Get.to', 'Get.to').replace('_foundUsers[index]', 'item')}
  }}

  Widget _buildList() {{
    return FutureBuilder(
      future: dataFuture,
      builder: (context, snapshot) {{
        if (snapshot.hasError) {{
          return const Center(child: Text('Error Loading Data'));
        }}
        if (snapshot.connectionState == ConnectionState.waiting) {{
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: ApprovalTheme.primary),
            ),
          );
        }}
        if (_foundUsers.isEmpty) {{
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No documents found',
                  style: TextStyle(color: Colors.grey.shade500)),
            ),
          );
        }}
        return Column(
          children: _foundUsers.map<Widget>((item) {{
            final header = item['header'];
            return ApprovalListCard(
              title: header['{fk}']?.toString() ?? '-',
              subtitle:
                  "${{header['requestorname'] ?? ''}} · ${{DateFormat('dd MMM yyyy').format(DateTime.parse(header['tanggal']))}}",
              onTap: () => _openDetail(item),
            );
          }}).toList(),
        );
      }},
    );
  }}

  @override
  Widget build(BuildContext context) {{
    return WillPopScope(
      onWillPop: () async {{
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are You sure?'),
            content: const Text('Do you want to exit V2RP Mobile?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (shouldPop == true) SystemNavigator.pop();
        return false;
      }},
      child: ApprovalListScaffold(
        title: '{meta['title']}',
        onBack: () => Get.to(const Navbar()),
        searchController: textControllers.{meta['controller']}.value,
        onSearchChanged: _runFilter,
        onRefresh: {refresh},
        child: _buildList(),
      ),
    );
  }}
{get_dataa_method}{get_dataa2_method}
}}
"""


def main():
    updated = []
    skipped = []
    for path in find_list_files():
        if path.name in ("sppbj_confirm.dart", "we_completed.dart", "itstock_app.dart"):
            continue
        content = path.read_text()
        if "ApprovalListScaffold" in content:
            skipped.append(path.name)
            continue
        meta = extract(content, path)
        if not meta:
            skipped.append(path.name)
            continue
        try:
            new_content = generate(meta)
            path.write_text(new_content)
            updated.append(str(path.relative_to(ROOT)))
            print(f"  OK {path.name}")
        except Exception as e:
            print(f"  FAIL {path.name}: {e}")
            skipped.append(path.name)

    print(f"\nUpdated: {len(updated)}, Skipped: {len(skipped)}")
    for u in updated:
        print(f"  + {u}")


if __name__ == "__main__":
    main()
