import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/BE/controller.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/sppbj_confirm/sppbj_confirm.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;

import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import '../../../../main.dart';

class SppbjConfirm2 extends StatefulWidget {
  final seckey;
  final sppbjno;
  final sppbjtype;
  final tanggal;
  final requestorname;
  final warehouse;
  final wono;
  final reason;

  SppbjConfirm2({
    Key? key,
    required this.seckey,
    required this.sppbjno,
    required this.sppbjtype,
    required this.tanggal,
    required this.requestorname,
    required this.warehouse,
    required this.wono,
    required this.reason,
  }) : super(key: key);

  @override
  State<SppbjConfirm2> createState() => _SppbjConfirm2State();
}

class _SppbjConfirm2State extends State<SppbjConfirm2> {
  static late List dataaa = <CaConfirmData>[];

  late Future dataFuture;

  @override
  void initState() {
    super.initState();

    dataFuture = getDataa();
  }

  var valueChooseRequest = "";
  var valueStatus = "";
  var updstatus = "0";
  double totalPrice = 0;
  bool isVisible = false;
  String reasonValue = '';
  static TextControllers textControllers = Get.put(TextControllers());

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
              approvalSppbjItemFields(dataaa[i]),
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
        docNo: widget.sppbjno ?? '',
        subtitle: _formattedDate,
        onBack: () => Get.to(() => SppbjConfirm()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.requestorname ?? '-',
          fields: [
            ApprovalInfoField('SPPBJ No', widget.sppbjno?.toString() ?? '-'),
            ApprovalInfoField('Date', _formattedDate),
            ApprovalInfoField('Type', widget.sppbjtype == 0 ? 'SCM' : 'Non SCM'),
            ApprovalInfoField('Warehouse', widget.warehouse ?? '-'),
            ApprovalInfoField('WO No', widget.wono ?? '-'),
            ApprovalInfoField('Request By', widget.requestorname ?? '-'),
          ],
          reason: widget.reason,
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
        Uri.https(
            'v2rp.net', '/api/v1/mobile/confirmation/sppbj/' + widget.seckey),
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
      print("dataaa " + caConfirmData.toString());

      // setState(() {
      dataaa = caConfirmData['data']['detail'];

      //hitung total
      totalPrice = 0;
      for (var item in dataaa) {
        totalPrice += approvalToDouble(item["amount"]);
      }

      // });
      print("totalllll  " + totalPrice.toString());
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
      "reason": textControllers.sppbjConfirmControllerReason.value.text,
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
          'v2rp.net',
          '/api/v1/mobile/confirmation/sppbj/' +
              widget.seckey +
              '/' +
              updstatus,
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
        setState(() {
          reffno = response['data']['reffno'];
          message = response['data']['message'];
        });
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            disableBackBtn: true,
            text: '$message Data!',
            barrierDismissible: false,
            // confirmBtnText: 'OK',
            onConfirmBtnTap: () async {
              Get.to(() => SppbjConfirm());
            },
            showCancelBtn: true,
            cancelBtnText: 'Home',
            onCancelBtnTap: () async {
              Get.to(const Navbar());
            });
      } else {
        setState(() {
          reffno = response['data']['reffno'];
          message = response['data']['message'];
        });
        await Future.delayed(const Duration(milliseconds: 1000));
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          disableBackBtn: true,
          title: 'Failed! ' + reffno,
          text: '$message',
          onConfirmBtnTap: () async {
            Get.to(() => SppbjConfirm());
          },
        );
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        disableBackBtn: true,
        title: 'Error! ',
        text: '$messageError',
        onConfirmBtnTap: () async {
          Get.to(() => SppbjConfirm());
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
        controller: textControllers.sppbjConfirmControllerReason.value,
      ),
      onConfirmBtnTap: () {
        print(textControllers.sppbjConfirmControllerReason.value.text);
        sendConfirm();
      },
    );
    textControllers.sppbjConfirmControllerReason.value.clear();
  }
}
