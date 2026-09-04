import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'reqip.dart';
import '../main.dart';

/// Pending counts per approval type from `/api/v1/mobile/notif`.
class ApprovalNotifTotals {
  final int totalSC;
  final int totalSA;
  final int totalPA;
  final int totalPOE;
  final int totalPNE;
  final int totalKC;
  final int totalKA;
  final int totalKDA;
  final int totalKD;
  final int totalLC;
  final int totalLA;
  final int totalMUA;
  final int totalITA;
  final int totalMRA;
  final int totalGRA;
  final int totalSTA;
  final int totalSMA;
  final int totalSAA;
  final int totalSPA;
  final int totalMMU;
  final int totalSTUA;
  final int totalDNA;
  final int totalAPRA;
  final int totalDPA;
  final int totalSOA;
  final int totalAPAA;
  final int totalAA;
  final int totalNA;
  final int totalARRA;
  final int totalITSA;
  final int totalSTSA;
  final int totalPOS;
  final int totalPNS;
  final int totalWoApp;
  final int totalWoCompleted;

  const ApprovalNotifTotals({
    this.totalSC = 0,
    this.totalSA = 0,
    this.totalPA = 0,
    this.totalPOE = 0,
    this.totalPNE = 0,
    this.totalKC = 0,
    this.totalKA = 0,
    this.totalKDA = 0,
    this.totalKD = 0,
    this.totalLC = 0,
    this.totalLA = 0,
    this.totalMUA = 0,
    this.totalITA = 0,
    this.totalMRA = 0,
    this.totalGRA = 0,
    this.totalSTA = 0,
    this.totalSMA = 0,
    this.totalSAA = 0,
    this.totalSPA = 0,
    this.totalMMU = 0,
    this.totalSTUA = 0,
    this.totalDNA = 0,
    this.totalAPRA = 0,
    this.totalDPA = 0,
    this.totalSOA = 0,
    this.totalAPAA = 0,
    this.totalAA = 0,
    this.totalNA = 0,
    this.totalARRA = 0,
    this.totalITSA = 0,
    this.totalSTSA = 0,
    this.totalPOS = 0,
    this.totalPNS = 0,
    this.totalWoApp = 0,
    this.totalWoCompleted = 0,
  });

  static const empty = ApprovalNotifTotals();

  int get poGabung => totalPOE + totalPNE;

  int get itGabung => totalITSA + totalSTSA;

  int get supplierGabung => totalPOS + totalPNS;

  int get cashBankPending => totalKC + totalKA + totalLC + totalLA;

  int get salesPending => totalARRA + totalSOA;

  int get purchasePending =>
      totalSC +
      totalSA +
      totalPA +
      totalNA +
      totalDPA +
      totalAPRA +
      totalAPAA +
      totalDNA +
      poGabung +
      supplierGabung;

  int get inventoryPending =>
      totalMUA +
      totalGRA +
      totalITA +
      totalSMA +
      totalSAA +
      totalSTUA +
      totalAA +
      totalMRA +
      totalSTA +
      itGabung +
      totalSPA +
      totalMMU;

  int get ppcPending => totalWoApp + totalWoCompleted;

  int get allPending =>
      cashBankPending +
      salesPending +
      purchasePending +
      inventoryPending +
      ppcPending;

  int pendingForCategory(String id) {
    switch (id) {
      case '1':
        return cashBankPending;
      case '2':
        return salesPending;
      case '3':
        return purchasePending;
      case '4':
        return inventoryPending;
      case '5':
        return ppcPending;
      default:
        return allPending;
    }
  }

  static ApprovalNotifTotals fromItems(List<dynamic> items) {
    final counts = <String, int>{};
    for (final item in items) {
      if (item is! Map) continue;
      final tipe = item['tipe']?.toString();
      if (tipe == null || tipe.isEmpty) continue;
      counts[tipe] = (counts[tipe] ?? 0) + 1;
    }

    int c(String key) => counts[key] ?? 0;

    return ApprovalNotifTotals(
      totalSC: c('SC'),
      totalSA: c('SA'),
      totalPA: c('PA'),
      totalPOE: c('POE'),
      totalPNE: c('PNE'),
      totalKC: c('KC'),
      totalKA: c('KA'),
      totalKDA: c('KDA'),
      totalKD: c('KD'),
      totalLC: c('LC'),
      totalLA: c('LA'),
      totalMUA: c('MUA'),
      totalITA: c('ITA'),
      totalMRA: c('MRA'),
      totalGRA: c('GRA'),
      totalSTA: c('STA'),
      totalSMA: c('SMA'),
      totalSAA: c('SAA'),
      totalSPA: c('SPA'),
      totalMMU: c('MMU'),
      totalSTUA: c('STUA'),
      totalDNA: c('DNA'),
      totalAPRA: c('APRA'),
      totalDPA: c('DPA'),
      totalSOA: c('SOA'),
      totalAPAA: c('APAA'),
      totalAA: c('AA'),
      totalNA: c('NA'),
      totalARRA: c('ARRA'),
      totalITSA: c('ITSA'),
      totalSTSA: c('STSA'),
      totalPOS: c('POS'),
      totalPNS: c('PNS'),
      totalWoApp: c('WOA'),
      totalWoCompleted: c('WOU'),
    );
  }
}

/// One approval menu that still needs action for a company/role.
class ApprovalPendingMenu {
  final String label;
  final int count;

  const ApprovalPendingMenu({required this.label, required this.count});
}

/// Pending total + menu breakdown for company picker badges.
class ApprovalPendingSummary {
  final int total;
  final List<ApprovalPendingMenu> menus;

  const ApprovalPendingSummary({
    required this.total,
    this.menus = const [],
  });

  static const empty = ApprovalPendingSummary(total: 0);

  bool get hasPending => total > 0;

  factory ApprovalPendingSummary.fromTotals(ApprovalNotifTotals t) {
    final menus = <ApprovalPendingMenu>[
      if (t.totalKC > 0)
        ApprovalPendingMenu(label: 'CA Confirm', count: t.totalKC),
      if (t.totalKA > 0)
        ApprovalPendingMenu(label: 'CA Approval', count: t.totalKA),
      if (t.totalLC > 0)
        ApprovalPendingMenu(label: 'CA Set Confirm', count: t.totalLC),
      if (t.totalLA > 0)
        ApprovalPendingMenu(label: 'CA Set Approval', count: t.totalLA),
      if (t.totalARRA > 0)
        ApprovalPendingMenu(label: 'AR', count: t.totalARRA),
      if (t.totalSOA > 0)
        ApprovalPendingMenu(label: 'Sales Order', count: t.totalSOA),
      if (t.totalSC > 0)
        ApprovalPendingMenu(label: 'SPPBJ Confirm', count: t.totalSC),
      if (t.totalSA > 0)
        ApprovalPendingMenu(label: 'SPPBJ', count: t.totalSA),
      if (t.totalPA > 0)
        ApprovalPendingMenu(label: 'AP', count: t.totalPA),
      if (t.totalNA > 0)
        ApprovalPendingMenu(label: 'New AP', count: t.totalNA),
      if (t.totalDPA > 0)
        ApprovalPendingMenu(label: 'DP Req', count: t.totalDPA),
      if (t.totalAPRA > 0)
        ApprovalPendingMenu(label: 'AP Refund', count: t.totalAPRA),
      if (t.totalAPAA > 0)
        ApprovalPendingMenu(label: 'AP Adj', count: t.totalAPAA),
      if (t.totalDNA > 0)
        ApprovalPendingMenu(label: 'Debit Note', count: t.totalDNA),
      if (t.poGabung > 0)
        ApprovalPendingMenu(label: 'PO Exception', count: t.poGabung),
      if (t.supplierGabung > 0)
        ApprovalPendingMenu(label: 'PO SCM', count: t.supplierGabung),
      if (t.totalMUA > 0)
        ApprovalPendingMenu(label: 'MU', count: t.totalMUA),
      if (t.totalGRA > 0)
        ApprovalPendingMenu(label: 'GR', count: t.totalGRA),
      if (t.totalITA > 0)
        ApprovalPendingMenu(label: 'IT', count: t.totalITA),
      if (t.totalSMA > 0)
        ApprovalPendingMenu(label: 'Stock Move', count: t.totalSMA),
      if (t.totalSAA > 0)
        ApprovalPendingMenu(label: 'Stock Adj', count: t.totalSAA),
      if (t.totalSTUA > 0)
        ApprovalPendingMenu(label: 'Stock Topup', count: t.totalSTUA),
      if (t.totalAA > 0)
        ApprovalPendingMenu(label: 'Assembling', count: t.totalAA),
      if (t.totalMRA > 0)
        ApprovalPendingMenu(label: 'MR', count: t.totalMRA),
      if (t.totalSTA > 0)
        ApprovalPendingMenu(label: 'Stock Transfer', count: t.totalSTA),
      if (t.itGabung > 0)
        ApprovalPendingMenu(label: 'IT Stock Adj', count: t.itGabung),
      if (t.totalSPA > 0)
        ApprovalPendingMenu(label: 'Stock Price', count: t.totalSPA),
      if (t.totalMMU > 0)
        ApprovalPendingMenu(label: 'Min/Max', count: t.totalMMU),
      if (t.totalWoApp > 0)
        ApprovalPendingMenu(label: 'WO Approval', count: t.totalWoApp),
      if (t.totalWoCompleted > 0)
        ApprovalPendingMenu(label: 'WO Completed', count: t.totalWoCompleted),
    ]..sort((a, b) => b.count.compareTo(a.count));

    return ApprovalPendingSummary(total: t.allPending, menus: menus);
  }

  factory ApprovalPendingSummary.fromItems(List<dynamic> items) {
    return ApprovalPendingSummary.fromTotals(
      ApprovalNotifTotals.fromItems(items),
    );
  }
}

class ApprovalNotifController extends GetxController {
  static const cacheTtl = Duration(minutes: 3);
  static const _timeoutDuration = Duration(minutes: 5);

  final totals = ApprovalNotifTotals.empty.obs;
  /// Raw pending transactions from `/api/v1/mobile/notif` for the active company.
  final items = <Map<String, dynamic>>[].obs;
  final isInitialLoading = true.obs;
  final isRefreshing = false.obs;
  final sessionExpired = false.obs;

  DateTime? _fetchedAt;
  bool _isFetching = false;
  Timer? _timeoutTimer;

  bool get hasCache => _fetchedAt != null;

  bool get isCacheFresh {
    if (_fetchedAt == null) return false;
    return DateTime.now().difference(_fetchedAt!) < cacheTtl;
  }

  @override
  void onClose() {
    _timeoutTimer?.cancel();
    super.onClose();
  }

  void invalidate() {
    _fetchedAt = null;
  }

  /// Clears cached counts/items so the next load uses the new company session.
  void resetForNewCompanySession() {
    _timeoutTimer?.cancel();
    _isFetching = false;
    _fetchedAt = null;
    totals.value = ApprovalNotifTotals.empty;
    items.clear();
    sessionExpired.value = false;
    isInitialLoading.value = true;
    isRefreshing.value = false;
  }

  List<Map<String, dynamic>> itemsForType(String tipe) {
    final key = tipe.toUpperCase();
    return items
        .where((e) => (e['tipe']?.toString() ?? '').toUpperCase() == key)
        .toList(growable: false);
  }

  /// Loads notification counts. Returns true when session expired (kode 77).
  /// Skips network when cache is still fresh unless [force] is true.
  Future<bool> load({bool force = false}) async {
    if (_isFetching) return sessionExpired.value;
    if (!force && isCacheFresh) return sessionExpired.value;

    _isFetching = true;
    if (!hasCache) {
      isInitialLoading.value = true;
    } else {
      isRefreshing.value = true;
    }

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_timeoutDuration, () {
      if (_isFetching) {
        // Timeout handled by caller via isRefreshing staying true too long;
        // fetch will complete or fail separately.
      }
    });

    var expired = false;
    try {
      HttpOverrides.global = MyHttpOverrides();
      final sharedPreferences = await SharedPreferences.getInstance();
      final finalKulonuwun = sharedPreferences.getString('kulonuwun');
      final finalMonggo = sharedPreferences.getString('monggo');
      final kulonuwun = MsgHeader.kulonuwun;
      final monggo = MsgHeader.monggo;

      final response = await http.get(
        Uri.https('v2rp.net', '/api/v1/mobile/notif'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );

      final responseData = json.decode(response.body);
      if (responseData['kode']?.toString() == '77') {
        expired = true;
        sessionExpired.value = true;
        return true;
      }

      final raw = responseData['data'];
      final parsed = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            parsed.add(item);
          } else if (item is Map) {
            parsed.add(Map<String, dynamic>.from(item));
          }
        }
      }
      items.assignAll(parsed);
      totals.value = ApprovalNotifTotals.fromItems(parsed);
      _fetchedAt = DateTime.now();
      sessionExpired.value = false;
    } catch (e) {
      // Keep previous totals on error when cache exists.
      if (!hasCache) {
        totals.value = ApprovalNotifTotals.empty;
        items.clear();
      }
    } finally {
      _timeoutTimer?.cancel();
      _isFetching = false;
      isInitialLoading.value = false;
      isRefreshing.value = false;
    }
    return expired;
  }

  Future<bool> forceRefresh() => load(force: true);
}

/// Refreshes approval menu badge counts after approve/reject or returning from a submenu.
Future<void> approvalRefreshMenuCounts() async {
  if (Get.isRegistered<ApprovalNotifController>()) {
    await Get.find<ApprovalNotifController>().forceRefresh();
  }
}

/// After choose/change company: clear old-company cache and fetch pending list
/// for the new session tokens already stored in SharedPreferences / MsgHeader.
Future<void> approvalReloadAfterCompanyChange() async {
  if (!Get.isRegistered<ApprovalNotifController>()) {
    Get.put(ApprovalNotifController(), permanent: true);
  }
  final controller = Get.find<ApprovalNotifController>();
  controller.resetForNewCompanySession();
  await controller.forceRefresh();
}

/// Counts pending approval items for a temporary session (no SharedPreferences write).
Future<ApprovalPendingSummary> approvalFetchPendingSummary({
  required String kulonuwun,
  required String monggo,
}) async {
  try {
    HttpOverrides.global = MyHttpOverrides();
    final response = await http.get(
      Uri.https('v2rp.net', '/api/v1/mobile/notif'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'kulonuwun': kulonuwun,
        'monggo': monggo,
      },
    );
    final responseData = json.decode(response.body);
    if (responseData['kode']?.toString() == '77') {
      return ApprovalPendingSummary.empty;
    }
    final raw = responseData['data'];
    if (raw is! List) return ApprovalPendingSummary.empty;
    return ApprovalPendingSummary.fromItems(raw);
  } catch (_) {
    return ApprovalPendingSummary.empty;
  }
}

@Deprecated('Use approvalFetchPendingSummary')
Future<int> approvalFetchPendingCount({
  required String kulonuwun,
  required String monggo,
}) async {
  return (await approvalFetchPendingSummary(
    kulonuwun: kulonuwun,
    monggo: monggo,
  ))
      .total;
}

/// Probes each role via choose/role (without persisting), hits `/notif`, then
/// restores the previous session tokens. Returns map of seckey → pending summary.
///
/// Prefer [fcmToken] when available so choose/role succeeds; session is restored
/// afterward so the active company is not left as the last probed role.
Future<Map<String, ApprovalPendingSummary>> approvalProbePendingCountsForRoles(
  List<Map<String, dynamic>> roles, {
  String fcmToken = '',
  void Function(String seckey, ApprovalPendingSummary summary)? onSummary,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final originalKulonuwun = prefs.getString('kulonuwun');
  final originalMonggo = prefs.getString('monggo');
  final originalHeaderK = MsgHeader.kulonuwun;
  final originalHeaderM = MsgHeader.monggo;
  final platform = Platform.isAndroid ? 'android' : 'ios';
  final summaries = <String, ApprovalPendingSummary>{};

  print(
      'ℹ️ [FCM:PROBE] Probing ${roles.length} roles (token present: ${fcmToken.isNotEmpty})');

  try {
    for (final role in roles) {
      final seckey = role['seckey']?.toString() ?? '';
      if (seckey.isEmpty) continue;
      try {
        // Backend returns 400 if fcmtoken is omitted. Send the real token so
        // /notif can be queried, then re-bind it to the active company in
        // finally so the last probed role does not keep iOS push.
        await MsgHeader.chooseRole(
          seckey,
          fcmToken,
          platform,
          persist: false,
          registerFcm: fcmToken.isNotEmpty,
        );
        if (MsgHeader.roleSuccess != true) {
          summaries[seckey] = ApprovalPendingSummary.empty;
          onSummary?.call(seckey, ApprovalPendingSummary.empty);
          continue;
        }
        final kulonuwun = MsgHeader.kulonuwun?.toString() ?? '';
        final monggo = MsgHeader.monggo?.toString() ?? '';
        final summary = (kulonuwun.isEmpty || monggo.isEmpty)
            ? ApprovalPendingSummary.empty
            : await approvalFetchPendingSummary(
                kulonuwun: kulonuwun,
                monggo: monggo,
              );
        summaries[seckey] = summary;
        onSummary?.call(seckey, summary);
      } catch (_) {
        summaries[seckey] = ApprovalPendingSummary.empty;
        onSummary?.call(seckey, ApprovalPendingSummary.empty);
      }
    }
  } finally {
    final currentKulonuwun = prefs.getString('kulonuwun');
    final sessionChangedDuringProbe = currentKulonuwun != null &&
        currentKulonuwun.isNotEmpty &&
        currentKulonuwun != originalKulonuwun;
    if (sessionChangedDuringProbe) {
      print(
          'ℹ️ [FCM:PROBE] Session changed during probe — keeping the newly selected company');
    } else if (originalKulonuwun != null &&
        originalKulonuwun.isNotEmpty &&
        originalMonggo != null &&
        originalMonggo.isNotEmpty) {
      await prefs.setString('kulonuwun', originalKulonuwun);
      await prefs.setString('monggo', originalMonggo);
      MsgHeader.kulonuwun = originalKulonuwun;
      MsgHeader.monggo = originalMonggo;
    } else {
      await prefs.remove('kulonuwun');
      await prefs.remove('monggo');
      MsgHeader.kulonuwun = originalHeaderK ?? '';
      MsgHeader.monggo = originalHeaderM ?? '';
    }

    if (fcmToken.isNotEmpty) {
      await MsgHeader.syncFcmToken(fcmToken);
    }
  }

  return summaries;
}
