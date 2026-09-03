import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:v2rp3/utils/hex_color.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────

class ApprovalTheme {
  ApprovalTheme._();

  static final Color primary = HexColor('#F4A62A');
  static final Color primaryDark = HexColor('#D4891A');
  static const Color background = Color(0xFFF5F5F7);

  static final NumberFormat currencyFmt =
      NumberFormat.currency(locale: 'eu', symbol: '');

  static String formatQty(dynamic item) {
    final qty = item['qty']?.toString() ?? '-';
    final unit = item['unit'];
    if (unit == null || unit.toString().isEmpty) return qty;
    return '$qty $unit';
  }
}

// ─── Field helpers (show all API response data) ─────────────────────────────

const Set<String> _approvalSkipFieldKeys = {
  'seckey',
  'urutan',
  'rowid',
  'id',
  'password',
  'token',
};

const Set<String> _approvalMoneyFieldKeys = {
  'amount',
  'harga',
  'price',
  'total',
  'tax',
  'disc',
  'budgetavailable',
  'amount_forex',
  'amount_base',
  'amountap',
  'qtamountgr',
  'taxamount',
  'sisa',
  'saldo',
};

String approvalHumanizeFieldKey(String key) {
  var s = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  s = s.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.isEmpty) return key;
  return s.split(' ').map((w) {
    if (w.isEmpty) return w;
    if (w.length <= 3 && w == w.toUpperCase()) return w;
    return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
  }).join(' ');
}

bool approvalIsMoneyFieldKey(String key) {
  final k = key.toLowerCase();
  for (final part in _approvalMoneyFieldKeys) {
    if (k.contains(part)) return true;
  }
  return false;
}

String approvalFormatFieldValue(String key, dynamic value) {
  if (value == null) return '-';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is num && approvalIsMoneyFieldKey(key)) {
    return ApprovalTheme.currencyFmt.format(value);
  }
  if (value is Map) {
    final parts = <String>[];
    value.forEach((k, v) {
      final label = approvalHumanizeFieldKey(k.toString());
      parts.add('$label: ${approvalFormatFieldValue(k.toString(), v)}');
    });
    return parts.isEmpty ? '-' : parts.join('\n');
  }
  if (value is List) {
    if (value.isEmpty) return '-';
    return value.map((e) => e.toString()).join(', ');
  }
  final text = value.toString().trim();
  return text.isEmpty ? '-' : text;
}

/// Converts API numeric values safely; null or invalid → 0.
double approvalToDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

/// Sums [fieldKey] across detail rows; uses [fallbackKey] when primary is null.
double approvalSumField(
  Iterable<dynamic> items,
  String fieldKey, {
  String? fallbackKey,
}) {
  var total = 0.0;
  for (final item in items) {
    if (item is! Map) continue;
    dynamic value = item[fieldKey];
    if (value == null && fallbackKey != null) {
      value = item[fallbackKey];
    }
    total += approvalToDouble(value);
  }
  return total;
}

/// Sums line amount using `amount_forex` when non-zero, otherwise `amount_base`.
double approvalSumForexOrBase(Iterable<dynamic> items) {
  var total = 0.0;
  for (final item in items) {
    if (item is! Map) continue;
    final forex = approvalToDouble(item['amount_forex']);
    final base = approvalToDouble(item['amount_base']);
    total += forex != 0 ? forex : base;
  }
  return total;
}

/// Sums line amount using `amount_base` when non-zero, otherwise `amount_forex`.
double approvalSumBaseOrForex(Iterable<dynamic> items) {
  var total = 0.0;
  for (final item in items) {
    if (item is! Map) continue;
    final base = approvalToDouble(item['amount_base']);
    final forex = approvalToDouble(item['amount_forex']);
    total += base != 0 ? base : forex;
  }
  return total;
}

/// AP Adjustment: sum primary lines only (tipe 0/1), exclude forex offset rows.
double approvalSumApAdjPrimary(Iterable<dynamic> items) {
  var total = 0.0;
  for (final item in items) {
    if (item is! Map) continue;
    final tipe = approvalToDouble(item['tipe']).toInt();
    if (tipe != 0 && tipe != 1) continue;
    final base = approvalToDouble(item['amount_base']);
    final forex = approvalToDouble(item['amount_forex']);
    total += base != 0 ? base : forex;
  }
  return total;
}

String approvalApAdjTypeLabel(dynamic tipe) {
  final n = approvalToDouble(tipe).toInt();
  if (n == 0 || n == 1) return 'Account Payable';
  return 'Other Expenses';
}

/// Line amount from `amount`, or `qty * harga` when amount is missing.
double approvalLineAmount(Map<dynamic, dynamic> item) {
  final amount = item['amount'];
  if (amount != null) return approvalToDouble(amount);
  return approvalToDouble(item['qty']) * approvalToDouble(item['harga']);
}

/// Sums line amounts across detail rows.
double approvalSumLineAmount(Iterable<dynamic> items) {
  var total = 0.0;
  for (final item in items) {
    if (item is Map) {
      total += approvalLineAmount(item);
    }
  }
  return total;
}

double approvalLineTaxAmount(Map<dynamic, dynamic> item) {
  final tax = item['taxamount'] ?? item['taxAmount'];
  return approvalToDouble(tax);
}

/// Sales/PO line net: `(qty × harga) × (100 − lineDisc%) / 100 + tax`.
double approvalSalesLineNet(Map<dynamic, dynamic> item) {
  final qty = approvalToDouble(item['qty']);
  final harga = approvalToDouble(item['harga']);
  final lineDiscPct = approvalToDouble(item['disc']);
  final subtotal = qty * harga;
  final afterLineDisc = subtotal * (100 - lineDiscPct) / 100;
  return afterLineDisc + approvalLineTaxAmount(item);
}

/// Sales Order total: sum of line nets, then optional header discount %.
double approvalSumSalesOrderTotal(
  Iterable<dynamic> items, {
  double headerDiscPercent = 0,
}) {
  var subtotal = 0.0;
  for (final item in items) {
    if (item is Map) {
      subtotal += approvalSalesLineNet(item);
    }
  }
  if (headerDiscPercent != 0) {
    subtotal = subtotal * (100 - headerDiscPercent) / 100;
  }
  return subtotal;
}

List<ApprovalInfoField> approvalFieldsFromRecord(
  dynamic record, {
  List<String>? priorityKeys,
  Map<String, String>? labels,
  Set<String>? skipKeys,
}) {
  if (record is! Map) return [];
  final map = Map<String, dynamic>.from(record);
  final skip = {..._approvalSkipFieldKeys, ...?skipKeys};
  final result = <ApprovalInfoField>[];
  final seen = <String>{};

  void addField(String key) {
    if (skip.contains(key) || seen.contains(key)) return;
    if (!map.containsKey(key)) return;
    final raw = map[key];
    if (raw == null || (raw is String && raw.trim().isEmpty)) return;
    seen.add(key);
    final label = labels?[key] ?? approvalHumanizeFieldKey(key);
    result.add(
        ApprovalInfoField(label, approvalFormatFieldValue(key, raw)));
  }

  if (priorityKeys != null) {
    for (final key in priorityKeys) {
      addField(key);
    }
  }

  final remaining = map.keys.where((k) => !seen.contains(k)).toList()
    ..sort();
  for (final key in remaining) {
    addField(key);
  }

  return result;
}

List<ApprovalInfoField> approvalMergeFields(
  List<ApprovalInfoField> primary,
  dynamic extra, {
  Set<String>? skipKeys,
}) {
  if (extra is! Map || extra.isEmpty) return primary;
  final usedLabels =
      primary.map((f) => f.label.toLowerCase()).toSet();
  final extraFields = approvalFieldsFromRecord(extra, skipKeys: skipKeys);
  return [
    ...primary,
    ...extraFields.where((f) => !usedLabels.contains(f.label.toLowerCase())),
  ];
}

/// Reads budget available from item/header map when [budget] may be null.
num approvalBudgetAvailable(dynamic item) {
  if (item is! Map) return 0;
  final budget = item['budget'];
  if (budget is Map) {
    final value = budget['budgetavailable'];
    if (value is num) return value;
    if (value != null) return num.tryParse(value.toString()) ?? 0;
  }
  final direct = item['budgetavailable'];
  if (direct is num) return direct;
  if (direct != null) return num.tryParse(direct.toString()) ?? 0;
  return 0;
}

/// Account name line: [itemcoa] + [rem] from API item row.
String approvalAccountName(dynamic item) {
  if (item is! Map) return '-';
  final coa = item['itemcoa']?.toString().trim() ?? '';
  final rem = item['rem']?.toString().trim() ?? '';
  if (coa.isNotEmpty && rem.isNotEmpty) return '$coa - $rem';
  if (coa.isNotEmpty) return coa;
  if (rem.isNotEmpty) return rem;
  return '-';
}

/// Cash advance line type: 0 = Budget, 1 = Item.
String approvalCashAdvanceTypeLabel(dynamic tipe) {
  final value = tipe?.toString();
  if (value == '0') return 'Budget';
  if (value == '1') return 'Item';
  return value ?? '-';
}

/// Project display name from API variants (`projectName`, `projectname`, `projectid`).
String approvalProjectName(dynamic item) {
  if (item is! Map) return '-';
  final direct = item['projectName'] ?? item['projectname'] ?? item['projectid'];
  if (direct != null && direct.toString().trim().isNotEmpty) {
    return direct.toString();
  }
  final budget = item['budget2'];
  if (budget is Map) {
    final fromBudget =
        budget['cprojectket'] ?? budget['cprojectid'] ?? budget['projectid'];
    if (fromBudget != null && fromBudget.toString().trim().isNotEmpty) {
      return fromBudget.toString();
    }
  }
  return '-';
}

/// Project ID from API variants (`projectid`, `projectId`, nested `budget2`).
String approvalProjectId(dynamic item) {
  if (item is! Map) return '-';
  final direct = item['projectid'] ?? item['projectId'];
  if (direct != null && direct.toString().trim().isNotEmpty) {
    return direct.toString();
  }
  final budget = item['budget2'];
  if (budget is Map) {
    final fromBudget = budget['projectid'] ?? budget['cprojectid'];
    if (fromBudget != null && fromBudget.toString().trim().isNotEmpty) {
      return fromBudget.toString();
    }
  }
  return '-';
}

/// Standard SPPBJ / purchase confirm item fields — matches original DataTable columns.
List<ApprovalInfoField> approvalSppbjItemFields(dynamic item) {
  return [
    ApprovalInfoField(
        'Request By', item['requestorname']?.toString() ?? ''),
    ApprovalInfoField(
        'Project Name', approvalProjectName(item)),
    ApprovalInfoField(
        'Item Account No', item['itemcoa']?.toString() ?? ''),
    ApprovalInfoField(
        'Item/ Account Name', approvalAccountName(item)),
    ApprovalInfoField('Remark SPPBJ', item['ket']?.toString() ?? ''),
    ApprovalInfoField('Unit', item['unit']?.toString() ?? ''),
    ApprovalInfoField('Qty', item['qty']?.toString() ?? ''),
    ApprovalInfoField(
        'Price/Unit',
        ApprovalTheme.currencyFmt.format(item['harga'] ?? 0)),
    ApprovalInfoField(
        'Amount', ApprovalTheme.currencyFmt.format(item['amount'] ?? 0)),
    ApprovalInfoField(
        'Budget Avail',
        ApprovalTheme.currencyFmt.format(approvalBudgetAvailable(item))),
  ];
}

class ApprovalInfoField {
  final String label;
  final String value;
  const ApprovalInfoField(this.label, this.value);
}

class ApprovalActionMeta {
  final String label;
  final IconData icon;
  final Color color;
  const ApprovalActionMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ─── Header ─────────────────────────────────────────────────────────────────

class ApprovalCompactHeader extends StatelessWidget {
  final String docNo;
  final String subtitle;
  final VoidCallback onBack;

  const ApprovalCompactHeader({
    super.key,
    required this.docNo,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ApprovalTheme.primary, ApprovalTheme.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
                onPressed: onBack,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docNo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Collapsible section ────────────────────────────────────────────────────

class ApprovalCollapsibleSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? summary;
  final Widget? badge;
  final Widget child;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry margin;
  final void Function(VoidCallback collapse)? registerCollapse;

  const ApprovalCollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.summary,
    this.badge,
    this.initiallyExpanded = false,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 0),
    this.registerCollapse,
  });

  @override
  State<ApprovalCollapsibleSection> createState() =>
      _ApprovalCollapsibleSectionState();
}

class _ApprovalCollapsibleSectionState extends State<ApprovalCollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    widget.registerCollapse?.call(_collapse);
  }

  @override
  void didUpdateWidget(covariant ApprovalCollapsibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.registerCollapse != widget.registerCollapse) {
      widget.registerCollapse?.call(_collapse);
    }
  }

  void _collapse() {
    if (_expanded && mounted) setState(() => _expanded = false);
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary?.trim();
    final hasSummary = summary != null && summary.isNotEmpty && summary != '-';

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded
              ? ApprovalTheme.primary.withOpacity(0.35)
              : Colors.grey.shade200,
          width: _expanded ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _expanded
                ? ApprovalTheme.primary.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: _expanded ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: _expanded
                ? ApprovalTheme.primary.withOpacity(0.04)
                : Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: ApprovalTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(widget.icon,
                          size: 18, color: ApprovalTheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (!_expanded && hasSummary) ...[
                            const SizedBox(height: 3),
                            Text(
                              summary!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.badge != null) ...[
                      const SizedBox(width: 6),
                      widget.badge!,
                    ],
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: _expanded
                            ? ApprovalTheme.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(height: 1, color: Colors.grey.shade200),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: widget.child,
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

// ─── Info panel ─────────────────────────────────────────────────────────────

class ApprovalInfoPanel extends StatelessWidget {
  final String collapsedSubtitle;
  final List<ApprovalInfoField> fields;
  final String? reason;
  final Map<String, dynamic>? extraRecord;
  final bool initiallyExpanded;

  const ApprovalInfoPanel({
    super.key,
    required this.collapsedSubtitle,
    required this.fields,
    this.reason,
    this.extraRecord,
    this.initiallyExpanded = true,
  });

  List<ApprovalInfoField> get _allFields =>
      approvalMergeFields(fields, extraRecord);

  String? get _reasonText {
    if (reason != null && reason!.trim().isNotEmpty) return reason;
    if (extraRecord?['reason'] != null &&
        extraRecord!['reason'].toString().trim().isNotEmpty) {
      return extraRecord!['reason'].toString();
    }
    if (extraRecord?['ket'] != null &&
        extraRecord!['ket'].toString().trim().isNotEmpty) {
      return extraRecord!['ket'].toString();
    }
    return reason;
  }

  String get _collapsedSummary {
    final parts = <String>[];
    final sub = collapsedSubtitle.trim();
    if (sub.isNotEmpty && sub != '-') parts.add(sub);
    for (final f in _allFields.take(2)) {
      final v = f.value.trim();
      if (v.isNotEmpty && v != '-' && !parts.contains(v)) {
        parts.add(v);
      }
    }
    return parts.isEmpty ? 'Tap to view document details' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final reasonText =
        (_reasonText ?? '').trim().isNotEmpty ? _reasonText! : '-';
    final displayFields = _allFields;

    return ApprovalCollapsibleSection(
      title: 'Document Info',
      icon: Icons.description_outlined,
      summary: _collapsedSummary,
      initiallyExpanded: initiallyExpanded,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in displayFields)
            ApprovalInfoRow(label: f.label, value: f.value),
          const Divider(height: 16),
          Text(
            'Reason',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reasonText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ApprovalInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action grid ────────────────────────────────────────────────────────────

class ApprovalActionGrid extends StatefulWidget {
  final List<ApprovalActionMeta> actions;
  final String selectedLabel;
  final ValueChanged<String> onSelected;
  final bool initiallyExpanded;
  final bool collapseOnSelect;

  const ApprovalActionGrid({
    super.key,
    required this.actions,
    required this.selectedLabel,
    required this.onSelected,
    this.initiallyExpanded = false,
    this.collapseOnSelect = true,
  });

  @override
  State<ApprovalActionGrid> createState() => _ApprovalActionGridState();
}

class _ApprovalActionGridState extends State<ApprovalActionGrid> {
  VoidCallback? _collapseSection;

  ApprovalActionMeta? get _selectedMeta {
    for (final a in widget.actions) {
      if (a.label == widget.selectedLabel) return a;
    }
    return null;
  }

  void _handleSelect(String label) {
    widget.onSelected(label);
    if (widget.collapseOnSelect) {
      _collapseSection?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedMeta;
    final summary = widget.selectedLabel.isNotEmpty
        ? widget.selectedLabel
        : 'Tap to choose an action';

    return ApprovalCollapsibleSection(
      title: 'Select Action',
      icon: Icons.touch_app_outlined,
      summary: summary,
      initiallyExpanded: widget.initiallyExpanded,
      registerCollapse: (fn) => _collapseSection = fn,
      badge: selected != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: selected.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: selected.color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected.icon, size: 12, color: selected.color),
                  const SizedBox(width: 4),
                  Text(
                    selected.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected.color,
                    ),
                  ),
                ],
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var row = 0; row < widget.actions.length; row += 2) ...[
            if (row > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (var col = row;
                    col < row + 2 && col < widget.actions.length;
                    col++) ...[
                  if (col > row) const SizedBox(width: 8),
                  Expanded(
                    child: _ActionTile(
                      meta: widget.actions[col],
                      selected: widget.selectedLabel == widget.actions[col].label,
                      onTap: () => _handleSelect(widget.actions[col].label),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final ApprovalActionMeta meta;
  final bool selected;
  final VoidCallback onTap;

  const _ActionTile({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? meta.color.withOpacity(0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? meta.color : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(meta.icon, size: 22,
                color: selected ? meta.color : Colors.grey.shade400),
            const SizedBox(height: 5),
            Text(
              meta.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? meta.color : Colors.grey.shade600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Item tiles ─────────────────────────────────────────────────────────────

class ApprovalItemsHeader extends StatelessWidget {
  final int count;
  final String hint;
  final VoidCallback? onExpandAll;
  final VoidCallback? onCollapseAll;
  final bool selectable;
  final bool allSelected;
  final bool someSelected;
  final VoidCallback? onToggleSelectAll;

  const ApprovalItemsHeader({
    super.key,
    required this.count,
    this.hint = '',
    this.onExpandAll,
    this.onCollapseAll,
    this.selectable = false,
    this.allSelected = false,
    this.someSelected = false,
    this.onToggleSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final showHint = hint.trim().isNotEmpty &&
        onExpandAll == null &&
        onCollapseAll == null &&
        !selectable;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ApprovalTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 16, color: ApprovalTheme.primary),
          ),
          const SizedBox(width: 8),
          Text('Items',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ApprovalTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ApprovalTheme.primary)),
          ),
          if (showHint) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ),
          ] else
            const Spacer(),
          if (selectable && onToggleSelectAll != null) ...[
            _HeaderActionChip(
              label: allSelected ? 'Batal pilih' : 'Pilih semua',
              onTap: onToggleSelectAll!,
            ),
            const SizedBox(width: 6),
          ],
          if (onExpandAll != null && onCollapseAll != null) ...[
            _HeaderActionChip(label: 'Buka semua', onTap: onExpandAll!),
            const SizedBox(width: 6),
            _HeaderActionChip(label: 'Tutup semua', onTap: onCollapseAll!),
          ],
        ],
      ),
    );
  }
}

class _HeaderActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Item list section for detail pages — scrollable inside [ApprovalDetailScaffold].
class ApprovalDetailItemsColumn extends StatefulWidget {
  final int count;
  final String hint;
  final List<Widget> children;
  final bool scrollable;
  final List<List<ApprovalInfoField>>? tableRows;
  /// Full field set for row detail popup; defaults to [tableRows] when omitted.
  final List<List<ApprovalInfoField>>? detailRows;
  final bool selectable;
  final bool Function(int index)? isRowSelected;
  final void Function(int index, bool? selected)? onRowSelectionChanged;

  const ApprovalDetailItemsColumn({
    super.key,
    required this.count,
    this.children = const [],
    this.hint = '',
    this.scrollable = true,
    this.tableRows,
    this.detailRows,
    this.selectable = false,
    this.isRowSelected,
    this.onRowSelectionChanged,
  });

  @override
  State<ApprovalDetailItemsColumn> createState() =>
      _ApprovalDetailItemsColumnState();
}

class _ApprovalDetailItemsColumnState extends State<ApprovalDetailItemsColumn> {
  bool? _forceExpanded;
  int _expansionTick = 0;

  void _setAll(bool expanded) {
    setState(() {
      _forceExpanded = expanded;
      _expansionTick++;
    });
  }

  void _toggleSelectAll() {
    final rows = widget.tableRows;
    if (rows == null || rows.isEmpty) return;

    final selectAll = !_isAllSelected();
    for (var i = 0; i < rows.length; i++) {
      final selected = widget.isRowSelected?.call(i) ?? false;
      if (selectAll && !selected) {
        widget.onRowSelectionChanged?.call(i, true);
      } else if (!selectAll && selected) {
        widget.onRowSelectionChanged?.call(i, false);
      }
    }
  }

  bool _isAllSelected() {
    final rows = widget.tableRows;
    if (rows == null || rows.isEmpty) return false;
    for (var i = 0; i < rows.length; i++) {
      if (!(widget.isRowSelected?.call(i) ?? false)) return false;
    }
    return true;
  }

  bool _isSomeSelected() {
    final rows = widget.tableRows;
    if (rows == null || rows.isEmpty) return false;
    for (var i = 0; i < rows.length; i++) {
      if (widget.isRowSelected?.call(i) ?? false) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isTable = widget.tableRows != null;
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    if (isTable) {
      return Container(
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: ApprovalItemsHeader(
                count: widget.count,
                hint: 'Tap baris untuk detail · Geser horizontal',
                selectable: widget.selectable,
                allSelected: _isAllSelected(),
                someSelected: _isSomeSelected(),
                onToggleSelectAll:
                    widget.selectable ? _toggleSelectAll : null,
              ),
            ),
            Expanded(
              child: ApprovalItemsDataTable(
                rows: widget.tableRows!,
                detailRows: widget.detailRows,
                selectable: widget.selectable,
                isRowSelected: widget.isRowSelected,
                onRowSelectionChanged: widget.onRowSelectionChanged,
                onToggleSelectAll:
                    widget.selectable ? _toggleSelectAll : null,
              ),
            ),
            if (widget.children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                ),
              ),
          ],
        ),
      );
    }

    final showBulkToggle = widget.count > 1;
    final items = <Widget>[
      ApprovalItemsHeader(
        count: widget.count,
        hint: widget.hint,
        onExpandAll: showBulkToggle ? () => _setAll(true) : null,
        onCollapseAll: showBulkToggle ? () => _setAll(false) : null,
      ),
      ...widget.children,
    ];

    final list = widget.scrollable
        ? ListView(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
            children: items,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          );

    final body = widget.scrollable
        ? Container(decoration: decoration, child: list)
        : list;

    return _ApprovalItemExpansionScope(
      forceExpanded: _forceExpanded,
      tick: _expansionTick,
      child: body,
    );
  }
}

/// Scrollable table for approval item lines (stable layout inside [Expanded]).
class ApprovalItemsDataTable extends StatelessWidget {
  final List<List<ApprovalInfoField>> rows;
  final List<List<ApprovalInfoField>>? detailRows;
  final bool selectable;
  final bool Function(int index)? isRowSelected;
  final void Function(int index, bool? selected)? onRowSelectionChanged;
  final VoidCallback? onToggleSelectAll;

  const ApprovalItemsDataTable({
    super.key,
    required this.rows,
    this.detailRows,
    this.selectable = false,
    this.isRowSelected,
    this.onRowSelectionChanged,
    this.onToggleSelectAll,
  });

  List<String> get _columnLabels {
    if (rows.isEmpty) return [];
    return [for (final f in rows.first) f.label];
  }

  static String _cellForRow(List<ApprovalInfoField> row, String label) {
    for (final f in row) {
      if (f.label == label) return f.value;
    }
    return '-';
  }

  static bool _isMoneyColumn(String label) {
    final l = label.toLowerCase();
    return l.contains('amount') ||
        l.contains('price') ||
        l.contains('harga') ||
        l.contains('budget') ||
        l.contains('tax') ||
        l.contains('total') ||
        l.contains('dpp') ||
        l.contains('ppn') ||
        l.contains('pph');
  }

  void _openRowDetail(BuildContext context, int index) {
    final fields = detailRows != null && index < detailRows!.length
        ? detailRows![index]
        : rows[index];
    final header = approvalItemRowHeader(fields);
    showApprovalItemDetail(
      context: context,
      index: index + 1,
      title: header.title,
      subtitle: header.subtitle,
      fields: fields,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Text('Tidak ada item',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      );
    }

    final labels = _columnLabels;
    final allSelected = rows.isNotEmpty &&
        rows.asMap().keys.every((i) => isRowSelected?.call(i) ?? false);
    final someSelected =
        rows.asMap().keys.any((i) => isRowSelected?.call(i) ?? false);
    final headerCheckValue =
        allSelected ? true : (someSelected ? null : false);

    final border = TableBorder(
      top: BorderSide(color: Colors.grey.shade300),
      bottom: BorderSide(color: Colors.grey.shade300),
      left: BorderSide(color: Colors.grey.shade200),
      right: BorderSide(color: Colors.grey.shade200),
      horizontalInside: BorderSide(color: Colors.grey.shade200),
      verticalInside: BorderSide(color: Colors.grey.shade100),
    );

    final table = Table(
      columnWidths: {
        if (selectable) 0: const FixedColumnWidth(48),
        for (var i = 0; i < labels.length; i++)
          i + (selectable ? 1 : 0): const FixedColumnWidth(104),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: border,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: ApprovalTheme.primary.withOpacity(0.08),
          ),
          children: [
            if (selectable)
              SizedBox(
                width: 48,
                child: Checkbox(
                  tristate: true,
                  value: headerCheckValue,
                  activeColor: ApprovalTheme.primary,
                  onChanged: rows.isEmpty
                      ? null
                      : (_) => onToggleSelectAll?.call(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            for (final label in labels)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: _TableColumnLabel(text: label),
              ),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: selectable && (isRowSelected?.call(i) ?? false)
                  ? ApprovalTheme.primary.withOpacity(0.1)
                  : (i.isEven ? Colors.white : Colors.grey.shade50),
            ),
            children: [
              if (selectable)
                SizedBox(
                  width: 48,
                  child: Checkbox(
                    value: isRowSelected?.call(i) ?? false,
                    activeColor: ApprovalTheme.primary,
                    onChanged: (v) => onRowSelectionChanged?.call(i, v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              for (final label in labels)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openRowDetail(context, i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      child: _TableCellText(
                        value: _cellForRow(rows[i], label),
                        alignEnd: _isMoneyColumn(label),
                        bold: _isMoneyColumn(label),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: table,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TableColumnLabel extends StatelessWidget {
  final String text;

  const _TableColumnLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    if (words.length >= 2 && text.length > 11) {
      final mid = (words.length / 2).ceil();
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            words.sublist(0, mid).join(' '),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              height: 1.2,
            ),
          ),
          Text(
            words.sublist(mid).join(' '),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              height: 1.2,
            ),
          ),
        ],
      );
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String value;
  final bool alignEnd;
  final bool bold;

  const _TableCellText({
    required this.value,
    this.alignEnd = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isNotEmpty ? value.trim() : '-';
    return SizedBox(
      width: 100,
      child: Text(
        display,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: bold ? ApprovalTheme.primaryDark : Colors.grey.shade800,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ApprovalItemExpansionScope extends InheritedWidget {
  final bool? forceExpanded;
  final int tick;

  const _ApprovalItemExpansionScope({
    required this.forceExpanded,
    required this.tick,
    required super.child,
  });

  static _ApprovalItemExpansionScope? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ApprovalItemExpansionScope>();
  }

  @override
  bool updateShouldNotify(_ApprovalItemExpansionScope old) =>
      forceExpanded != old.forceExpanded || tick != old.tick;
}

/// Compact 2-column grid for short item fields.
class ApprovalItemFieldsBody extends StatelessWidget {
  final List<ApprovalInfoField> fields;

  const ApprovalItemFieldsBody({super.key, required this.fields});

  static bool _isWideField(ApprovalInfoField f) {
    final label = f.label.toLowerCase();
    if (ApprovalDetailFieldRow.isDescriptionLabel(f.label)) return true;
    if (label == 'amount' ||
        label == 'total' ||
        label.contains('grand total') ||
        label.contains('budget')) {
      return true;
    }
    return f.value.trim().length > 48;
  }

  @override
  Widget build(BuildContext context) {
    final compact = <ApprovalInfoField>[];
    final wide = <ApprovalInfoField>[];
    for (final f in fields) {
      if (_isWideField(f)) {
        wide.add(f);
      } else {
        compact.add(f);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in compact)
                    SizedBox(
                      width: cellWidth,
                      child: _CompactFieldCell(
                        label: f.label,
                        value: f.value,
                        highlight: f.label.toLowerCase() == 'amount' ||
                            f.label.toLowerCase() == 'total',
                      ),
                    ),
                ],
              );
            },
          ),
        if (compact.isNotEmpty && wide.isNotEmpty) const SizedBox(height: 8),
        for (final f in wide)
          ApprovalDetailFieldRow(
            label: f.label,
            value: f.value,
            highlight: f.label.toLowerCase() == 'amount' ||
                f.label.toLowerCase() == 'total',
            multiline: ApprovalDetailFieldRow.isDescriptionLabel(f.label),
          ),
      ],
    );
  }
}

class _CompactFieldCell extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _CompactFieldCell({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isNotEmpty ? value.trim() : '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? ApprovalTheme.primary.withOpacity(0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? ApprovalTheme.primary.withOpacity(0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            display,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight ? ApprovalTheme.primary : Colors.grey.shade800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline item card — collapsible; tap header to expand full detail.
class ApprovalExpandedItemCard extends StatefulWidget {
  final int index;
  final String? title;
  final String? subtitle;
  final String? amount;
  final List<ApprovalInfoField> fields;
  final bool embedded;
  final bool? initiallyExpanded;

  const ApprovalExpandedItemCard({
    super.key,
    required this.index,
    required this.fields,
    this.title,
    this.subtitle,
    this.amount,
    this.embedded = false,
    this.initiallyExpanded,
  });

  @override
  State<ApprovalExpandedItemCard> createState() =>
      _ApprovalExpandedItemCardState();
}

class _ApprovalExpandedItemCardState extends State<ApprovalExpandedItemCard> {
  late bool _expanded;
  int _lastExpansionTick = -1;

  bool get _defaultExpanded =>
      widget.initiallyExpanded ?? widget.fields.length <= 5;

  @override
  void initState() {
    super.initState();
    _expanded = _defaultExpanded;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _ApprovalItemExpansionScope.of(context);
    if (scope != null && scope.tick != _lastExpansionTick) {
      _lastExpansionTick = scope.tick;
      if (scope.forceExpanded != null) {
        setState(() => _expanded = scope.forceExpanded!);
      }
    }
  }

  String? get _headerTitle {
    final t = widget.title?.trim();
    if (t != null && t.isNotEmpty && t != '-') return t;
    for (final f in widget.fields) {
      final v = f.value.trim();
      if (v.isNotEmpty && v != '-') return v;
    }
    return null;
  }

  List<ApprovalInfoField> get _previewFields {
    final result = <ApprovalInfoField>[];
    for (final f in widget.fields) {
      final l = f.label.toLowerCase();
      if (l.contains('qty') ||
          l == 'unit' ||
          l == 'amount' ||
          l == 'total' ||
          l.contains('price') ||
          l.contains('harga')) {
        result.add(f);
      }
      if (result.length >= 3) break;
    }
    return result;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final headerTitle = _headerTitle;
    final amountText = widget.amount?.trim();
    final showAmount = amountText != null && amountText.isNotEmpty;
    final subtitleText = widget.subtitle?.trim();
    final showSubtitle =
        subtitleText != null && subtitleText.isNotEmpty && subtitleText != '-';
    final preview = _previewFields;

    return Container(
      margin:
          widget.embedded ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      decoration: widget.embedded
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(widget.embedded ? 0 : 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                decoration: BoxDecoration(
                  color: _expanded
                      ? ApprovalTheme.primary.withOpacity(0.05)
                      : Colors.transparent,
                  borderRadius:
                      widget.embedded ? null : BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ApprovalTheme.primary,
                            ApprovalTheme.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle ?? 'Item #${widget.index}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                              height: 1.3,
                            ),
                          ),
                          if (showSubtitle) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                height: 1.3,
                              ),
                            ),
                          ],
                          if (!_expanded && preview.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final f in preview)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${f.label}: ${f.value}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (!_expanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${widget.fields.length} field · ketuk untuk buka',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showAmount) ...[
                      const SizedBox(width: 6),
                      Text(
                        amountText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ApprovalTheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(width: 2),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ApprovalItemFieldsBody(fields: widget.fields),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

/// Inline item card with checkbox — for bulk-approval screens.
class ApprovalSelectableExpandedItemCard extends StatelessWidget {
  final int index;
  final bool selected;
  final ValueChanged<bool?>? onSelected;
  final String? title;
  final String? subtitle;
  final String? amount;
  final List<ApprovalInfoField> fields;

  const ApprovalSelectableExpandedItemCard({
    super.key,
    required this.index,
    required this.selected,
    required this.onSelected,
    required this.fields,
    this.title,
    this.subtitle,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? ApprovalTheme.primary.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? ApprovalTheme.primary : Colors.grey.shade200,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Checkbox(
              value: selected,
              activeColor: ApprovalTheme.primary,
              onChanged: onSelected,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Expanded(
            child: ApprovalExpandedItemCard(
              index: index,
              title: title,
              subtitle: subtitle,
              amount: amount,
              fields: fields,
              embedded: true,
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalCompactItemTile extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback? onTap;

  const ApprovalCompactItemTile({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ApprovalTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$index',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ApprovalTheme.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(amount,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ApprovalTheme.primary)),
              Icon(Icons.chevron_right,
                  size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact item row with checkbox — for bulk-approval screens.
class ApprovalSelectableItemTile extends StatelessWidget {
  final int index;
  final bool selected;
  final ValueChanged<bool?>? onSelected;
  final VoidCallback? onTap;
  final String title;
  final String subtitle;
  final String amount;

  const ApprovalSelectableItemTile({
    super.key,
    required this.index,
    required this.selected,
    required this.onSelected,
    this.onTap,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? ApprovalTheme.primary.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? ApprovalTheme.primary : Colors.grey.shade200,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: selected,
            activeColor: ApprovalTheme.primary,
            onChanged: onSelected,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ApprovalTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$index',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ApprovalTheme.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(amount,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ApprovalTheme.primary)),
                    Icon(Icons.chevron_right,
                        size: 18, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary totals section — collapsed by default to preserve item list space.
class ApprovalSummarySection extends StatefulWidget {
  final String title;
  final List<ApprovalInfoField> fields;
  final bool initiallyExpanded;
  final String highlightLabel;

  const ApprovalSummarySection({
    super.key,
    required this.title,
    required this.fields,
    this.initiallyExpanded = false,
    this.highlightLabel = 'Grand Total',
  });

  @override
  State<ApprovalSummarySection> createState() => _ApprovalSummarySectionState();
}

class _ApprovalSummarySectionState extends State<ApprovalSummarySection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  ApprovalInfoField? get _highlightField {
    for (final f in widget.fields) {
      if (f.label == widget.highlightLabel) return f;
    }
    return widget.fields.isNotEmpty ? widget.fields.last : null;
  }

  List<ApprovalInfoField> get _breakdownFields {
    return widget.fields
        .where((f) => f.label != widget.highlightLabel)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = _highlightField;
    final breakdown = _breakdownFields;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 16, color: ApprovalTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  if (!_expanded && highlight != null)
                    Text(
                      highlight.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ApprovalTheme.primaryDark,
                      ),
                    ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoCol = constraints.maxWidth >= 320;
                      if (!twoCol) {
                        return Column(
                          children: [
                            for (final f in breakdown)
                              _CompactSummaryRow(label: f.label, value: f.value),
                          ],
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          for (final f in breakdown)
                            SizedBox(
                              width: (constraints.maxWidth - 8) / 2,
                              child: _CompactSummaryRow(
                                label: f.label,
                                value: f.value,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (highlight != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: ApprovalTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              highlight.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Text(
                            highlight.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: ApprovalTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompactSummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value.isNotEmpty ? value : '-',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ApprovalDetailFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool multiline;

  const ApprovalDetailFieldRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.multiline = false,
  });

  static bool isDescriptionLabel(String label) {
    final l = label.toLowerCase();
    return l.contains('description') ||
        l.contains('remark') ||
        l == 'ket' ||
        l == 'desc' ||
        l.contains('keterangan');
  }

  static bool isPricingLabel(String label) {
    final l = label.toLowerCase();
    return l.contains('amount') ||
        l.contains('price') ||
        l.contains('harga') ||
        l.contains('budget') ||
        l.contains('tax') ||
        l.contains('disc') ||
        l.contains('total') ||
        l.contains('dpp') ||
        l.contains('ppn') ||
        l.contains('pph');
  }

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isNotEmpty ? value.trim() : '-';

    if (multiline || isDescriptionLabel(label) || display.length > 120) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              display,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? ApprovalTheme.primary.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? ApprovalTheme.primary.withOpacity(0.25)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              display,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: highlight ? 14 : 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: highlight ? ApprovalTheme.primary : Colors.grey.shade800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ApprovalInfoField> fields;

  const _ItemDetailSection({
    required this.title,
    required this.icon,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: ApprovalTheme.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              children: [
                for (final f in fields)
                  ApprovalDetailFieldRow(
                    label: f.label,
                    value: f.value,
                    highlight: f.label.toLowerCase() == 'amount',
                    multiline: ApprovalDetailFieldRow.isDescriptionLabel(f.label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _approvalFieldValue(
  List<ApprovalInfoField> fields, {
  required List<String> labels,
}) {
  for (final pattern in labels) {
    final p = pattern.toLowerCase();
    for (final f in fields) {
      final l = f.label.toLowerCase();
      if (l == p || l.contains(p)) {
        final v = f.value.trim();
        if (v.isNotEmpty && v != '-') return v;
      }
    }
  }
  return null;
}

bool _isSkippableTitleField(String label) {
  final l = label.toLowerCase();
  return l == 'amount' ||
      l == 'qty' ||
      l == 'unit' ||
      l == 'ccy' ||
      l.contains('price') ||
      l.contains('budget') ||
      l.contains('total') ||
      l.contains('tax');
}

({String title, String? subtitle}) approvalItemRowHeader(
    List<ApprovalInfoField> fields) {
  final title = _approvalFieldValue(fields, labels: [
    'item name',
    'account name',
    'item/acc name',
    'item/ acc name',
    'desc',
    'item',
    'document no',
    'invoice no',
    'type',
    'stockname',
  ]);

  String? fallbackTitle;
  for (final f in fields) {
    if (_isSkippableTitleField(f.label)) continue;
    final v = f.value.trim();
    if (v.isNotEmpty && v != '-') {
      fallbackTitle = v;
      break;
    }
  }

  final subtitle = _approvalFieldValue(fields, labels: [
    'project name',
    'item/ acc no',
    'item/acc no',
    'stockcode',
    'request by',
    'from mu no',
    'warehouse',
  ]);

  return (
    title: title ?? fallbackTitle ?? 'Item',
    subtitle: subtitle,
  );
}

void showApprovalItemDetail({
  required BuildContext context,
  required int index,
  required String title,
  required List<ApprovalInfoField> fields,
  String? subtitle,
}) {
  String? amountText;
  for (final f in fields) {
    final l = f.label.toLowerCase();
    if (l == 'amount' || l == 'total' || l == 'grand total') {
      amountText = f.value;
      break;
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height * 0.9;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ApprovalTheme.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ApprovalTheme.primary, ApprovalTheme.primaryDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: ApprovalTheme.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.35)),
                        ),
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item #$index',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            if (subtitle != null &&
                                subtitle.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (amountText != null && amountText.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 4, top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                              Text(
                                amountText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 22, color: Colors.white.withOpacity(0.9)),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  child: _ItemDetailSection(
                    title: 'Item Detail',
                    icon: Icons.list_alt_rounded,
                    fields: fields,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ─── Bottom bar ─────────────────────────────────────────────────────────────

class ApprovalDetailBottomBar extends StatelessWidget {
  final double totalPrice;
  final int itemCount;
  final String? selectedAction;
  final Color? actionColor;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final String idleHint;
  final String totalLabel;
  final bool quantityTotal;

  const ApprovalDetailBottomBar({
    super.key,
    required this.totalPrice,
    this.itemCount = 0,
    this.selectedAction,
    this.actionColor,
    this.submitLabel = 'Submit',
    this.onSubmit,
    this.idleHint = 'Select an action to continue',
    this.totalLabel = 'Total Amount',
    this.quantityTotal = false,
  });

  bool get _hasAction =>
      selectedAction != null &&
      selectedAction!.isNotEmpty &&
      onSubmit != null;

  @override
  Widget build(BuildContext context) {
    final color = actionColor ?? ApprovalTheme.primary;
    final fmt = ApprovalTheme.currencyFmt;
    final totalText = quantityTotal
        ? NumberFormat('#,##0.##').format(totalPrice)
        : fmt.format(totalPrice);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 2.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ApprovalTheme.primary, ApprovalTheme.primaryDark],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 4),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ApprovalTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.summarize_outlined,
                        size: 20, color: ApprovalTheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(totalLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500)),
                            if (itemCount > 0) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text('·',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11)),
                              ),
                              Text('$itemCount item${itemCount > 1 ? 's' : ''}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(totalText,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ApprovalTheme.primary,
                                height: 1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: _hasAction
                              ? Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 11, color: color),
                                    const SizedBox(width: 4),
                                    Text('Ready to $selectedAction',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: color)),
                                  ],
                                )
                              : Text(idleHint,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade400,
                                      fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_hasAction)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onSubmit,
                        borderRadius: BorderRadius.circular(10),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(submitLabel,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_outlined,
                              size: 15, color: Colors.grey.shade400),
                          const SizedBox(width: 5),
                          Text('Action',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail scaffold ────────────────────────────────────────────────────────

class ApprovalDetailScaffold extends StatelessWidget {
  final String docNo;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? infoPanel;
  final Widget? actionSection;
  final Widget body;
  final Widget bottomBar;

  const ApprovalDetailScaffold({
    super.key,
    required this.docNo,
    required this.subtitle,
    required this.onBack,
    this.infoPanel,
    this.actionSection,
    required this.body,
    required this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApprovalTheme.background,
      body: Column(
        children: [
          ApprovalCompactHeader(
            docNo: docNo,
            subtitle: subtitle,
            onBack: onBack,
          ),
          if (infoPanel != null) infoPanel!,
          if (actionSection != null) actionSection!,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: body,
            ),
          ),
          bottomBar,
        ],
      ),
    );
  }
}

// ─── List page widgets ──────────────────────────────────────────────────────

class ApprovalListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ApprovalListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ApprovalTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description_outlined,
                      size: 20, color: ApprovalTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: ApprovalTheme.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ApprovalListScaffold extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final Widget child;

  /// When set, replaces the default search field (e.g. search + action buttons).
  final Widget? searchSection;

  const ApprovalListScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.child,
    this.searchSection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApprovalTheme.background,
      body: Column(
        children: [
          ApprovalCompactHeader(
            docNo: title,
            subtitle: 'Approval List',
            onBack: onBack,
          ),
          Expanded(
            child: LiquidPullToRefresh(
              onRefresh: onRefresh,
              color: ApprovalTheme.primary,
              height: 120,
              showChildOpacityTransition: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  searchSection ??
                      TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search document no...',
                          hintStyle: TextStyle(
                              fontSize: 13, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.search,
                              color: ApprovalTheme.primary, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: ApprovalTheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Preset action sets ─────────────────────────────────────────────────────

class ApprovalActions {
  ApprovalActions._();

  static const confirmActions = [
    ApprovalActionMeta(
        label: 'Pending',
        icon: Icons.hourglass_empty_rounded,
        color: Color(0xFF9E9E9E)),
    ApprovalActionMeta(
        label: 'Confirm',
        icon: Icons.check_circle_outline_rounded,
        color: Color(0xFFF4A62A)),
    ApprovalActionMeta(
        label: 'Reject',
        icon: Icons.cancel_outlined,
        color: Color(0xFFE53935)),
    ApprovalActionMeta(
        label: 'Send To Draft',
        icon: Icons.edit_note_outlined,
        color: Color(0xFFFF9800)),
  ];

  static const approveActions = [
    ApprovalActionMeta(
        label: 'Approve',
        icon: Icons.check_circle_outline_rounded,
        color: Color(0xFFF4A62A)),
    ApprovalActionMeta(
        label: 'Reject',
        icon: Icons.cancel_outlined,
        color: Color(0xFFE53935)),
  ];

  static Color colorFor(String label, List<ApprovalActionMeta> actions) {
    for (final a in actions) {
      if (a.label == label) return a.color;
    }
    return ApprovalTheme.primary;
  }
}
