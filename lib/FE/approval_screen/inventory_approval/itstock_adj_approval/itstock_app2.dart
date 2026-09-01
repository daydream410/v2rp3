import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/itstock_adj_approval/itstock_app.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:v2rp3/routes/api_name.dart';
import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import '../../../../main.dart';
import 'package:v2rp3/BE/controller.dart';

class ItStockAdjApp2 extends StatefulWidget {
  final seckey;
  final reffno;
  final warehouse;
  final tanggal;
  final requestor;
  ItStockAdjApp2({
    Key? key,
    required this.seckey,
    required this.reffno,
    required this.warehouse,
    required this.tanggal,
    required this.requestor,
  }) : super(key: key);

  @override
  State<ItStockAdjApp2> createState() => _ItStockAdjApp2State();
}

class _ItStockAdjApp2State extends State<ItStockAdjApp2> {
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

  static const _statusActions = [
    ApprovalActionMeta(label: 'Ready To Approval', icon: Icons.fact_check_outlined, color: Color(0xFFF4A62A)),
    ApprovalActionMeta(label: 'Send To Draft', icon: Icons.edit_note_outlined, color: Color(0xFFFF9800)),
    ApprovalActionMeta(label: 'Approved & Updated', icon: Icons.check_circle_rounded, color: Color(0xFF43A047)),
  ];

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  void _onStatusSelected(String status) {
    setState(() {
      valueStatus = status;
      if (status == "Ready To Approval") { updstatus = "1"; isVisible = true; }
      else if (status == "Send To Draft") { updstatus = "-9"; isVisible = true; }
      else if (status == "Approved & Updated") { updstatus = "1"; isVisible = true; }
    });
  }
  List<ApprovalInfoField> _itemDetailFields(dynamic e) {
    return [
      ApprovalInfoField('SPPBJ No', (e['sppbjno'] ?? '').toString()),
      ApprovalInfoField('Project ID', (e['projectid'] ?? '').toString()),
      ApprovalInfoField('Stock ID', (e['stockcode'] ?? '').toString()),
      ApprovalInfoField('Description', (e['ket'] ?? e['stocknm']).toString()),
      ApprovalInfoField('Unit', (e['unit'] ?? '').toString()),
      ApprovalInfoField('From WH', (e['warehouse'] ?? e['fmwh']).toString()),
      ApprovalInfoField('QTY Deliver', (e['qtyrcvd']?.toString() ?? e['rcvd'].toString()).toString()),
      ApprovalInfoField('QTY Received', (e['qtyarrive'].toString())),
      ApprovalInfoField('QTY Stock', (e['qtystock'].toString())),
      ApprovalInfoField('O/S QTY', ((e['qtyrcvd'] - e['qtyarrive'] - e['qtystock']) .toStringAsFixed(1)).toString()),
      ApprovalInfoField('Adj Write Off', (e['qtywoff'].toString())),
      ApprovalInfoField('Adj Send Back', (e['qtysendback'].toString())),
      ApprovalInfoField('Adj Allocate To W/H', (e['qtytowh'].toString())),
      ApprovalInfoField('Adj WH', (e['adjwarehouse'].toString())),
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
        onBack: () => Get.to(() => ItStockAdjApp()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.requestor ?? '-',
          fields: [
            ApprovalInfoField('Request By', widget.requestor ?? '-'),
            ApprovalInfoField('Warehouse', widget.warehouse ?? '-'),
          ],
        ),
        actionSection: ApprovalActionGrid(actions: _statusActions, selectedLabel: valueStatus, onSelected: _onStatusSelected),
        body: _buildBody(),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: totalPrice, itemCount: dataaa.length,
          selectedAction: hasAction ? valueStatus : null,
          actionColor: hasAction ? ApprovalTheme.primary : null,
          idleHint: 'Select an action to continue',
          onSubmit: hasAction ? () { if (updstatus == '-9') { reason(); } else { sendConfirm(); } } : null,
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

    String reffnoo = widget.reffno;
    String contain = 'STRF';
    if (reffnoo.contains(contain)) {
      print('contain');
      try {
        var getData = await http.get(
          Uri.https(ApiName.v2rp, ApiName.itAdj + widget.seckey),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'kulonuwun': finalKulonuwun ?? kulonuwun,
            'monggo': finalMonggo ?? monggo,
          },
        );
        final responseData = json.decode(getData.body);
      final _data = responseData['data'];
      if (_data is Map && _data['header'] is Map) {
      }
      final details = responseData['data']['detail'];
      if (mounted) { setState(() => dataaa = details); } else { dataaa = details; }
        print("dataaa " + dataaa.toString());

        if (mounted) setState(() {});
        return dataaa;
      } catch (e) {
        print(e);
      }
    } else {
      print('not');
      try {
        var getData = await http.get(
          Uri.https(ApiName.v2rp, ApiName.stockAdj + widget.seckey),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'kulonuwun': finalKulonuwun ?? kulonuwun,
            'monggo': finalMonggo ?? monggo,
          },
        );
        final responseData = json.decode(getData.body);
        dataaa = responseData['data']['detail'];
        print("dataaa " + dataaa.toString());

        if (mounted) setState(() {});
        return dataaa;
      } catch (e) {
        print(e);
      }
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
    String reffnoo = widget.reffno;
    String contain = 'STRF';

    var body = json.encode({
      "reason": textControllers.itstockadjAppControllerReason.value.text,
    });
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Loading',
      text: 'Submitting your data',
      barrierDismissible: false,
      disableBackBtn: true,
    );
    if (reffnoo.contains(contain)) {
      try {
        var getData = await http.put(
          Uri.https(
            ApiName.v2rp,
            ApiName.itAdj + widget.seckey + '/' + updstatus,
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
                Get.to(() => ItStockAdjApp());
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
            title: 'Failed! ' + widget.reffno,
            text: '$message',
            disableBackBtn: true,
            onConfirmBtnTap: () async {
              Get.to(() => ItStockAdjApp());
            },
          );
        }
      } catch (e) {
        print(e);
      }
    } else {
      try {
        var getData = await http.put(
          Uri.https(
            ApiName.v2rp,
            ApiName.stockAdj + widget.seckey + '/' + updstatus,
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
                Get.to(() => ItStockAdjApp());
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
            title: 'Failed! ' + widget.reffno,
            text: '$message',
            disableBackBtn: true,
            onConfirmBtnTap: () async {
              Get.to(() => ItStockAdjApp());
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
            Get.to(() => ItStockAdjApp());
          },
        );
      }
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
        controller: textControllers.itstockadjAppControllerReason.value,
      ),
      onConfirmBtnTap: () {
        print(textControllers.itstockadjAppControllerReason.value.text);
        sendConfirm();
      },
    );
    textControllers.itstockadjAppControllerReason.value.clear();
  }
}
