// ignore_for_file: avoid_print, unused_local_variable, prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:v2rp3/BE/approval_notif_controller.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/BE/controller.dart';
import 'package:v2rp3/FE/approval_screen/cash_bank/cash_advance_confirm/ca_confirm.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'package:v2rp3/routes/api_name.dart';
import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import '../../../../main.dart';

class CashAdvanceConfirm2 extends StatefulWidget {
  final seckey;
  final nokasbon;
  final ket;
  final tanggal;
  final requestor;
  final requestorname;
  final updstatus;
  final kasir;
  final kasirname;
  const CashAdvanceConfirm2({
    Key? key,
    required this.seckey,
    required this.nokasbon,
    required this.ket,
    required this.tanggal,
    required this.requestor,
    required this.requestorname,
    required this.updstatus,
    required this.kasir,
    required this.kasirname,
  }) : super(key: key);

  @override
  State<CashAdvanceConfirm2> createState() => _CashAdvanceConfirm2State();
}

class _CashAdvanceConfirm2State extends State<CashAdvanceConfirm2> {
  static late List dataaa = <CaConfirmData>[];

  late Future dataFuture;

  @override
  void initState() {
    super.initState();

    dataFuture = getDataa();
  }

  static TextControllers textControllers = Get.put(TextControllers());
  var valueChooseRequest = "";
  var valueStatus = "";
  var updstatus = "0";
  double totalPrice = 0;
  bool isVisible = false;
  String reasonValue = '';

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  void _onStatusSelected(String status) {
    setState(() {
      valueStatus = status;
      if (status == "Pending") { updstatus = "0"; isVisible = false; }
      else if (status == "Confirm") { updstatus = "1"; isVisible = true; }
      else if (status == "Reject") { updstatus = "-1"; isVisible = true; }
      else if (status == "Send To Draft") { updstatus = "-9"; isVisible = true; }
    });
  }
  List<ApprovalInfoField> _itemDetailFields(dynamic e) {
    return [
      ApprovalInfoField('Request By', (e['requestorname'] ?? '').toString()),
      ApprovalInfoField('Project Name', approvalProjectName(e)),
      ApprovalInfoField('Project ID', approvalProjectId(e)),
      ApprovalInfoField('Item/ Acc No', (e['itemcoa'] ?? '').toString()),
      ApprovalInfoField('Item/Acc Name', approvalAccountName(e)),
      ApprovalInfoField('Desc', (e['ket'] ?? '').toString()),
      ApprovalInfoField('Unit', (e['unit'].toString())),
      ApprovalInfoField('QTY', (e['qty'].toString())),
      ApprovalInfoField('Price/ Unit', (ApprovalTheme.currencyFmt.format(e['harga'])).toString()),
      ApprovalInfoField('Amount', (ApprovalTheme.currencyFmt.format(e['amount'])).toString()),
      ApprovalInfoField('Budget Avail', (ApprovalTheme.currencyFmt.format(approvalBudgetAvailable(e))).toString()),
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
        docNo: widget.nokasbon ?? '',
        subtitle: _formattedDate,
        onBack: () => Get.to(() => CashAdvanceConfirm()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.requestorname ?? '-',
          fields: [
            ApprovalInfoField('Request By', widget.requestorname ?? '-'),
            ApprovalInfoField('Cashier', widget.kasirname ?? '-'),
          ],
          reason: widget.ket,
        ),
        actionSection: ApprovalActionGrid(
          actions: ApprovalActions.confirmActions,
          selectedLabel: valueStatus,
          onSelected: _onStatusSelected,
        ),
        body: _buildBody(),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: totalPrice, itemCount: dataaa.length,
          selectedAction: hasAction ? valueStatus : null,
          actionColor: hasAction ? ApprovalActions.colorFor(valueStatus, ApprovalActions.confirmActions) : null,
          idleHint: 'Select an action to continue',
          onSubmit: hasAction ? () { if (updstatus == '-9' || updstatus == '-1') { reason(); } else { sendConfirm(); } } : null,
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
        // Uri.http('156.67.217.113',
        //     '/api/v1/mobile/confirmation/kasbon/' + widget.seckey),
        Uri.https(ApiName.v2rp, ApiName.kasbonConfirm + widget.seckey),
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
      final details = caConfirmData['data']['detail'];
      var total = 0.0;
      for (var item in details) { total += approvalToDouble(item["amount"]); }
      if (mounted) { setState(() { dataaa = details; totalPrice = total; }); }
      else { dataaa = details; totalPrice = total; }

      // });
      print("totalllll  " + totalPrice.toString());
      print("dataaa " + dataaa.toString());
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
    var reffno;
    var message;
    var messageError;

    var body = json.encode({
      "reason": textControllers.caConfirmControllerReason.value.text,
    });
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Loading',
      text: 'Submitting your data',
      barrierDismissible: false,
      disableBackBtn: true,
    );
    try {
      var getData = await http.put(
        Uri.https(
          ApiName.v2rp,
          ApiName.kasbonConfirm + widget.seckey + '/' + updstatus,
        ),
        body: body,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );
      final response = json.decode(getData.body);
      print(response.toString());
      setState(() {
        status = response['success'];
        messageError = response['message'];
      });
      if (status == true) {
        approvalRefreshMenuCounts();
        setState(() {
          message = response['data']['message'];
        });
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: 'Success $message Data!',
            barrierDismissible: false,
            disableBackBtn: true,
            // confirmBtnText: 'OK',
            onConfirmBtnTap: () async {
              Get.to(() => CashAdvanceConfirm());
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
          title: 'Failed! ' + widget.nokasbon,
          disableBackBtn: true,
          text: '$message',
          onConfirmBtnTap: () async {
            Get.to(() => CashAdvanceConfirm());
          },
        );
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Error! ' + widget.nokasbon,
        disableBackBtn: true,
        text: '$messageError',
        onConfirmBtnTap: () async {
          Get.to(() => CashAdvanceConfirm());
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
        controller: textControllers.caConfirmControllerReason.value,
      ),
      onConfirmBtnTap: () {
        print(textControllers.caConfirmControllerReason.value.text);
        sendConfirm();
      },
    );
    textControllers.caConfirmControllerReason.value.clear();
  }
}
