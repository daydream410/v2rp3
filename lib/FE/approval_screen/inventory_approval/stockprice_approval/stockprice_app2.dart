import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/stockprice_approval/stockprice_app.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import '../../../../main.dart';
import 'package:v2rp3/BE/approval_notif_controller.dart';

class StockPriceApp2 extends StatefulWidget {
  final seckey;
  final apreff;
  final apjvno;
  final tanggal;
  final supplierName;
  StockPriceApp2({
    Key? key,
    required this.seckey,
    required this.apreff,
    required this.apjvno,
    required this.tanggal,
    required this.supplierName,
  }) : super(key: key);

  @override
  State<StockPriceApp2> createState() => _StockPriceApp2State();
}

class _StockPriceApp2State extends State<StockPriceApp2> {
  static late List dataaa = <CaConfirmData>[];

  late Future dataFuture;

  @override
  void initState() {
    super.initState();

    dataFuture = getDataa();
  }

  var valueChooseRequest = "";
  var valueStatus = "";
  var updstatus = "1";
  double totalDiff = 0;
  double totalStock = 0;
  double totalCogs = 0;
  bool isVisible = false;

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  List<ApprovalInfoField> _itemDetailFields(dynamic e) {
    return [
      ApprovalInfoField('GR No', (e['grno'] ?? '').toString()),
      ApprovalInfoField('P/O No', (e['pono'] ?? '').toString()),
      ApprovalInfoField('SPPBJ No', (e['sppbjno'] ?? '').toString()),
      ApprovalInfoField('Project', (e['projectcode'] ?? '').toString()),
      ApprovalInfoField('Item', (e['stockcode'] ?? '').toString()),
      ApprovalInfoField('Name', (e['itemnm'] ?? '').toString()),
      ApprovalInfoField('QTY Inv', (e['qtyap'].toString())),
      ApprovalInfoField('QTY GR', (e['qtygr'].toString())),
      ApprovalInfoField('Inv Amount', (ApprovalTheme.currencyFmt.format(e['amountap'])).toString()),
      ApprovalInfoField('G/R Amount', (ApprovalTheme.currencyFmt.format(e['qtamountgr'])).toString()),
      ApprovalInfoField('Diff', (ApprovalTheme.currencyFmt.format(e['amountap'] - e['qtamountgr'])).toString()),
      ApprovalInfoField('Allocate To Stock', (ApprovalTheme.currencyFmt.format(e['astock'])).toString()),
      ApprovalInfoField('Allocate To COGS', (ApprovalTheme.currencyFmt.format(e['aexpend'])).toString()),
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
    final hasAction = true;
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
        docNo: widget.apreff ?? '',
        subtitle: _formattedDate,
        onBack: () => Get.to(() => StockPriceApp()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.supplierName ?? '-',
          fields: [
            ApprovalInfoField('JV No', widget.apjvno ?? '-'),
            ApprovalInfoField('Supplier', widget.supplierName ?? '-'),
          ],
        ),
        actionSection: null,
        body: _buildBody(),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: totalDiff, itemCount: dataaa.length,
          selectedAction: hasAction ? 'Submit' : null,
          actionColor: hasAction ? ApprovalTheme.primary : null,
          idleHint: 'Tap submit to approve',
          onSubmit: () { sendConfirm(); },
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
        //     '/api/v1/mobile/approval/stockpriceadjustment/' + widget.seckey),
        Uri.https('v2rp.net',
            '/api/v1/mobile/approval/stockpriceadjustment/' + widget.seckey),
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
      // setState(() {
      dataaa = caConfirmData['data']['detail'];

      //hitung total
      totalDiff = 0;
      totalStock = 0;
      totalCogs = 0;
      for (var item in dataaa) {
        totalDiff += approvalToDouble(item['amountap']) - approvalToDouble(item['qtamountgr']);
        totalStock += approvalToDouble(item['astock']);
        totalCogs += approvalToDouble(item['aexpend']);
      }

      // });
      print("totalllll  " + totalDiff.toString());
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
        //   '/api/v1/mobile/approval/stockpriceadjustment/' +
        //       widget.seckey +
        //       '/' +
        //       updstatus,
        // ),
        Uri.https(
          'v2rp.net',
          '/api/v1/mobile/approval/stockpriceadjustment/' +
              widget.seckey +
              '/' +
              updstatus,
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
        approvalRefreshMenuCounts();
        setState(() {
          message = response['data']['message'];
        });
        // Get.snackbar(
        //   'Success $message Data!',
        //   widget.apreff,
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
              Get.to(() => StockPriceApp());
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
        //   'Failed! ' + widget.apreff,
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
          title: 'Failed! ' + widget.apreff,
          disableBackBtn: true,
          text: '$message',
          onConfirmBtnTap: () async {
            Get.to(() => StockPriceApp());
          },
        );
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Error! ' + widget.apreff,
        disableBackBtn: true,
        text: '$messageError',
        onConfirmBtnTap: () async {
          Get.to(() => StockPriceApp());
        },
      );
    }
  }
}
