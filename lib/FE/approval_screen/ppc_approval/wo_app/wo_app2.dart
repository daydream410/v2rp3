import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/approval_screen/ppc_approval/wo_app/wo_app.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;
import 'package:v2rp3/routes/api_name.dart';
import '../../../../BE/reqip.dart';
// import 'package:v2rp3/BE/controller.dart';

import '../../../../main.dart';

class WoApp2 extends StatefulWidget {
  final seckey;
  final reffno;
  final tanggal;
  final duedate;
  final amount;
  final username;
  final projectid;
  final locationname;
  final description;
  final wipacc;
  final wipaccName;

  WoApp2({
    Key? key,
    required this.seckey,
    required this.reffno,
    required this.tanggal,
    required this.duedate,
    required this.amount,
    required this.username,
    required this.projectid,
    required this.locationname,
    required this.description,
    required this.wipacc,
    required this.wipaccName,
  }) : super(key: key);

  @override
  State<WoApp2> createState() => _WoApp2State();
}

class _WoApp2State extends State<WoApp2> {
  late Future dataFuture;

  String reasonValue = '';
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

  @override
  void initState() {
    super.initState();
    final raw = widget.amount;
    if (raw != null) {
      totalPrice = raw is num
          ? raw.toDouble()
          : (double.tryParse(raw.toString()) ?? 0);
    }
  }

  String get _formattedDueDate {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(widget.duedate));
    } catch (_) {
      return widget.duedate?.toString() ?? '-';
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
          ApprovalInfoField('WO No', widget.reffno?.toString() ?? '-'),
          ApprovalInfoField('Due Date', _formattedDueDate),
          ApprovalInfoField('Amount',
              ApprovalTheme.currencyFmt.format(totalPrice)),
          ApprovalInfoField('Project', widget.projectid?.toString() ?? '-'),
          ApprovalInfoField('Location', widget.locationname?.toString() ?? '-'),
          ApprovalInfoField('WIP Account', widget.wipacc?.toString() ?? '-'),
          ApprovalInfoField(
              'WIP Account Name', widget.wipaccName?.toString() ?? '-'),
          ApprovalInfoField('Request By', widget.username?.toString() ?? '-'),
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
        onBack: () => Get.to(() => WoApp()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.username ?? '-',
          fields: [
            ApprovalInfoField('Request By', widget.username ?? '-'),
            ApprovalInfoField('Project', widget.projectid ?? '-'),
            ApprovalInfoField('Location', widget.locationname ?? '-'),
          ],
          reason: widget.description,
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
  //   final SharedPreferences sharedPreferences =
  //       await SharedPreferences.getInstance();
  //   var finalKulonuwun = sharedPreferences.getString('kulonuwun');
  //   var finalMonggo = sharedPreferences.getString('monggo');
  //   var kulonuwun = MsgHeader.kulonuwun;
  //   var monggo = MsgHeader.monggo;
  //   try {
  //     var getData = await http.get(
  //       Uri.https(ApiName.v2rp, ApiName.grApp + widget.seckey),
  //       headers: {
  //         'Content-Type': 'application/json; charset=utf-8',
  //         'kulonuwun': finalKulonuwun ?? kulonuwun,
  //         'monggo': finalMonggo ?? monggo,
  //       },
  //     );
  //     final caConfirmData = json.decode(getData.body);
  //     dataaa = caConfirmData['data']['detail'];
  //     print("totalllll  " + totalPrice.toString());
  //     print("dataaa " + dataaa.toString());
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

    // var body = json.encode({
    //   "reason": '',
    // });
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
          ApiName.woApp + widget.seckey + '/' + updstatus,
        ),
        // body: body,
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
              Get.to(() => WoApp());
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
            Get.to(() => WoApp());
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
          Get.to(() => WoApp());
        },
      );
    }
  }

  // Future<void> reason() async {
  //   QuickAlert.show(
  //     context: context,
  //     type: QuickAlertType.custom,
  //     confirmBtnText: 'S U B M I T',
  //     confirmBtnColor: HexColor("#ffc947"),
  //     widget: TextFormField(
  //       decoration: const InputDecoration(
  //         alignLabelWithHint: true,
  //         hintText: 'Enter Your Reason',
  //         prefixIcon: Icon(
  //           Icons.text_snippet_rounded,
  //         ),
  //       ),
  //       textInputAction: TextInputAction.next,
  //       keyboardType: TextInputType.text,
  //       controller: textControllers.grAppControllerReason.value,
  //     ),
  //     onConfirmBtnTap: () {
  //       print(textControllers.grAppControllerReason.value.text);
  //       sendConfirm();
  //     },
  //   );
  //   textControllers.grAppControllerReason.value.clear();
  // }
}
