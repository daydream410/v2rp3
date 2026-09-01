import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
// import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/assembling_approval/asmb_app.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;
import 'package:v2rp3/routes/api_name.dart';
// import '../../../../BE/resD.dart';

import '../../../../BE/reqip.dart';
import '../../../../main.dart';

class AssemblingApp2 extends StatefulWidget {
  final seckey;
  final reffno;
  final tanggal;
  final estdate;
  final requestor;
  final supplier;
  final item;
  final location;
  final ket;

  AssemblingApp2({
    Key? key,
    required this.seckey,
    required this.reffno,
    required this.tanggal,
    required this.estdate,
    required this.requestor,
    required this.supplier,
    required this.item,
    required this.location,
    required this.ket,
  }) : super(key: key);

  @override
  State<AssemblingApp2> createState() => _AssemblingApp2State();
}

class _AssemblingApp2State extends State<AssemblingApp2> {
  // static late List dataaa = <CaConfirmData>[];

  late Future dataFuture;

  @override
  void initState() {
    super.initState();
  }

  var valueChooseRequest = "";
  var valueStatus = "";
  var updstatus = "0";
  double totalPrice = 0;
  bool isVisible = false;

  static const _statusActions = [
    ApprovalActionMeta(label: 'Pending', icon: Icons.hourglass_empty_rounded, color: Color(0xFF9E9E9E)),
    ApprovalActionMeta(label: 'Approve', icon: Icons.check_circle_outline_rounded, color: Color(0xFFF4A62A)),
  ];

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  String get _formattedEstDate {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(widget.estdate));
    } catch (_) {
      return widget.estdate?.toString() ?? '-';
    }
  }

  void _onStatusSelected(String status) {
    setState(() {
      valueStatus = status;
      if (status == "Pending") { updstatus = "0"; isVisible = false; }
      else if (status == "Approve") { updstatus = "1"; isVisible = true; }
    });
  }
  Widget _buildBody() {
    return ApprovalDetailItemsColumn(
      count: 1,
      tableRows: [
        [
          ApprovalInfoField('Item', widget.item?.toString() ?? '-'),
          ApprovalInfoField('Supplier', widget.supplier?.toString() ?? '-'),
          ApprovalInfoField('Location', widget.location?.toString() ?? '-'),
          ApprovalInfoField('Est. Date', _formattedEstDate),
          ApprovalInfoField('Request By', widget.requestor?.toString() ?? '-'),
        ],
      ],
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
        onBack: () => Get.to(() => AssemblingApp()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.requestor ?? '-',
          fields: [
            ApprovalInfoField('Request By', widget.requestor ?? '-'),
            ApprovalInfoField('Supplier', widget.supplier ?? '-'),
            ApprovalInfoField('Location', widget.location ?? '-'),
          ],
          reason: widget.ket,
        ),
        actionSection: ApprovalActionGrid(actions: _statusActions, selectedLabel: valueStatus, onSelected: _onStatusSelected),
        body: _buildBody(),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: totalPrice, itemCount: 1,
          selectedAction: hasAction ? valueStatus : null,
          actionColor: hasAction ? ApprovalTheme.primary : null,
          idleHint: 'Select an action to continue',
          onSubmit: hasAction ? () { sendConfirm(); } : null,
        ),
      ),
    );
  }


  // Future<dynamic> getDataa() async {
  //   HttpOverrides.global = MyHttpOverrides();

  //   var kulonuwun = MsgHeader.kulonuwun;
  //   var monggo = MsgHeader.monggo;
  //   try {
  //     var getData = await http.get(
  //       Uri.http('156.67.217.113',
  //           '/api/v1/mobile/approval/assembling/' + widget.seckey),
  //       headers: {
  //         'Content-Type': 'application/json; charset=utf-8',
  //         'kulonuwun': kulonuwun,
  //         'monggo': monggo,
  //       },
  //     );
  //     final caConfirmData = json.decode(getData.body);

  //     // setState(() {
  //     dataaa = caConfirmData['data']['detail'];
  //     print("dataaa " + dataaa.toString());

  //     //hitung total
  //     totalPrice = 0;
  //     for (var item in dataaa) {
  //       totalPrice += item["amount"] as int;
  //     }

  //     // });
  //     print("totalllll  " + totalPrice.toString());
  //     return dataaa;
  //   } catch (e) {
  //     print(e);
  //   }
  // }

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
        // Uri.http(
        //   '156.67.217.113',
        //   '/api/v1/mobile/approval/assembling/' +
        //       widget.seckey +
        //       '/' +
        //       updstatus,
        // ),
        Uri.https(
          ApiName.v2rp,
          ApiName.assembling + widget.seckey + '/' + updstatus,
        ),
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
        // Get.snackbar(
        //   'Success $message Data!',
        //   widget.reffno,
        //   icon: const Icon(Icons.check),
        //   backgroundColor: Colors.green,
        //   isDismissible: true,
        //   dismissDirection: DismissDirection.vertical,
        //   colorText: Colors.white,
        // );
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: 'Success $message Data!',
            barrierDismissible: false,
            disableBackBtn: true,
            // confirmBtnText: 'OK',
            onConfirmBtnTap: () async {
              Get.to(() => AssemblingApp());
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
        // Get.snackbar(
        //   'Failed! ' + widget.reffno,
        //   '$messageError',
        //   icon: const Icon(Icons.warning),
        //   backgroundColor: Colors.red,
        //   isDismissible: true,
        //   dismissDirection: DismissDirection.vertical,
        //   colorText: Colors.white,
        // );
        await Future.delayed(const Duration(milliseconds: 1000));
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Failed! ' + widget.reffno,
          disableBackBtn: true,
          text: '$message',
          onConfirmBtnTap: () async {
            Get.to(() => AssemblingApp());
          },
        );
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Error! ' + widget.reffno,
        text: '$messageError',
        disableBackBtn: true,
        onConfirmBtnTap: () async {
          Get.to(() => AssemblingApp());
        },
      );
    }
  }
}
