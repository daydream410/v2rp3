import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/it_approval/it_app.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:v2rp3/BE/controller.dart';
import 'package:v2rp3/routes/api_name.dart';

import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import '../../../../main.dart';

class ItApp2 extends StatefulWidget {
  final seckey;
  final reffno;
  final tanggal;
  final requestor;
  final towh;

  ItApp2({
    Key? key,
    required this.seckey,
    required this.reffno,
    required this.tanggal,
    required this.requestor,
    required this.towh,
  }) : super(key: key);

  @override
  State<ItApp2> createState() => _ItApp2State();
}

class _ItApp2State extends State<ItApp2> {
  var currentDate = "Estimate Arrival Date ";
  List<dynamic> dataaa = [];

  late Future dataFuture;

  @override
  void initState() {
    super.initState();
    dataaa = [];
    totalPrice = 0;
    dataFuture = getDataa();
  }

  var valueChooseRequest = "";
  var valueStatus = "";
  var updstatus = "0";
  double totalPrice = 0;
  bool isVisible = false;
  String reasonValue = '';
  static TextControllers textControllers = Get.put(TextControllers());

  double get _detailTotal => approvalSumLineAmount(
        dataaa.whereType<Map<dynamic, dynamic>>(),
      );

  static const _statusActions = [
    ApprovalActionMeta(label: 'Pending', icon: Icons.hourglass_empty_rounded, color: Color(0xFF9E9E9E)),
    ApprovalActionMeta(label: 'Deliver', icon: Icons.local_shipping_outlined, color: Color(0xFFF4A62A)),
    ApprovalActionMeta(label: 'Reject', icon: Icons.cancel_outlined, color: Color(0xFFE53935)),
    ApprovalActionMeta(label: 'Received', icon: Icons.inventory_2_outlined, color: Color(0xFF43A047)),
  ];

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  void _onStatusSelected(String status) {
    setState(() {
      valueStatus = status;
      if (status == "Pending") { updstatus = "0"; isVisible = false; }
      else if (status == "Deliver") { updstatus = "1"; isVisible = true; }
      else if (status == "Reject") { updstatus = "-1"; isVisible = true; }
      else if (status == "Received") { updstatus = "2"; isVisible = true; }
    });
  }
  List<ApprovalInfoField> _itemDetailFields(dynamic e) {
    final amount = approvalLineAmount(e as Map);
    return [
      ApprovalInfoField('SPPBJ No', (e['sppbjno'] ?? '').toString()),
      ApprovalInfoField('Project ID', (e['projectid'] ?? '').toString()),
      ApprovalInfoField('Stock ID', (e['stockcode'] ?? '').toString()),
      ApprovalInfoField('Description', (e['ket'] ?? '').toString()),
      ApprovalInfoField('Unit', (e['unit'] ?? '').toString()),
      ApprovalInfoField('From WH', (e['warehouse'] ?? '').toString()),
      ApprovalInfoField('QTY Req', (e['qty'].toString())),
      ApprovalInfoField('QTY Deliver', (e['qtyrcvd'].toString())),
      ApprovalInfoField('Price', ApprovalTheme.currencyFmt.format(approvalToDouble(e['harga']))),
      ApprovalInfoField('Amount', ApprovalTheme.currencyFmt.format(amount)),
      ApprovalInfoField('Remarks', (e['rem'] ?? '').toString()),
    ];
  }
  Widget _buildBody() {
    return FutureBuilder(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error Loading Data', style: TextStyle(color: Colors.grey.shade500)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: ApprovalTheme.primary));
        }
        return ApprovalDetailItemsColumn(
          count: dataaa.length,
          tableRows: [
            for (var i = 0; i < dataaa.length; i++)
              _itemDetailFields(dataaa[i]),
          ],
          children: const [],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = isVisible && valueStatus.isNotEmpty;
    return WillPopScope(
      onWillPop: () async {
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
      },
      child: ApprovalDetailScaffold(
        docNo: widget.reffno ?? '',
        subtitle: _formattedDate,
        onBack: () => Get.to(() => ItApp()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.requestor ?? '-',
          fields: [
            ApprovalInfoField('Request By', widget.requestor ?? '-'),
            ApprovalInfoField('To WH', widget.towh ?? '-'),
          ],
        ),
        actionSection: ApprovalActionGrid(actions: _statusActions, selectedLabel: valueStatus, onSelected: _onStatusSelected),
        body: _buildBody(),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: _detailTotal, itemCount: dataaa.length,
          selectedAction: hasAction ? valueStatus : null,
          actionColor: hasAction ? ApprovalTheme.primary : null,
          idleHint: 'Select an action to continue',
          onSubmit: hasAction ? () { if (updstatus == '-1') { reason(); } else { sendConfirm(); } } : null,
        ),
      ),
    );
  }


  Future<dynamic> getDataa() async {
    HttpOverrides.global = MyHttpOverrides();
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    var finalKulonuwun = sharedPreferences.getString('kulonuwun');
    var finalMonggo = sharedPreferences.getString('monggo');
    var kulonuwun = MsgHeader.kulonuwun;
    var monggo = MsgHeader.monggo;
    try {
      var getData = await http.get(
        Uri.https(ApiName.v2rp, ApiName.itApp + widget.seckey),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );
      final caConfirmData = json.decode(getData.body);
      final _data = caConfirmData['data'];
      if (_data is Map && _data['header'] is Map) {
      }
      final data = caConfirmData['data'];
      final rawDetails =
          data is Map ? (data['detail'] ?? data['details']) : null;
      final details = rawDetails is List ? rawDetails : <dynamic>[];
      final total = approvalSumLineAmount(
        details.whereType<Map<dynamic, dynamic>>(),
      );
      if (mounted) {
        setState(() {
          dataaa = details;
          totalPrice = total;
        });
      } else {
        dataaa = details;
        totalPrice = total;
      }
      print("totalllll  $totalPrice (calc=$total, lines=${details.length})");
      if (mounted) setState(() {});
      return dataaa;
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendConfirm() async {
    HttpOverrides.global = MyHttpOverrides();
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    var finalKulonuwun = sharedPreferences.getString('kulonuwun');
    var finalMonggo = sharedPreferences.getString('monggo');
    var kulonuwun = MsgHeader.kulonuwun;
    var monggo = MsgHeader.monggo;
    var status;
    var message;
    var messageError;
    DateTime dateNow = DateTime.now();

    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Loading',
      text: 'Submitting your data',
      barrierDismissible: false,
      disableBackBtn: true,
    );
    if (updstatus == '-1') {
      setState(() {
        currentDate = dateNow.toString();
      });
    }
    try {
      var getData = await http.put(
        Uri.https(
          ApiName.v2rp,
          ApiName.itApp + widget.seckey + '/' + updstatus,
        ),
        headers: {
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
        body: {
          'estrcvd': currentDate.toString(),
          "reason": textControllers.itAppControllerReason.value.text,
        },
      );
      final response = json.decode(getData.body);
      print(response.toString());
      setState(() {
        status = response['success'];
        messageError = response['message'];
      });
      if (status == true) {
        setState(() {
          message = response['data']['message'];
        });
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: 'Success $message Data!',
            barrierDismissible: false,
            // confirmBtnText: 'OK',
            disableBackBtn: true,
            onConfirmBtnTap: () async {
              Get.to(() => ItApp());
            },
            showCancelBtn: true,
            cancelBtnText: 'Home',
            onCancelBtnTap: () async {
              Get.to(const Navbar());
            });
      } else {
        setState(() {
          message = response['data']['message'];
        });
        await Future.delayed(const Duration(milliseconds: 1000));
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          disableBackBtn: true,
          title: 'Failed! ' + widget.reffno,
          text: '$message',
          onConfirmBtnTap: () async {
            Get.to(() => ItApp());
          },
        );
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        disableBackBtn: true,
        title: 'Error! ' + widget.reffno,
        text: '$messageError',
        onConfirmBtnTap: () async {
          Get.to(() => ItApp());
        },
      );
    }
  }

  Future<void> reason() async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      confirmBtnText: 'S U B M I T',
      confirmBtnColor: HexColor("#ffc947"),
      widget: TextFormField(
        decoration: const InputDecoration(
          alignLabelWithHint: true,
          hintText: 'Enter Your Reason',
          prefixIcon: Icon(
            Icons.text_snippet_rounded,
          ),
        ),
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.text,
        controller: textControllers.itAppControllerReason.value,
      ),
      onConfirmBtnTap: () {
        print(textControllers.itAppControllerReason.value.text);
        sendConfirm();
      },
    );
    textControllers.itAppControllerReason.value.clear();
  }
}
