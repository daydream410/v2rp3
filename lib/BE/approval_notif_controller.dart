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

class ApprovalNotifController extends GetxController {
  static const cacheTtl = Duration(minutes: 3);
  static const _timeoutDuration = Duration(minutes: 5);

  final totals = ApprovalNotifTotals.empty.obs;
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
      final items = raw is List ? raw : <dynamic>[];
      totals.value = ApprovalNotifTotals.fromItems(items);
      _fetchedAt = DateTime.now();
      sessionExpired.value = false;
    } catch (e) {
      // Keep previous totals on error when cache exists.
      if (!hasCache) totals.value = ApprovalNotifTotals.empty;
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
