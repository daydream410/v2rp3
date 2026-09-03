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
import '../../BE/approval_notif_controller.dart';
import '../../BE/controller.dart';
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
  late final ApprovalNotifController _notif;
  late final Worker _sessionWorker;
  String idSelected = '0';

  @override
  void initState() {
    super.initState();
    _notif = Get.find<ApprovalNotifController>();
    _sessionWorker = ever(_notif.sessionExpired, (expired) {
      if (expired == true) autoLogout();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notif.load();
    });
  }

  @override
  void dispose() {
    _sessionWorker.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onPullRefresh() async {
    final started = DateTime.now();
    try {
      await _notif.forceRefresh();
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

  List<ApprovalMenuFilter> _categoryFilters(ApprovalNotifTotals t) => [
        for (final def in _filterDefs)
          ApprovalMenuFilter(
            id: def.id,
            label: def.label,
            icon: def.icon,
            badgeCount: t.pendingForCategory(def.id),
          ),
      ];

  bool _showsSection(String sectionId) =>
      idSelected == '0' || idSelected == sectionId;

  void _openIfHasData(int count, Widget Function() page) {
    if (count == 0) {
      wakwaw();
    } else {
      Get.to(() => page())?.then((_) {
        _notif.forceRefresh();
      });
    }
  }

  List<ApprovalMenuSectionData> _visibleSections(ApprovalNotifTotals t) {
    return [
      if (_showsSection('1')) _cashBankSection(t),
      if (_showsSection('2')) _salesSection(t),
      if (_showsSection('3')) _purchaseSection(t),
      if (_showsSection('4')) _inventorySection(t),
      if (_showsSection('5')) _ppcSection(t),
    ];
  }

  ApprovalMenuSectionData _cashBankSection(ApprovalNotifTotals t) =>
      ApprovalMenuSectionData(
        title: 'Cash & Bank',
        icon: Icons.account_balance_wallet_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'Cash Advance\nConfirmation',
            imageAsset: 'images/cashbankapp.png',
            count: t.totalKC,
            onTap: () => _openIfHasData(t.totalKC, () => CashAdvanceConfirm()),
          ),
          ApprovalMenuItemData(
            title: 'Cash Advance\nApproval',
            imageAsset: 'images/cashadvanceapp.png',
            count: t.totalKA,
            onTap: () => _openIfHasData(t.totalKA, () => CashAdvanceApproval()),
          ),
          ApprovalMenuItemData(
            title: 'C/A Settlement\nConfirmation',
            imageAsset: 'images/casettlement.png',
            count: t.totalLC,
            onTap: () => _openIfHasData(t.totalLC, () => CaSettleConfirm()),
          ),
          ApprovalMenuItemData(
            title: 'C/A Settlement\nApproval',
            imageAsset: 'images/casettlementapp.png',
            count: t.totalLA,
            onTap: () => _openIfHasData(t.totalLA, () => CaSetApproval()),
          ),
        ],
      );

  ApprovalMenuSectionData _salesSection(ApprovalNotifTotals t) =>
      ApprovalMenuSectionData(
        title: 'Sales',
        icon: Icons.point_of_sale_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'A/R Receipt\nApproval',
            imageAsset: 'images/arreceipt.png',
            count: t.totalARRA,
            onTap: () => _openIfHasData(t.totalARRA, () => ArApproval()),
          ),
          ApprovalMenuItemData(
            title: 'Sales Order\nApproval',
            imageAsset: 'images/salesapp.png',
            count: t.totalSOA,
            onTap: () => _openIfHasData(t.totalSOA, () => SalesOrderApproval()),
          ),
        ],
      );

  ApprovalMenuSectionData _purchaseSection(ApprovalNotifTotals t) =>
      ApprovalMenuSectionData(
        title: 'Purchase',
        icon: Icons.shopping_cart_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'SPPBJ\nConfirmation',
            imageAsset: 'images/sppbj.png',
            count: t.totalSC,
            onTap: () => _openIfHasData(t.totalSC, () => SppbjConfirm()),
          ),
          ApprovalMenuItemData(
            title: 'SPPBJ\nApproval',
            imageAsset: 'images/sppbjapp.png',
            count: t.totalSA,
            onTap: () => _openIfHasData(t.totalSA, () => SppbjApp()),
          ),
          ApprovalMenuItemData(
            title: 'PO SCM\nApproval',
            imageAsset: 'images/poscm.png',
            count: t.totalPA,
            onTap: () => _openIfHasData(t.totalPA, () => PoScmApp()),
          ),
          ApprovalMenuItemData(
            title: 'New Payable\nApproval',
            imageAsset: 'images/newpayable.png',
            count: t.totalNA,
            onTap: () => _openIfHasData(t.totalNA, () => NpApp()),
          ),
          ApprovalMenuItemData(
            title: 'DP Request\nApproval',
            imageAsset: 'images/dpreqapp.png',
            count: t.totalDPA,
            onTap: () => _openIfHasData(t.totalDPA, () => DpReqApp()),
          ),
          ApprovalMenuItemData(
            title: 'A/P Refund\nApproval',
            imageAsset: 'images/aprefund.png',
            count: t.totalAPRA,
            onTap: () => _openIfHasData(t.totalAPRA, () => ApRefundApp()),
          ),
          ApprovalMenuItemData(
            title: 'A/P Adjustment\nApproval',
            imageAsset: 'images/apadjustmentapp.png',
            count: t.totalAPAA,
            onTap: () => _openIfHasData(t.totalAPAA, () => ApAdjApp()),
          ),
          ApprovalMenuItemData(
            title: 'D/N Supplier\nApproval',
            imageAsset: 'images/dnsupplier.png',
            count: t.totalDNA,
            onTap: () => _openIfHasData(t.totalDNA, () => DebitNotesApp()),
          ),
          ApprovalMenuItemData(
            title: 'PO Exception\nApproval',
            imageAsset: 'images/poexception.png',
            count: t.poGabung,
            onTap: () => _openIfHasData(t.poGabung, () => PoExApp()),
          ),
          ApprovalMenuItemData(
            title: 'PO SCM Supplier\nUnapproved',
            imageAsset: 'images/supplier.png',
            count: t.supplierGabung,
            onTap: () => _openIfHasData(t.supplierGabung, () => PoUnapproved()),
          ),
        ],
      );

  ApprovalMenuSectionData _inventorySection(ApprovalNotifTotals t) =>
      ApprovalMenuSectionData(
        title: 'Inventory',
        icon: Icons.inventory_2_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'Material Use\nApproval',
            imageAsset: 'images/muapp.png',
            count: t.totalMUA,
            onTap: () => _openIfHasData(t.totalMUA, () => MuApp()),
          ),
          ApprovalMenuItemData(
            title: 'Goods Receive\nApproval',
            imageAsset: 'images/grapp.png',
            count: t.totalGRA,
            onTap: () => _openIfHasData(t.totalGRA, () => GrApp()),
          ),
          ApprovalMenuItemData(
            title: 'Internal Transfer\nApproval',
            imageAsset: 'images/itapp.png',
            count: t.totalITA,
            onTap: () => _openIfHasData(t.totalITA, () => ItApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Movement\nApproval',
            imageAsset: 'images/smapp.png',
            count: t.totalSMA,
            onTap: () => _openIfHasData(t.totalSMA, () => SmApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Adjustment\nApproval',
            imageAsset: 'images/stockadjapp.png',
            count: t.totalSAA,
            onTap: () => _openIfHasData(t.totalSAA, () => StockAdjApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Top Up\nApproval',
            imageAsset: 'images/stocktopup.png',
            count: t.totalSTUA,
            onTap: () => _openIfHasData(t.totalSTUA, () => StockTopupApp()),
          ),
          ApprovalMenuItemData(
            title: 'Assembling\nApproval',
            imageAsset: 'images/assembling.png',
            count: t.totalAA,
            onTap: () => _openIfHasData(t.totalAA, () => AssemblingApp()),
          ),
          ApprovalMenuItemData(
            title: 'Material Return\nApproval',
            imageAsset: 'images/materialreturnapp.png',
            count: t.totalMRA,
            onTap: () => _openIfHasData(t.totalMRA, () => MrApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Transfer\nApproval',
            imageAsset: 'images/stocktransferapp.png',
            count: t.totalSTA,
            onTap: () => _openIfHasData(t.totalSTA, () => StockTrfApp()),
          ),
          ApprovalMenuItemData(
            title: 'IT Stock Adj\nApproval',
            imageAsset: 'images/itstockadj.png',
            count: t.itGabung,
            onTap: () => _openIfHasData(t.itGabung, () => ItStockAdjApp()),
          ),
          ApprovalMenuItemData(
            title: 'Stock Price\nApproval',
            imageAsset: 'images/stockpriceapp.png',
            count: t.totalSPA,
            onTap: () => _openIfHasData(t.totalSPA, () => StockPriceApp()),
          ),
          ApprovalMenuItemData(
            title: 'Update Min/Max\nApproval',
            imageAsset: 'images/updateminmax.png',
            count: t.totalMMU,
            onTap: () => _openIfHasData(t.totalMMU, () => UpdateMinMaxApp()),
          ),
        ],
      );

  ApprovalMenuSectionData _ppcSection(ApprovalNotifTotals t) =>
      ApprovalMenuSectionData(
        title: 'PPC',
        icon: Icons.precision_manufacturing_outlined,
        items: [
          ApprovalMenuItemData(
            title: 'Work Order\nApproval',
            imageAsset: 'images/woapp.png',
            count: t.totalWoApp,
            onTap: () => _openIfHasData(t.totalWoApp, () => WoApp()),
          ),
          ApprovalMenuItemData(
            title: 'Work Order\nCompleted',
            imageAsset: 'images/wocomp.png',
            count: t.totalWoCompleted,
            onTap: () => _openIfHasData(t.totalWoCompleted, () => WoCompleted()),
          ),
        ],
      );

  void _onFilterSelected(String id) {
    setState(() => idSelected = id);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final totals = _notif.totals.value;
      final isInitialLoading = _notif.isInitialLoading.value;
      final sections = _visibleSections(totals);
      var totalPending = 0;
      for (final s in sections) {
        totalPending += s.totalPending;
      }

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
                filters: _categoryFilters(totals),
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
                                if (isInitialLoading)
                                  const ApprovalMenuSummarySkeleton()
                                else
                                  ApprovalMenuSummaryCard(
                                    totalPending: totalPending,
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
                        if (isInitialLoading)
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
    });
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
