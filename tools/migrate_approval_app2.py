#!/usr/bin/env python3
"""Migrate approval detail pages to shared approval UI."""
import re
from pathlib import Path
from typing import Optional, List, Tuple

ROOT = Path(__file__).resolve().parents[1]

ACTION_META = {
    "Pending": ("Icons.hourglass_empty_rounded", "0xFF9E9E9E"),
    "Approve": ("Icons.check_circle_outline_rounded", "0xFFF4A62A"),
    "Confirm": ("Icons.check_circle_outline_rounded", "0xFFF4A62A"),
    "Reject": ("Icons.cancel_outlined", "0xFFE53935"),
    "Send To Draft": ("Icons.edit_note_outlined", "0xFFFF9800"),
    "Update": ("Icons.update_rounded", "0xFFF4A62A"),
    "Deliver": ("Icons.local_shipping_outlined", "0xFFF4A62A"),
    "Received": ("Icons.inventory_2_outlined", "0xFF43A047"),
    "Ready To Approval": ("Icons.fact_check_outlined", "0xFFF4A62A"),
    "Approved & Updated": ("Icons.check_circle_rounded", "0xFF43A047"),
}

STATUS_TO_UPD = {
    "Pending": ('"0"', "false"),
    "Approve": ('"1"', "true"),
    "Confirm": ('"1"', "true"),
    "Update": ('"1"', "true"),
    "Deliver": ('"1"', "true"),
    "Received": ('"2"', "true"),
    "Ready To Approval": ('"1"', "true"),
    "Approved & Updated": ('"1"', "true"),
    "Send To Draft": ('"-9"', "true"),
    "Reject": ('"-1"', "true"),
}

CONFIG = {
    "lib/FE/approval_screen/purchase_approval/sppbj_approval/sppbj_app2.dart": {
        "type": "checkbox", "doc_no": "widget.sppbjno ?? ''", "back": "Get.to(() => SppbjApp())",
        "collapsed": "widget.requestorname ?? '-'", "fields": [("Date", "_formattedDate"), ("Request By", "widget.requestorname ?? '-'")],
        "reason": "widget.ket", "submit_method": "submitData",
    },
    "lib/FE/approval_screen/cash_bank/cash_advance_approval/ca_app2.dart": {
        "type": "checkbox", "doc_no": "widget.nokasbon ?? ''", "back": "Get.to(() => CashAdvanceApproval())",
        "collapsed": "widget.requestorname ?? '-'", "fields": [("Date", "_formattedDate"), ("Request By", "widget.requestorname ?? '-'")],
        "reason": "widget.ket", "submit_method": "submitData",
    },
    "lib/FE/approval_screen/cash_bank/ca_set_approval/ca_set_app2.dart": {
        "type": "checkbox", "doc_no": "widget.lpjk ?? ''", "back": "Get.to(() => CaSetApproval())",
        "collapsed": "widget.requestorname ?? '-'", "fields": [("Date", "_formattedDate"), ("Request By", "widget.requestorname ?? '-'")],
        "reason": "widget.ket", "submit_method": "submitData",
    },
    "lib/FE/approval_screen/purchase_approval/po_ex_approval/poex_app2.dart": {
        "type": "checkbox", "selection_actions": ["Send To Draft (ALL)"],
        "doc_no": "widget.pono ?? ''", "back": "Get.to(() => PoExApp())",
        "collapsed": "widget.requestor ?? '-'", "fields": [("Project", "widget.projectid ?? '-'"), ("Request By", "widget.requestor ?? '-'")],
        "submit_method": "submitData",
    },
    "lib/FE/approval_screen/purchase_approval/sppbj_confirm/sppbj_confirm2.dart": {
        "type": "confirm", "doc_no": "widget.sppbjno ?? ''", "back": "Get.to(() => SppbjConfirm())",
        "collapsed": "widget.requestorname ?? '-'",
        "fields": [("Type", "widget.sppbjtype == 0 ? 'SCM' : 'Non SCM'"), ("Warehouse", "widget.warehouse ?? '-'"),
                   ("WO No", "widget.wono ?? '-'"), ("Request By", "widget.requestorname ?? '-'")],
        "reason": "widget.reason", "item_title": "item['itemname'] ?? ''", "item_subtitle": "item['ket'] ?? ''",
        "item_amount": "item['amount']", "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
        "reason_controller": "textControllers.sppbjConfirmControllerReason.value",
    },
    "lib/FE/approval_screen/cash_bank/cash_advance_confirm/ca_confirm2.dart": {
        "type": "confirm", "doc_no": "widget.nokasbon ?? ''", "back": "Get.to(() => CashAdvanceConfirm())",
        "collapsed": "widget.requestorname ?? '-'",
        "fields": [("Request By", "widget.requestorname ?? '-'"), ("Cashier", "widget.kasirname ?? '-'")],
        "reason": "widget.ket", "item_title": "item['itemcoa'] ?? ''", "item_subtitle": "item['ket'] ?? ''",
        "item_amount": "item['amount']", "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
        "reason_controller": "textControllers.caConfirmControllerReason.value",
    },
    "lib/FE/approval_screen/cash_bank/ca_set_confirm/ca_set_confirm2.dart": {
        "type": "confirm", "doc_no": "widget.lpjk ?? ''", "back": "Get.to(() => CaSettleConfirm())",
        "collapsed": "widget.requestorname ?? '-'",
        "fields": [("Request By", "widget.requestorname ?? '-'")],
        "reason": "widget.ket", "item_title": "item['itemcoa'] ?? ''", "item_subtitle": "item['ket'] ?? ''",
        "item_amount": "item['amount']", "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
        "reason_controller": "textControllers.caSetConfirmControllerReason.value",
    },
    "lib/FE/approval_screen/inventory_approval/gr_approval/gr_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve", "Reject"],
        "doc_no": "widget.grno ?? ''", "back": "Get.to(() => GrApp())", "collapsed": "widget.requestorname ?? '-'",
        "fields": [("Request By", "widget.requestorname ?? '-'"), ("Supplier", "widget.suppliername ?? '-'"), ("Warehouse", "widget.locationname ?? '-'")],
        "submit": "if (updstatus == '-1') { reason(); } else { sendConfirm(); }", "no_total": True,
    },
    "lib/FE/approval_screen/inventory_approval/mr_approval/mr_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve", "Reject"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => MrApp())", "collapsed": "widget.requestorname ?? '-'",
        "fields": [("Request By", "widget.requestorname ?? '-'"), ("Warehouse", "widget.warehouse ?? '-'")],
        "reason": "widget.ket", "submit": "if (updstatus == '-1') { reason(); } else { sendConfirm(); }",
        "no_total": True,
    },
    "lib/FE/approval_screen/inventory_approval/sm_approval/sm_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => SmApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'"), ("Warehouse", "widget.warehouse ?? '-'")],
        "submit": "sendConfirm();", "no_total": True,
    },
    "lib/FE/approval_screen/purchase_approval/ap_adjustment/apadj_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve", "Reject"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => ApAdjApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'")],
        "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
        "total_amount_key": "amount_forex",
    },
    "lib/FE/approval_screen/inventory_approval/mu_approval/mu_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Update", "Reject"],
        "doc_no": "widget.dono ?? ''", "back": "Get.to(() => MuApp())", "collapsed": "widget.userid ?? '-'",
        "fields": [("User", "widget.userid ?? '-'")], "reason": "widget.ket",
        "submit": "if (updstatus == '-1') { reason(); } else { sendConfirm(); }", "no_total": True,
    },
    "lib/FE/approval_screen/inventory_approval/assembling_approval/asmb_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => AssemblingApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'"), ("Supplier", "widget.supplier ?? '-'"), ("Location", "widget.location ?? '-'")],
        "reason": "widget.ket", "submit": "sendConfirm();", "no_body": True, "no_total": True,
    },
    "lib/FE/approval_screen/inventory_approval/update_minmax_approval/minmax_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Update", "Send To Draft"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => UpdateMinMaxApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'"), ("Warehouse", "widget.warehouse ?? '-'")],
        "submit": "if (updstatus == '-9') { reason(); } else { sendConfirm(); }", "no_total": True,
    },
    "lib/FE/approval_screen/inventory_approval/stock_topup_approval/topup_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve", "Send To Draft"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => StockTopupApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'"), ("Warehouse", "widget.warehouse ?? '-'")],
        "submit": "if (updstatus == '-9') { reason(); } else { sendConfirm(); }", "no_total": True,
    },
    "lib/FE/approval_screen/inventory_approval/stockadj_approval/stockadj_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve", "Reject", "Send To Draft"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => StockAdjApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'"), ("Warehouse", "widget.warehouse ?? '-'")],
        "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
    },
    "lib/FE/approval_screen/inventory_approval/stock_trf_approval/stocktrf_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Deliver", "Reject"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => StockTrfApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'"), ("From", "widget.warehouse ?? '-'"), ("To", "widget.towh ?? '-'")],
        "submit": "if (updstatus == '-1') { reason(); } else { sendConfirm(); }", "no_total": True,
    },
    "lib/FE/approval_screen/inventory_approval/it_approval/it_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Deliver", "Reject", "Received"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => ItApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'"), ("To WH", "widget.towh ?? '-'")],
        "submit": "if (updstatus == '-1') { reason(); } else { sendConfirm(); }", "no_total": True,
    },
    "lib/FE/approval_screen/inventory_approval/itstock_adj_approval/itstock_app2.dart": {
        "type": "dropdown", "statuses": ["Ready To Approval", "Send To Draft", "Approved & Updated"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => ItStockAdjApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'"), ("Warehouse", "widget.warehouse ?? '-'")],
        "submit": "if (updstatus == '-9') { reason(); } else { sendConfirm(); }", "no_total": True,
    },
    "lib/FE/approval_screen/purchase_approval/dn_approval/dn_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve", "Reject", "Send To Draft"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => DebitNotesApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'")],
        "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
    },
    "lib/FE/approval_screen/purchase_approval/np_app/newap_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Confirm", "Reject", "Send To Draft"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => NpApp())", "collapsed": "widget.supplier ?? '-'",
        "fields": [("Supplier", "widget.supplier ?? '-'"), ("Amount", "widget.amount?.toString() ?? '-'")],
        "reason": "widget.ket", "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
        "scroll_body": True, "total_field": "gTTL",
    },
    "lib/FE/approval_screen/purchase_approval/po_scm_approval/poscm_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Confirm", "Reject", "Send To Draft"],
        "doc_no": "widget.pono ?? ''", "back": "Get.to(() => PoScmApp())", "collapsed": "widget.requestorname ?? '-'",
        "fields": [("Request By", "widget.requestorname ?? '-'"), ("Supplier", "widget.suppliername ?? '-'")],
        "reason": "widget.ket", "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
        "scroll_body": True,
    },
    "lib/FE/approval_screen/purchase_approval/dpreq_approval/dpreq_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Confirm", "Reject", "Send To Draft"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => DpReqApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'"), ("Supplier", "widget.supplier ?? '-'")],
        "reason": "widget.ket", "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
    },
    "lib/FE/approval_screen/sales_approval/ar_app/ar_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Confirm", "Reject", "Send To Draft"],
        "doc_no": "widget.arno ?? ''", "back": "Get.to(() => ArApproval())", "collapsed": "widget.requestorname ?? '-'",
        "fields": [("Request By", "widget.requestorname ?? '-'"), ("Client", "widget.clientname ?? '-'")],
        "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
        "total_field": "totalPrice2", "total_amount_key": "amount_base",
    },
    "lib/FE/approval_screen/sales_approval/sales_order_app/sales_order_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve", "Reject", "Send To Draft"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => SalesOrderApproval())", "collapsed": "widget.client_id ?? '-'",
        "fields": [("Client", "widget.client_id ?? '-'")], "reason": "widget.notes",
        "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
    },
    "lib/FE/approval_screen/ppc_approval/wo_app/wo_app2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => WoApp())", "collapsed": "widget.username ?? '-'",
        "fields": [("Request By", "widget.username ?? '-'"), ("Project", "widget.projectid ?? '-'"), ("Location", "widget.locationname ?? '-'")],
        "reason": "widget.description", "submit": "sendConfirm();", "no_total": True,
        "extra_body": "const Padding(padding: EdgeInsets.all(12), child: Text('LIST ACTIVITY SPPBJ', style: TextStyle(fontWeight: FontWeight.bold)))",
    },
    "lib/FE/approval_screen/inventory_approval/stockprice_approval/stockprice_app2.dart": {
        "type": "dropdown", "statuses": [], "no_action_grid": True, "always_submit": True,
        "doc_no": "widget.apreff ?? ''", "back": "Get.to(() => StockPriceApp())", "collapsed": "widget.supplierName ?? '-'",
        "fields": [("JV No", "widget.apjvno ?? '-'"), ("Supplier", "widget.supplierName ?? '-'")],
        "submit": "sendConfirm();", "total_field": "totalDiff", "idle_hint": "Tap submit to approve",
        "total_amount_key": "amountap",
    },
    "lib/FE/approval_screen/purchase_approval/poscm_unapproved/poscm_unapproved2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve", "Send To Draft"],
        "doc_no": "widget.pono ?? ''", "back": "Get.to(() => PoUnapproved())", "collapsed": "widget.requestorname ?? '-'",
        "fields": [("Request By", "widget.requestorname ?? '-'"), ("Supplier", "widget.supplier ?? '-'")],
        "submit": "if (updstatus == '-9') { reason(); } else { submitData(); }", "submit_method": "submitData",
        "scroll_body": True,
    },
    "lib/FE/approval_screen/purchase_approval/ap_refund/ap_refund2.dart": {
        "type": "dropdown", "statuses": ["Pending", "Approve", "Reject", "Send To Draft"],
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => ApRefundApp())", "collapsed": "widget.requestor ?? '-'",
        "fields": [("Request By", "widget.requestor ?? '-'")],
        "submit": "if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); }",
    },
    "lib/FE/approval_screen/ppc_approval/wo_completed/wo_completed2.dart": {
        "type": "dropdown", "statuses": [], "no_action_grid": True, "always_submit": True,
        "doc_no": "widget.reffno ?? ''", "back": "Get.to(() => WoCompleted())", "collapsed": "widget.username ?? '-'",
        "fields": [("Request By", "widget.username ?? '-'"), ("Project", "widget.projectid ?? '-'")],
        "submit": "sendConfirm();", "idle_hint": "Tap submit to continue", "no_total": True,
    },
}


def find_matching(content: str, open_idx: int, open_c: str, close_c: str) -> int:
    depth = 0
    i = open_idx
    in_str = None
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
        elif c in ('"', "'"):
            in_str = c
        elif c == open_c:
            depth += 1
        elif c == close_c:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def find_orange_header_end(content: str) -> int:
    pos = 0
    while True:
        idx = content.find("#F4A62A", pos)
        if idx == -1:
            return -1
        start = content.rfind("Container(", max(0, idx - 800), idx)
        if start == -1:
            pos = idx + 1
            continue
        paren = content.find("(", start)
        end = find_matching(content, paren, "(", ")")
        if end > idx:
            return end + 1
        pos = idx + 1


def extract_future_builder(content: str) -> Optional[str]:
    idx = 0
    while True:
        idx = content.find("FutureBuilder(", idx)
        if idx == -1:
            return None
        chunk = content[idx : idx + 120]
        if "dataFuture" in chunk:
            paren = content.find("(", idx + len("FutureBuilder"))
            end = find_matching(content, paren, "(", ")")
            if end != -1:
                fb = content[idx : end + 1]
                if "DataTable2" in fb or "ListView" in fb or "SizedBox" in fb:
                    return fb
        idx += 1


def extract_body_content(content: str, cfg: dict) -> Optional[str]:
    if cfg.get("no_body"):
        return None
    if cfg["type"] != "confirm" and not cfg.get("scroll_body"):
        fb = extract_future_builder(content)
        if fb:
            extra = cfg.get("extra_body")
            return f"{extra},\n{fb}" if extra else fb
    header_end = find_orange_header_end(content)
    if header_end == -1:
        return None
    bnb = content.find("bottomNavigationBar:", header_end)
    if bnb == -1:
        return None
    body = content[header_end:bnb].strip()
    body = re.sub(r"^,\s*", "", body)
    body = re.sub(
        r"Visibility\(\s*visible: selectedGak,[\s\S]*?\),\s*\n\s*",
        "",
        body,
    )
    if not cfg.get("scroll_body"):
        body = re.sub(
            r",\s*const SizedBox\([^)]*\),\s*FutureBuilder\(\s*future: dataFuture,[\s\S]*?"
            r"format\((?:totalPrice|totalPrice2|gTTL|totalDiff|sTTL)[\s\S]*?\),\s*\n\s*\}\s*,\s*\n\s*\),\s*$",
            "",
            body,
        )
        body = re.sub(
            r",\s*FutureBuilder\(\s*future: dataFuture,[\s\S]*?"
            r"format\((?:totalPrice|totalPrice2|gTTL|totalDiff|sTTL)[\s\S]*?\),\s*\n\s*\}\s*,\s*\n\s*\),\s*$",
            "",
            body,
        )
    return body.strip().rstrip(",").strip()


def normalize_body(body: str) -> str:
    body = re.sub(r"if \(snapshot\.error != null\)", "if (snapshot.hasError)", body)
    body = re.sub(
        r"return const Center\(\s*child: Text\('Error Loading Data'\),\s*\);",
        "return Center(child: Text('Error Loading Data', style: TextStyle(color: Colors.grey.shade500)));",
        body,
    )
    body = re.sub(
        r"return const Center\(\s*child: Column\(\s*children: \[[\s\S]*?CircularProgressIndicator\(\)[\s\S]*?\]\s*,?\s*\)\s*,?\s*\);",
        "return Center(child: CircularProgressIndicator(color: ApprovalTheme.primary));",
        body,
    )
    body = re.sub(r"return Expanded\(\s*child: (DataTable2|ListView|SingleChildScrollView)", r"return \1", body)
    body = re.sub(
        r"(return DataTable2\([\s\S]*?\.toList\(\),\s*\n\s*)\),\s*\n\s*\);",
        r"\1);",
        body,
    )
    return body


def add_import(content: str) -> str:
    if "approval_ui.dart" in content:
        return content
    marker = "import 'package:v2rp3/FE/navbar/navbar.dart';"
    if marker in content:
        return content.replace(marker, marker + "\nimport 'package:v2rp3/FE/shared/approval_ui.dart';", 1)
    return re.sub(
        r"(import '[^']+';\n)(class )",
        r"\1import 'package:v2rp3/FE/shared/approval_ui.dart';\n\n\2",
        content,
        count=1,
    )


def build_status_actions(statuses: List[str]) -> str:
    lines = ["  static const _statusActions = ["]
    for s in statuses:
        icon, color = ACTION_META.get(s, ("Icons.touch_app_outlined", "0xFFF4A62A"))
        lines.append(f"    ApprovalActionMeta(label: '{s}', icon: {icon}, color: Color({color})),")
    lines.append("  ];")
    return "\n".join(lines)


def build_on_status_selected(statuses: List[str]) -> str:
    lines = ["  void _onStatusSelected(String status) {", "    setState(() {", "      valueStatus = status;"]
    for i, s in enumerate(statuses):
        upd, vis = STATUS_TO_UPD[s]
        kw = "if" if i == 0 else "else if"
        lines.append(f'      {kw} (status == "{s}") {{ updstatus = {upd}; isVisible = {vis}; }}')
    lines += ["    });", "  }"]
    return "\n".join(lines)


def build_checkbox_helpers(actions: List[str]) -> str:
    meta = ["  static const _selectionActions = ["]
    for label in actions:
        if "Reject" in label:
            icon, color = ACTION_META["Reject"]
        else:
            icon, color = ACTION_META["Send To Draft"]
        meta.append(f"    ApprovalActionMeta(label: '{label}', icon: {icon}, color: Color({color})),")
    meta.append("  ];")
    on = ["  void _onSelectionAction(String label) {", "    setState(() {", "      _selectionAction = label;"]
    for label in actions:
        if "Reject" in label:
            on.append("      if (label == 'Reject Selected') valueButton = '-1';")
        elif "Draft" in label:
            on.append("      else if (label == 'Send To Draft (ALL)') valueButton = '-9';")
    on += ["    });", "  }"]
    return (
        "\n".join(meta)
        + "\n\n  String get _formattedDate =>\n      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));\n\n"
        + "\n".join(on)
    )


def build_scaffold(cfg: dict) -> str:
    fields = cfg.get("fields", [])
    fields_dart = "\n".join(f"            ApprovalInfoField('{lbl}', {val})," for lbl, val in fields)
    reason_line = f"          reason: {cfg['reason']},\n" if cfg.get("reason") else ""
    total = cfg.get("total_field", "totalPrice")
    idle = cfg.get("idle_hint", "Select an action to continue")
    submit = cfg.get("submit", "sendConfirm();")
    submit_method = cfg.get("submit_method", "sendConfirm")
    item_count = "0" if cfg.get("no_body") else "dataaa.length"

    if cfg["type"] == "checkbox":
        return f"""  @override
  Widget build(BuildContext context) {{
    final hasSelection = selectedGak;
    final displayAction = _selectionAction.isNotEmpty ? _selectionAction : 'Approve All';
    return WillPopScope(
      onWillPop: () async {{
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are You sure?'),
            content: const Text('Do you want to exit V2RP Mobile?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
            ],
          ),
        );
        if (shouldPop == true) SystemNavigator.pop();
        return false;
      }},
      child: ApprovalDetailScaffold(
        docNo: {cfg['doc_no']},
        subtitle: _formattedDate,
        onBack: () => {cfg['back']},
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: {cfg['collapsed']},
          fields: [
{fields_dart}
          ],
{reason_line}        ),
        actionSection: hasSelection ? ApprovalActionGrid(
          actions: _selectionActions, selectedLabel: _selectionAction, onSelected: _onSelectionAction,
        ) : null,
        body: Container(
          color: ApprovalTheme.background,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _buildBody(),
        ),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: {total}, itemCount: {item_count},
          selectedAction: hasSelection ? displayAction : null,
          actionColor: hasSelection ? (_selectionAction.isNotEmpty
              ? ApprovalActions.colorFor(_selectionAction, _selectionActions) : ApprovalTheme.primary) : null,
          submitLabel: _selectionAction.isNotEmpty ? 'Submit' : 'Approve All',
          idleHint: 'Select items to continue',
          onSubmit: hasSelection ? () {{
            if (_selectionAction.contains('Draft') || _selectionAction.contains('Reject')) reason();
            else {{ setState(() => valueButton = '1'); {submit_method}(); }}
          }} : null,
        ),
      ),
    );
  }}"""

    if cfg["type"] == "confirm":
        submit_expr = cfg.get("submit", "sendConfirm();")
        return f"""  @override
  Widget build(BuildContext context) {{
    final hasAction = isVisible && valueStatus.isNotEmpty;
    return WillPopScope(
      onWillPop: () async {{
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are You sure?'),
            content: const Text('Do you want to exit V2RP Mobile?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
            ],
          ),
        );
        if (shouldPop == true) SystemNavigator.pop();
        return false;
      }},
      child: ApprovalDetailScaffold(
        docNo: {cfg['doc_no']},
        subtitle: _formattedDate,
        onBack: () => {cfg['back']},
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: {cfg['collapsed']},
          fields: [
{fields_dart}
          ],
{reason_line}        ),
        actionSection: ApprovalActionGrid(
          actions: ApprovalActions.confirmActions,
          selectedLabel: valueStatus,
          onSelected: _onStatusSelected,
        ),
        body: Container(
          color: ApprovalTheme.background,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _buildBody(),
        ),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: totalPrice, itemCount: {item_count},
          selectedAction: hasAction ? valueStatus : null,
          actionColor: hasAction ? ApprovalActions.colorFor(valueStatus, ApprovalActions.confirmActions) : null,
          idleHint: 'Select an action to continue',
          onSubmit: hasAction ? () {{ {submit_expr} }} : null,
        ),
      ),
    );
  }}"""

    always = cfg.get("always_submit", False)
    no_grid = cfg.get("no_action_grid", False)
    action = "null" if no_grid else "ApprovalActionGrid(actions: _statusActions, selectedLabel: valueStatus, onSelected: _onStatusSelected)"
    has = "true" if always else "isVisible && valueStatus.isNotEmpty"
    sel = "'Submit'" if always else "valueStatus"
    on_submit = f"() {{ {submit} }}" if always else f"hasAction ? () {{ {submit} }} : null"

    return f"""  @override
  Widget build(BuildContext context) {{
    final hasAction = {has};
    return WillPopScope(
      onWillPop: () async {{
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are You sure?'),
            content: const Text('Do you want to exit V2RP Mobile?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
            ],
          ),
        );
        if (shouldPop == true) SystemNavigator.pop();
        return false;
      }},
      child: ApprovalDetailScaffold(
        docNo: {cfg['doc_no']},
        subtitle: _formattedDate,
        onBack: () => {cfg['back']},
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: {cfg['collapsed']},
          fields: [
{fields_dart}
          ],
{reason_line}        ),
        actionSection: {action},
        body: Container(
          color: ApprovalTheme.background,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _buildBody(),
        ),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: {total}, itemCount: {item_count},
          selectedAction: hasAction ? {sel} : null,
          actionColor: hasAction ? ApprovalTheme.primary : null,
          idleHint: '{idle}',
          onSubmit: {on_submit},
        ),
      ),
    );
  }}"""


def build_confirm_body(cfg: dict) -> str:
    title = cfg["item_title"].replace("item[", "dataaa[i][")
    subtitle = cfg["item_subtitle"].replace("item[", "dataaa[i][")
    amount = cfg["item_amount"].replace("item[", "dataaa[i][")
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
            ApprovalItemsHeader(count: dataaa.length),
            for (var i = 0; i < dataaa.length; i++)
              GestureDetector(
                onTap: () {{
                  final item = dataaa[i];
                  showApprovalItemDetail(
                    context: context,
                    index: i + 1,
                    title: {title},
                    fields: [
                      ApprovalInfoField('Item', {title}),
                      ApprovalInfoField('Description', {subtitle}),
                      ApprovalInfoField('Amount', ApprovalTheme.currencyFmt.format({amount})),
                    ],
                  );
                }},
                child: ApprovalCompactItemTile(
                  index: i + 1,
                  title: {title},
                  subtitle: {subtitle},
                  amount: ApprovalTheme.currencyFmt.format({amount}),
                ),
              ),
          ],
        );
      }},
    );
  }}"""


def build_body_fn(cfg: dict, body: Optional[str]) -> str:
    if cfg.get("no_body"):
        extra = cfg.get("extra_body", "")
        if extra:
            return f"  Widget _buildBody() {{ return ListView(children: [{extra}]); }}\n"
        return "  Widget _buildBody() => const SizedBox.shrink();\n"
    if cfg["type"] == "confirm":
        return build_confirm_body(cfg) + "\n"
    body = normalize_body(body or "")
    extra = cfg.get("extra_body")
    if extra:
        body = extra + ",\n" + body if body else extra
    if cfg.get("scroll_body"):
        return f"  Widget _buildBody() {{\n    return ListView(children: [\n{body}\n    ]);\n  }}\n"
    if "FutureBuilder" in body:
        return f"  Widget _buildBody() {{\n    return {body};\n  }}\n"
    return f"  Widget _buildBody() {{\n    return ListView(children: [{body}]);\n  }}\n"


def build_helpers(cfg: dict) -> str:
    if cfg["type"] == "checkbox":
        actions = cfg.get("selection_actions", ["Reject Selected", "Send To Draft (ALL)"])
        return build_checkbox_helpers(actions) + "\n"
    statuses = cfg.get("statuses", [])
    date_getter = "  String get _formattedDate =>\n      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));\n\n"
    if cfg["type"] == "confirm":
        return date_getter + build_on_status_selected(["Pending", "Confirm", "Reject", "Send To Draft"]) + "\n"
    if statuses:
        return build_status_actions(statuses) + "\n\n" + date_getter + build_on_status_selected(statuses) + "\n"
    return date_getter


def find_build_method_span(content: str) -> Optional[Tuple[int, int]]:
    m = re.search(r"\n  @override\n  Widget build\(BuildContext context\) \{", content)
    if not m:
        return None
    brace = content.find("{", m.end() - 1)
    end = find_matching(content, brace, "{", "}")
    if end == -1:
        return None
    return m.start(), end + 1


def fix_getdata(content: str, cfg: dict) -> str:
    total_field = cfg.get("total_field", "totalPrice")
    amount_key = cfg.get("total_amount_key", "amount")
    if cfg.get("no_total"):
        pat = r"(final \w+ = json\.decode\([^)]+\);)\s*\n\s*(?://[^\n]*\n\s*)*dataaa = ([^;]+);"
        repl = r"\1\n      final details = \2;\n      if (mounted) { setState(() => dataaa = details); } else { dataaa = details; }"
        return re.sub(pat, repl, content, count=1, flags=re.S)
    pat = (
        rf"(final \w+ = json\.decode\([^)]+\);)\s*\n\s*(?://[^\n]*\n\s*)*"
        rf"dataaa = ([^;]+);\s*\n\s*(?://[^\n]*\n\s*)*{re.escape(total_field)} = 0;\s*\n\s*"
        rf"for \(var item in dataaa\) \{{\s*\n\s*{re.escape(total_field)} \+= ([^;]+);\s*\n\s*\}}"
    )
    repl = (
        rf"\1\n      final details = \2;\n      var total = 0.0;\n"
        rf'      for (var item in details) {{ total += (item["{amount_key}"] as num).toDouble(); }}\n'
        rf"      if (mounted) {{ setState(() {{ dataaa = details; {total_field} = total; }}); }}\n"
        rf"      else {{ dataaa = details; {total_field} = total; }}"
    )
    return re.sub(pat, repl, content, flags=re.S)


def migrate_file(path: str, cfg: dict) -> bool:
    p = ROOT / path
    content = p.read_text()
    if "ApprovalDetailScaffold" in content:
        return False

    body = extract_body_content(content, cfg) if cfg["type"] != "confirm" else None
    if body is None and not cfg.get("no_body") and cfg["type"] != "confirm":
        print(f"FAIL body extract: {path}")
        return False

    span = find_build_method_span(content)
    if not span:
        print(f"FAIL build: {path}")
        return False

    helpers = build_helpers(cfg)
    body_fn = build_body_fn(cfg, body)
    new_section = "\n" + helpers + body_fn + "\n" + build_scaffold(cfg) + "\n"
    content = content[: span[0]] + new_section + content[span[1] :]
    content = add_import(content)
    content = fix_getdata(content, cfg)

    if cfg["type"] == "checkbox":
        if "_selectionAction" not in content:
            if "String reasonValue = '';" in content:
                content = content.replace(
                    "String reasonValue = '';",
                    "String reasonValue = '';\n  String _selectionAction = '';",
                    1,
                )
            else:
                content = content.replace(
                    "bool selectedGak = false;",
                    "bool selectedGak = false;\n  String _selectionAction = '';",
                    1,
                )
        content = content.replace(
            "if (isSelected != null) {\n                                          selectedGak = true;\n                                        }",
            "if (isSelected != null) {\n                                          selectedGak = true;\n                                        }\n"
            "                                        if (selectedDetails.isEmpty) {\n"
            "                                          selectedGak = false;\n"
            "                                          _selectionAction = '';\n"
            "                                        }",
            1,
        )

    p.write_text(content)
    print(f"OK: {path}")
    return True


def main():
    ok = 0
    for rel, cfg in CONFIG.items():
        if migrate_file(rel, cfg):
            ok += 1
    print(f"Migrated {ok} files")


if __name__ == "__main__":
    main()
