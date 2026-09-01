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
import 'package:v2rp3/FE/approval_screen/inventory_approval/mu_approval/mu_app.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;
import '../../../../BE/resD.dart';
import 'package:v2rp3/BE/controller.dart';

import '../../../../BE/reqip.dart';
import '../../../../main.dart';

class MuApp2 extends StatefulWidget {
  final seckey;
  final dono;
  final tanggal;
  final userid;
  final ket;

  MuApp2({
    Key? key,
    required this.seckey,
    required this.dono,
    required this.tanggal,
    required this.userid,
    required this.ket,
  }) : super(key: key);

  @override
  State<MuApp2> createState() => _MuApp2State();
}

class _MuApp2State extends State<MuApp2> {
  static late List dataaa = <CaConfirmData>[];

  late Future dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = getDataa();
  }

  String reasonValue = '';
  static TextControllers textControllers = Get.put(TextControllers());
  var valueChooseRequest = "";
  var valueStatus = "";
  var updstatus = "0";
  double totalPrice = 0;
  bool isVisible = false;
  static const _statusActions = [
    ApprovalActionMeta(label: 'Pending', icon: Icons.hourglass_empty_rounded, color: Color(0xFF9E9E9E)),
    ApprovalActionMeta(label: 'Update', icon: Icons.update_rounded, color: Color(0xFFF4A62A)),
    ApprovalActionMeta(label: 'Reject', icon: Icons.cancel_outlined, color: Color(0xFFE53935)),
  ];

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  void _onStatusSelected(String status) {
    setState(() {
      valueStatus = status;
      if (status == "Pending") { updstatus = "0"; isVisible = false; }
      else if (status == "Update") { updstatus = "1"; isVisible = true; }
      else if (status == "Reject") { updstatus = "-1"; isVisible = true; }
    });
  }
  List<ApprovalInfoField> _itemDetailFields(dynamic e) {
    return [
      ApprovalInfoField('SPPBJ No', (e['sppbjno'] ?? '').toString()),
      ApprovalInfoField('Project Name', (e['projectid'] ?? '').toString()),
      ApprovalInfoField('Stock ID', (e['stockcode'] ?? '').toString()),
      ApprovalInfoField('Desc', (e['ket'] ?? '').toString()),
      ApprovalInfoField('Unit', (e['unit'] ?? '').toString()),
      ApprovalInfoField('WH ID', (e['warehouse'] ?? '').toString()),
      ApprovalInfoField('WH Name', (e['warehousename'] ?? '').toString()),
      ApprovalInfoField('QTY Req', (e['qty'].toString())),
      ApprovalInfoField('QTY Realize', (e['qtyrcvd'].toString())),
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
        docNo: widget.dono ?? '',
        subtitle: _formattedDate,
        onBack: () => Get.to(() => MuApp()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.userid ?? '-',
          fields: [
            ApprovalInfoField('User', widget.userid ?? '-'),
          ],
          reason: widget.ket,
        ),
        actionSection: ApprovalActionGrid(actions: _statusActions, selectedLabel: valueStatus, onSelected: _onStatusSelected),
        body: _buildBody(),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: totalPrice, itemCount: dataaa.length,
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
        Uri.https('v2rp.net',
            '/api/v1/mobile/approval/materialused/' + widget.seckey),
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
      if (mounted) { setState(() => dataaa = details); } else { dataaa = details; }

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
    var message;
    var messageError;

    var body = json.encode({
      "reason": textControllers.muAppControllerReason.value.text,
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
          '/api/v1/mobile/approval/materialused/' +
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
              Get.to(() => MuApp());
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
          title: 'Failed! ' + widget.dono,
          disableBackBtn: true,
          text: '$message',
          onConfirmBtnTap: () async {
            Get.to(() => MuApp());
          },
        );
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Error! ' + widget.dono,
        disableBackBtn: true,
        text: messageError ?? 'Cannot Reach Server!',
        onConfirmBtnTap: () async {
          Get.to(() => MuApp());
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
        controller: textControllers.muAppControllerReason.value,
      ),
      onConfirmBtnTap: () {
        print(textControllers.muAppControllerReason.value.text);
        sendConfirm();
      },
    );
    textControllers.muAppControllerReason.value.clear();
  }
}
