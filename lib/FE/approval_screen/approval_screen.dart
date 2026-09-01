import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/approval_screen/cash_bank/cash_advance_confirm/ca_confirm.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/gr_approval/gr_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/it_approval/it_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/sm_approval/sm_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/stock_trf_approval/stocktrf_app.dart';
import 'package:v2rp3/FE/approval_screen/ppc_approval/wo_completed/we_completed.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/ap_adjustment/apadj_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/ap_refund/ap_refund.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/dn_approval/dn_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/dpreq_approval/dpreq_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/np_app/newap_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/po_ex_approval/poex_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/poscm_unapproved/poscm_unapproved.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/sppbj_approval/sppbj_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/sppbj_confirm/sppbj_confirm.dart';
import 'package:v2rp3/FE/approval_screen/sales_approval/ar_app/ar_app.dart';
import 'package:v2rp3/FE/approval_screen/sales_approval/sales_order_app/sales_order_app.dart';
import 'package:v2rp3/FE/shared/approval_menu_ui.dart';
import '../../BE/controller.dart';
import '../../BE/reqip.dart';
import '../../BE/resD.dart';
import '../../main.dart';
import '../mainScreen/login_screen4.dart';
import 'cash_bank/ca_set_approval/ca_set_app.dart';
import 'cash_bank/ca_set_confirm/ca_set_confirm.dart';
import 'cash_bank/cash_advance_approval/ca_app.dart';
import 'inventory_approval/assembling_approval/asmb_app.dart';
import 'inventory_approval/itstock_adj_approval/itstock_app.dart';
import 'inventory_approval/mr_approval/mr_app.dart';
import 'inventory_approval/mu_approval/mu_app.dart';
import 'inventory_approval/stock_topup_approval/topup_app.dart';
import 'inventory_approval/stockadj_approval/stockadj_app.dart';
import 'inventory_approval/stockprice_approval/stockprice_app.dart';
import 'inventory_approval/update_minmax_approval/minmax_app.dart';
import 'ppc_approval/wo_app/wo_app.dart';
import 'purchase_approval/po_scm_approval/poscm_app.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  static TextControllers textControllers = Get.put(TextControllers());

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final RefreshController _refreshController = RefreshController();
  Timer? _timeoutTimer;
  bool _isFetching = false;
  bool _isInitialLoading = true;
  bool _hasLoadedOnce = false;
  String idSelected = '0';
  int totalSC = 0;
  int totalSA = 0;
  int totalPA = 0;
  int totalPOE = 0;
  int totalPNE = 0;
  int totalKC = 0;
  int totalKA = 0;
  int totalKDA = 0;
  int totalKD = 0;
  int totalLC = 0;
  int totalLA = 0;
  int totalMUA = 0;
  int totalITA = 0;
  int totalMRA = 0;
  int totalGRA = 0;
  int totalSTA = 0;
  int totalSMA = 0;
  int totalSAA = 0;
  int totalSPA = 0;
  int totalMMU = 0;
  int totalSTUA = 0;
  int totalDNA = 0;
  int totalAPRA = 0;
  int totalDPA = 0;
  int totalSOA = 0;
  int totalAPAA = 0;
  int totalAA = 0;
  int totalNA = 0;
  int totalARRA = 0;
  int totalITSA = 0;
  int totalSTSA = 0;
  int poGabung = 0;
  int itGabung = 0;
  int totalPOS = 0;
  int totalPNS = 0;
  int supplierGabung = 0;
  int totalWoApp = 0;
  int totalWoCompleted = 0;

  static late List dataaa = <CaConfirmData>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          getDataa();
        } catch (e) {
          print('Error in getDataa: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _onPullRefresh() async {
    final started = DateTime.now();
    try {
      await getDataa2();
    } finally {
      final elapsed = DateTime.now().difference(started);
      const minDuration = Duration(milliseconds: 900);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      if (mounted) {
        _refreshController.refreshCompleted();
      }
    }
  }

  static const _filterDefs = [
    (id: '0', label: 'All', icon: Icons.grid_view_rounded),
    (id: '1', label: 'Cash & Bank', icon: Icons.account_balance_wallet_outlined),
    (id: '2', label: 'Sales', icon: Icons.point_of_sale_outlined),
    (id: '3', label: 'Purchase', icon: Icons.shopping_cart_outlined),
    (id: '4', label: 'Inventory', icon: Icons.inventory_2_outlined),
    (id: '5', label: 'PPC', icon: Icons.precision_manufacturing_outlined),
  ];

  int get _cashBankPending => totalKC + totalKA + totalLC + totalLA;

  int get _salesPending => totalARRA + totalSOA;

  int get _purchasePending =>
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

  int get _inventoryPending =>
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

  int get _ppcPending => totalWoApp + totalWoCompleted;

  int get _allPending =>
      _cashBankPending +
      _salesPending +
      _purchasePending +
      _inventoryPending +
      _ppcPending;

  int _pendingForCategory(String id) {
    switch (id) {
      case '1':
        return _cashBankPending;
      case '2':
        return _salesPending;
      case '3':
        return _purchasePending;
      case '4':
        return _inventoryPending;
      case '5':
        return _ppcPending;
      default:
        return _allPending;
    }
  }

  List<ApprovalMenuFilter> get _categoryFilters => [
        for (final def in _filterDefs)
          ApprovalMenuFilter(
            id: def.id,
            label: def.label,
            icon: def.icon,
            badgeCount: _pendingForCategory(def.id),
          ),
      ];

  bool _showsSection(String sectionId) =>
      idSelected == '0' || idSelected == sectionId;

  void _openIfHasData(int count, Widget Function() page) {
    if (count == 0) {
      wakwaw();
    } else {
      Get.to(() => page());
    }
  }

  int get _totalPending {
    var total = 0;
    for (final s in _visibleSections()) {
      total += s.totalPending;
    }
    return total;
  }

  List<ApprovalMenuSectionData> _visibleSections() {
    return [
      if (_showsSection('1')) _cashBankSection(),
      if (_showsSection('2')) _salesSection(),
      if (_showsSection('3')) _purchaseSection(),
      if (_showsSection('4')) _inventorySection(),
      if (_showsSection('5')) _ppcSection(),
    ];
  }

  ApprovalMenuSectionData _cashBankSection() => ApprovalMenuSectionData(
        title: 'Cash & Bank',
        icon: Icons.account_balance_wallet_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'Cash Advance\nConfirmation',
            imageAsset: 'images/cashbankapp.png',
            count: totalKC,
            onTap: () => _openIfHasData(totalKC, () => CashAdvanceConfirm()),
          ),
          ApprovalMenuItemData(
            title: 'Cash Advance\nApproval',
            imageAsset: 'images/cashadvanceapp.png',
            count: totalKA,
            onTap: () => _openIfHasData(totalKA, () => CashAdvanceApproval()),
          ),
          ApprovalMenuItemData(
            title: 'C/A Settlement\nConfirmation',
            imageAsset: 'images/casettlement.png',
            count: totalLC,
            onTap: () => _openIfHasData(totalLC, () => CaSettleConfirm()),
          ),
          ApprovalMenuItemData(
            title: 'C/A Settlement\nApproval',
            imageAsset: 'images/casettlementapp.png',
            count: totalLA,
            onTap: () => _openIfHasData(totalLA, () => CaSetApproval()),
          ),
        ],
      );

  ApprovalMenuSectionData _salesSection() => ApprovalMenuSectionData(
        title: 'Sales',
        icon: Icons.point_of_sale_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'A/R Receipt\nApproval',
            imageAsset: 'images/arreceipt.png',
            count: totalARRA,
            onTap: () => _openIfHasData(totalARRA, () => ArApproval()),
          ),
          ApprovalMenuItemData(
            title: 'Sales Order\nApproval',
            imageAsset: 'images/salesapp.png',
            count: totalSOA,
            onTap: () => _openIfHasData(totalSOA, () => SalesOrderApproval()),
          ),
        ],
      );

  ApprovalMenuSectionData _purchaseSection() => ApprovalMenuSectionData(
        title: 'Purchase',
        icon: Icons.shopping_cart_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'SPPBJ\nConfirmation',
            imageAsset: 'images/sppbj.png',
            count: totalSC,
            onTap: () => _openIfHasData(totalSC, () => SppbjConfirm()),
          ),
          ApprovalMenuItemData(
            title: 'SPPBJ\nApproval',
            imageAsset: 'images/sppbjapp.png',
            count: totalSA,
            onTap: () => _openIfHasData(totalSA, () => SppbjApp()),
          ),
          ApprovalMenuItemData(
            title: 'PO SCM\nApproval',
            imageAsset: 'images/poscm.png',
            count: totalPA,
            onTap: () => _openIfHasData(totalPA, () => PoScmApp()),
          ),
          ApprovalMenuItemData(
            title: 'New Payable\nApproval',
            imageAsset: 'images/newpayable.png',
            count: totalNA,
            onTap: () => _openIfHasData(totalNA, () => NpApp()),
          ),
          ApprovalMenuItemData(
            title: 'DP Request\nApproval',
            imageAsset: 'images/dpreqapp.png',
            count: totalDPA,
            onTap: () => _openIfHasData(totalDPA, () => DpReqApp()),
          ),
          ApprovalMenuItemData(
            title: 'A/P Refund\nApproval',
            imageAsset: 'images/aprefund.png',
            count: totalAPRA,
            onTap: () => _openIfHasData(totalAPRA, () => ApRefundApp()),
          ),
          ApprovalMenuItemData(
            title: 'A/P Adjustment\nApproval',
            imageAsset: 'images/apadjustmentapp.png',
            count: totalAPAA,
            onTap: () => _openIfHasData(totalAPAA, () => ApAdjApp()),
          ),
          ApprovalMenuItemData(
            title: 'D/N Supplier\nApproval',
            imageAsset: 'images/dnsupplier.png',
            count: totalDNA,
            onTap: () => _openIfHasData(totalDNA, () => DebitNotesApp()),
          ),
          ApprovalMenuItemData(
            title: 'PO Exception\nApproval',
            imageAsset: 'images/poexception.png',
            count: poGabung,
            onTap: () => _openIfHasData(poGabung, () => PoExApp()),
          ),
          ApprovalMenuItemData(
            title: 'PO SCM Supplier\nUnapproved',
            imageAsset: 'images/supplier.png',
            count: supplierGabung,
            onTap: () => _openIfHasData(supplierGabung, () => PoUnapproved()),
          ),
        ],
      );

  ApprovalMenuSectionData _inventorySection() => ApprovalMenuSectionData(
        title: 'Inventory',
        icon: Icons.inventory_2_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'Material Use\nApproval',
            imageAsset: 'images/muapp.png',
            count: totalMUA,
            onTap: () => _openIfHasData(totalMUA, () => MuApp()),
          ),
          ApprovalMenuItemData(
            title: 'Goods Receive\nApproval',
            imageAsset: 'images/grapp.png',
            count: totalGRA,
            onTap: () => _openIfHasData(totalGRA, () => GrApp()),
          ),
          ApprovalMenuItemData(
            title: 'Internal Transfer\nApproval',
            imageAsset: 'images/itapp.png',
            count: totalITA,
            onTap: () => _openIfHasData(totalITA, () => ItApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Movement\nApproval',
            imageAsset: 'images/smapp.png',
            count: totalSMA,
            onTap: () => _openIfHasData(totalSMA, () => SmApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Adjustment\nApproval',
            imageAsset: 'images/stockadjapp.png',
            count: totalSAA,
            onTap: () => _openIfHasData(totalSAA, () => StockAdjApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Top Up\nApproval',
            imageAsset: 'images/stocktopup.png',
            count: totalSTUA,
            onTap: () => _openIfHasData(totalSTUA, () => StockTopupApp()),
          ),
          ApprovalMenuItemData(
            title: 'Assembling\nApproval',
            imageAsset: 'images/assembling.png',
            count: totalAA,
            onTap: () => _openIfHasData(totalAA, () => AssemblingApp()),
          ),
          ApprovalMenuItemData(
            title: 'Material Return\nApproval',
            imageAsset: 'images/materialreturnapp.png',
            count: totalMRA,
            onTap: () => _openIfHasData(totalMRA, () => MrApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Transfer\nApproval',
            imageAsset: 'images/stocktransferapp.png',
            count: totalSTA,
            onTap: () => _openIfHasData(totalSTA, () => StockTrfApp()),
          ),
          ApprovalMenuItemData(
            title: 'IT Stock Adj\nApproval',
            imageAsset: 'images/itstockadj.png',
            count: itGabung,
            onTap: () => _openIfHasData(itGabung, () => ItStockAdjApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Price\nApproval',
            imageAsset: 'images/stockpriceapp.png',
            count: totalSPA,
            onTap: () => _openIfHasData(totalSPA, () => StockPriceApp()),
          ),
          ApprovalMenuItemData(
            title: 'Update Min/Max\nApproval',
            imageAsset: 'images/updateminmax.png',
            count: totalMMU,
            onTap: () => _openIfHasData(totalMMU, () => UpdateMinMaxApp()),
          ),
        ],
      );

  ApprovalMenuSectionData _ppcSection() => ApprovalMenuSectionData(
        title: 'PPC',
        icon: Icons.precision_manufacturing_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'Work Order\nApproval',
            imageAsset: 'images/woapp.png',
            count: totalWoApp,
            onTap: () => _openIfHasData(totalWoApp, () => WoApp()),
          ),
          ApprovalMenuItemData(
            title: 'Work Order\nCompleted',
            imageAsset: 'images/wocomp.png',
            count: totalWoCompleted,
            onTap: () => _openIfHasData(totalWoCompleted, () => WoCompleted()),
          ),
        ],
      );

  void _onFilterSelected(String id) {
    setState(() => idSelected = id);
  }

  @override
  Widget build(BuildContext context) {
    final sections = _visibleSections();
    return WillPopScope(
      onWillPop: () async {
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
        if (shouldPop == true) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: ApprovalMenuTheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: ApprovalMenuTheme.primary,
          title: const Text(
            'Approval Menu',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: ApprovalMenuTheme.primary,
              child: ApprovalMenuFilterBar(
                filters: _categoryFilters,
                selectedId: idSelected,
                onSelected: _onFilterSelected,
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: ApprovalMenuTheme.background,
                child: RefreshConfiguration(
                  headerTriggerDistance: 110,
                  dragSpeedRatio: 0.65,
                  springDescription: const SpringDescription(
                    mass: 2.2,
                    stiffness: 150,
                    damping: 16,
                  ),
                  child: SmartRefresher(
                    controller: _refreshController,
                    enablePullDown: true,
                    enablePullUp: false,
                    onRefresh: _onPullRefresh,
                    header: WaterDropMaterialHeader(
                      backgroundColor: Colors.white,
                      color: ApprovalMenuTheme.primary,
                      distance: 80,
                      offset: 12,
                    ),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: ColoredBox(
                            color: ApprovalMenuTheme.primary,
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                if (_isInitialLoading)
                                  const ApprovalMenuSummarySkeleton()
                                else
                                  ApprovalMenuSummaryCard(
                                    totalPending: _totalPending,
                                    sectionCount: sections.length,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            height: 16,
                            decoration: const BoxDecoration(
                              color: ApprovalMenuTheme.background,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        if (_isInitialLoading)
                          const SliverToBoxAdapter(
                            child: ApprovalMenuLoadingSkeleton(),
                          )
                        else if (sections.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: ColoredBox(
                              color: ApprovalMenuTheme.background,
                              child: _buildEmptyCategory(),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ApprovalMenuSectionCard(
                                section: sections[index],
                              ),
                              childCount: sections.length,
                            ),
                          ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: const ColoredBox(
                            color: ApprovalMenuTheme.background,
                            child: SizedBox.expand(),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCategory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Tidak ada menu pada kategori ini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getDataa() async {
    if (_isFetching) return;
    _isFetching = true;
    if (mounted && !_hasLoadedOnce) {
      setState(() {
        _isInitialLoading = true;
      });
    }
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && _isFetching) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Timeout',
          text:
              'Pengambilan data melebihi 5 menit. Silakan cek koneksi atau coba lagi.',
        );
      }
    });
    HttpOverrides.global = MyHttpOverrides();
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    var finalKulonuwun = sharedPreferences.getString('kulonuwun');
    var finalMonggo = sharedPreferences.getString('monggo');
    var kulonuwun = MsgHeader.kulonuwun;
    var monggo = MsgHeader.monggo;

    try {
      // http://156.67.217.113/api/v1/mobile
      var getData = await http.get(
        Uri.https('v2rp.net', '/api/v1/mobile/notif'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );

      final responseData = json.decode(getData.body);
      print("getdataaaa " + responseData.toString());
      if (mounted) {
        setState(() {
          dataaa = responseData['data'];
          // totalSC = dataaa.length;
        });
      }
      if (responseData['kode'] == '77') {
        autoLogout();
      }
      totalSC = 0;
      totalSA = 0;
      totalPA = 0;
      totalPOE = 0;
      totalPNE = 0;
      totalKC = 0;
      totalKA = 0;
      totalKDA = 0;
      totalKD = 0;
      totalLC = 0;
      totalLA = 0;
      totalMUA = 0;
      totalITA = 0;
      totalMRA = 0;
      totalGRA = 0;
      totalSTA = 0;
      totalSMA = 0;
      totalSAA = 0;
      totalSPA = 0;
      totalMMU = 0;
      totalSTUA = 0;
      totalDNA = 0;
      totalAPRA = 0;
      totalDPA = 0;
      totalSOA = 0;
      totalAPAA = 0;
      totalAA = 0;
      totalNA = 0;
      totalARRA = 0;
      totalITSA = 0;
      totalSTSA = 0;
      poGabung = 0;
      totalPOS = 0;
      totalPNS = 0;
      supplierGabung = 0;
      totalWoApp = 0;
      totalWoCompleted = 0;
      for (var item in dataaa) {
        if (item['tipe'] == 'SC') {
          totalSC += 1;
        } else if (item['tipe'] == 'SA') {
          totalSA += 1;
        } else if (item['tipe'] == 'PA') {
          totalPA += 1;
        } else if (item['tipe'] == 'POE') {
          totalPOE += 1;
        } else if (item['tipe'] == 'PNE') {
          totalPNE += 1;
        } else if (item['tipe'] == 'KC') {
          totalKC += 1;
        } else if (item['tipe'] == 'KA') {
          totalKA += 1;
        } else if (item['tipe'] == 'KDA') {
          totalKDA += 1;
        } else if (item['tipe'] == 'KD') {
          totalKD += 1;
        } else if (item['tipe'] == 'LC') {
          totalLC += 1;
        } else if (item['tipe'] == 'LA') {
          totalLA += 1;
        } else if (item['tipe'] == 'MUA') {
          totalMUA += 1;
        } else if (item['tipe'] == 'ITA') {
          totalITA += 1;
        } else if (item['tipe'] == 'MRA') {
          totalMRA += 1;
        } else if (item['tipe'] == 'GRA') {
          totalGRA += 1;
        } else if (item['tipe'] == 'STA') {
          totalSTA += 1;
        } else if (item['tipe'] == 'SMA') {
          totalSMA += 1;
        } else if (item['tipe'] == 'SAA') {
          totalSAA += 1;
        } else if (item['tipe'] == 'SPA') {
          totalSPA += 1;
        } else if (item['tipe'] == 'MMU') {
          totalMMU += 1;
        } else if (item['tipe'] == 'STUA') {
          totalSTUA += 1;
        } else if (item['tipe'] == 'DNA') {
          totalDNA += 1;
        } else if (item['tipe'] == 'APRA') {
          totalAPRA += 1;
        } else if (item['tipe'] == 'DPA') {
          totalDPA += 1;
        } else if (item['tipe'] == 'SOA') {
          totalSOA += 1;
        } else if (item['tipe'] == 'APAA') {
          totalAPAA += 1;
        } else if (item['tipe'] == 'AA') {
          totalAA += 1;
        } else if (item['tipe'] == 'NA') {
          totalNA += 1;
        } else if (item['tipe'] == 'ARRA') {
          totalARRA += 1;
        } else if (item['tipe'] == 'ITSA') {
          totalITSA += 1;
        } else if (item['tipe'] == 'STSA') {
          totalSTSA += 1;
        } else if (item['tipe'] == 'POS') {
          totalPOS += 1;
        } else if (item['tipe'] == 'PNS') {
          totalPNS += 1;
        } else if (item['tipe'] == 'WOA') {
          totalWoApp += 1;
        } else if (item['tipe'] == 'WOU') {
          totalWoCompleted += 1;
        }
      }
      poGabung = totalPOE + totalPNE;
      itGabung = totalITSA + totalSTSA;
      supplierGabung = totalPOS + totalPNS;
      // print("totalPOS = " + totalPOS.toString());
      // print("totalPNS = " + totalPNS.toString());
      // print("supplierGabung = " + supplierGabung.toString());
    } catch (e) {
      print(e);
    } finally {
      _timeoutTimer?.cancel();
      _isFetching = false;
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _hasLoadedOnce = true;
        });
      }
    }
  }

  Future<void> getDataa2() async {
    if (_isFetching) return;
    _isFetching = true;
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && _isFetching) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Timeout',
          text:
              'Pengambilan data melebihi 5 menit. Silakan cek koneksi atau coba lagi.',
        );
      }
    });
    HttpOverrides.global = MyHttpOverrides();
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    var finalKulonuwun = sharedPreferences.getString('kulonuwun');
    var finalMonggo = sharedPreferences.getString('monggo');
    var kulonuwun = MsgHeader.kulonuwun;
    var monggo = MsgHeader.monggo;

    try {
      // http://156.67.217.113/api/v1/mobile
      var getData = await http.get(
        Uri.https('v2rp.net', '/api/v1/mobile/notif'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );

      final responseData = json.decode(getData.body);
      print("getdataaaa " + responseData.toString());
      if (mounted) {
        setState(() {
          dataaa = responseData['data'];
          // totalSC = dataaa.length;
        });
      }
      if (responseData['kode'] == '77') {
        autoLogout();
      }
      totalSC = 0;
      totalSA = 0;
      totalPA = 0;
      totalPOE = 0;
      totalPNE = 0;
      totalKC = 0;
      totalKA = 0;
      totalKDA = 0;
      totalKD = 0;
      totalLC = 0;
      totalLA = 0;
      totalMUA = 0;
      totalITA = 0;
      totalMRA = 0;
      totalGRA = 0;
      totalSTA = 0;
      totalSMA = 0;
      totalSAA = 0;
      totalSPA = 0;
      totalMMU = 0;
      totalSTUA = 0;
      totalDNA = 0;
      totalAPRA = 0;
      totalDPA = 0;
      totalSOA = 0;
      totalAPAA = 0;
      totalAA = 0;
      totalNA = 0;
      totalARRA = 0;
      totalITSA = 0;
      totalSTSA = 0;
      poGabung = 0;
      totalPOS = 0;
      totalPNS = 0;
      supplierGabung = 0;
      totalWoApp = 0;
      totalWoCompleted = 0;
      for (var item in dataaa) {
        if (item['tipe'] == 'SC') {
          totalSC += 1;
        } else if (item['tipe'] == 'SA') {
          totalSA += 1;
        } else if (item['tipe'] == 'PA') {
          totalPA += 1;
        } else if (item['tipe'] == 'POE') {
          totalPOE += 1;
        } else if (item['tipe'] == 'PNE') {
          totalPNE += 1;
        } else if (item['tipe'] == 'KC') {
          totalKC += 1;
        } else if (item['tipe'] == 'KA') {
          totalKA += 1;
        } else if (item['tipe'] == 'KDA') {
          totalKDA += 1;
        } else if (item['tipe'] == 'KD') {
          totalKD += 1;
        } else if (item['tipe'] == 'LC') {
          totalLC += 1;
        } else if (item['tipe'] == 'LA') {
          totalLA += 1;
        } else if (item['tipe'] == 'MUA') {
          totalMUA += 1;
        } else if (item['tipe'] == 'ITA') {
          totalITA += 1;
        } else if (item['tipe'] == 'MRA') {
          totalMRA += 1;
        } else if (item['tipe'] == 'GRA') {
          totalGRA += 1;
        } else if (item['tipe'] == 'STA') {
          totalSTA += 1;
        } else if (item['tipe'] == 'SMA') {
          totalSMA += 1;
        } else if (item['tipe'] == 'SAA') {
          totalSAA += 1;
        } else if (item['tipe'] == 'SPA') {
          totalSPA += 1;
        } else if (item['tipe'] == 'MMU') {
          totalMMU += 1;
        } else if (item['tipe'] == 'STUA') {
          totalSTUA += 1;
        } else if (item['tipe'] == 'DNA') {
          totalDNA += 1;
        } else if (item['tipe'] == 'APRA') {
          totalAPRA += 1;
        } else if (item['tipe'] == 'DPA') {
          totalDPA += 1;
        } else if (item['tipe'] == 'SOA') {
          totalSOA += 1;
        } else if (item['tipe'] == 'APAA') {
          totalAPAA += 1;
        } else if (item['tipe'] == 'AA') {
          totalAA += 1;
        } else if (item['tipe'] == 'NA') {
          totalNA += 1;
        } else if (item['tipe'] == 'ARRA') {
          totalARRA += 1;
        } else if (item['tipe'] == 'ITSA') {
          totalITSA += 1;
        } else if (item['tipe'] == 'STSA') {
          totalSTSA += 1;
        } else if (item['tipe'] == 'POS') {
          totalPOS += 1;
        } else if (item['tipe'] == 'PNS') {
          totalPNS += 1;
        } else if (item['tipe'] == 'WOA') {
          totalWoApp += 1;
        } else if (item['tipe'] == 'WOU') {
          totalWoCompleted += 1;
        }
      }
      poGabung = totalPOE + totalPNE;
      itGabung = totalITSA + totalSTSA;
      supplierGabung = totalPOS + totalPNS;
      // print("totalPOS = " + totalPOS.toString());
      // print("totalPNS = " + totalPNS.toString());
      // print("supplierGabung = " + supplierGabung.toString());
    } catch (e) {
      print(e);
    } finally {
      _timeoutTimer?.cancel();
      _isFetching = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future autoLogout() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    sharedPreferences.remove('username');
    sharedPreferences.remove('email');
    sharedPreferences.remove('password');
    sharedPreferences.remove('kulonuwun');
    sharedPreferences.remove('monggo');
    await sharedPreferences.clear();
    Get.offAll(() => const LoginPage4());
    Get.snackbar(
      "Session Time Out",
      "Please Re-login",
      colorText: Colors.white,
      icon: const Icon(
        Icons.logout,
        color: Colors.white,
      ),
      backgroundColor: Colors.red,
      isDismissible: true,
      dismissDirection: DismissDirection.vertical,
    );
  }

  Future wakwaw() async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      text: 'No Approval Data',
      barrierDismissible: false,
      confirmBtnText: 'Okay',
    );
  }
}
