// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/poscm_unapproved/poscm_unapproved.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;

import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import '../../../../BE/controller.dart';
import '../../../../main.dart';

class PoUnapproved2 extends StatefulWidget {
  final seckey;
  final pono;
  final tanggal;
  final requestorname;
  final supplier;
  final ccy;
  final disc;
  final tipe;

  const PoUnapproved2({
    Key? key,
    required this.seckey,
    required this.pono,
    required this.tanggal,
    required this.requestorname,
    required this.supplier,
    required this.ccy,
    required this.disc,
    required this.tipe,
  }) : super(key: key);

  @override
  State<PoUnapproved2> createState() => _PoUnapproved2State();
}

class _PoUnapproved2State extends State<PoUnapproved2> {
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
  static TextControllers textControllers = Get.put(TextControllers());
  double sTTL = 0;
  double dTTL = 0;
  double sTAX = 0;
  String dTAX = '';
  double ppn = 0;
  double pph = 0;
  double otax = 0;
  double othexpen = 0;
  double nTTL = 0;
  double gTTL = 0;

  static const _statusActions = [
    ApprovalActionMeta(label: 'Pending', icon: Icons.hourglass_empty_rounded, color: Color(0xFF9E9E9E)),
    ApprovalActionMeta(label: 'Approve', icon: Icons.check_circle_outline_rounded, color: Color(0xFFF4A62A)),
    ApprovalActionMeta(label: 'Send To Draft', icon: Icons.edit_note_outlined, color: Color(0xFFFF9800)),
  ];

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  void _onStatusSelected(String status) {
    setState(() {
      valueStatus = status;
      if (status == "Pending") { updstatus = "0"; isVisible = false; }
      else if (status == "Approve") { updstatus = "1"; isVisible = true; }
      else if (status == "Send To Draft") { updstatus = "-9"; isVisible = true; }
    });
  }
  List<ApprovalInfoField> _itemDetailFields(dynamic e) {
    return [
      ApprovalInfoField('Type', (e['tipe'] == 0 ? 'SPPBJ' : 'Other Income/Expenses').toString()),
      ApprovalInfoField('SPPBJ No', (e['sppbjno'] ?? '').toString()),
      ApprovalInfoField('Item Coa', (e['itemcoa'] ?? '').toString()),
      ApprovalInfoField('Item Name', (e['itemname'] ?? '').toString()),
      ApprovalInfoField('Project ID', (e['projectid'] ?? '').toString()),
      ApprovalInfoField('Desc', (e['ket'] ?? '').toString()),
      ApprovalInfoField('Unit', (e['unit'] ?? '').toString()),
      ApprovalInfoField('QTY', (e['qty'].toString())),
      ApprovalInfoField('Price /Unit', (ApprovalTheme.currencyFmt.format(e['harga'])).toString()),
      ApprovalInfoField('Amount', (ApprovalTheme.currencyFmt.format(e['harga'] * e['qty'])).toString()),
      ApprovalInfoField('Disc(%)', ('${e['disc']}%').toString()),
      ApprovalInfoField('Tax Amt', (ApprovalTheme.currencyFmt.format(e['taxAmount'])).toString()),
      ApprovalInfoField('Total', (ApprovalTheme.currencyFmt.format(e['harga'] * e['qty'] + e['taxAmount'])).toString()),
      ApprovalInfoField('in IDR', (ApprovalTheme.currencyFmt.format(e['amtidr'])).toString()),
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
        docNo: widget.pono ?? '',
        subtitle: _formattedDate,
        onBack: () => Get.to(() => PoUnapproved()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.requestorname ?? '-',
          fields: [
            ApprovalInfoField('Request By', widget.requestorname ?? '-'),
            ApprovalInfoField('Supplier', widget.supplier ?? '-'),
          ],
        ),
        actionSection: ApprovalActionGrid(actions: _statusActions, selectedLabel: valueStatus, onSelected: _onStatusSelected),
        body: _buildBody(),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: gTTL, itemCount: dataaa.length,
          selectedAction: hasAction ? valueStatus : null,
          actionColor: hasAction ? ApprovalTheme.primary : null,
          idleHint: 'Select an action to continue',
          onSubmit: hasAction ? () { if (updstatus == '-9') { reason(); } else { submitData(); } } : null,
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
  //       Uri.https('v2rp.net',
  //           '/api/v1/mobile/approval/supplier/pononscm/' + widget.seckey),
  //       headers: {
  //         'Content-Type': 'application/json; charset=utf-8',
  //         'kulonuwun': finalKulonuwun ?? kulonuwun,
  //         'monggo': finalMonggo ?? monggo,
  //       },
  //     );
  //     final caConfirmData = json.decode(getData.body);
  //     print("response " + caConfirmData.toString());
  //     dataaa = caConfirmData['data']['detail'];
  //     print("dataaa " + dataaa.toString());
  //     if (dataaa.isEmpty) {
  //       var getData = await http.get(
  //         Uri.https('v2rp.net',
  //             '/api/v1/mobile/approval/supplier/poscm/' + widget.seckey),
  //         headers: {
  //           'Content-Type': 'application/json; charset=utf-8',
  //           'kulonuwun': finalKulonuwun ?? kulonuwun,
  //           'monggo': finalMonggo ?? monggo,
  //         },
  //       );
  //       final caConfirmData = json.decode(getData.body);
  //       print("response " + caConfirmData.toString());
  //       dataaa = caConfirmData['data']['detail'];
  //       print("dataaa " + dataaa.toString());
  //     }
  //     return dataaa;
  //   } catch (e) {
  //     print(e);
  //   }
  // }

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
            '/api/v1/mobile/approval/supplier/poscm/' + widget.seckey),
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
      print("response " + caConfirmData.toString());
      dataaa = caConfirmData!['data']['detail'] ?? [];
      print("dataaa " + dataaa.toString());

      if (dataaa.isEmpty) {
        var getData = await http.get(
          Uri.https('v2rp.net',
              '/api/v1/mobile/approval/supplier/pononscm/' + widget.seckey),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'kulonuwun': finalKulonuwun ?? kulonuwun,
            'monggo': finalMonggo ?? monggo,
          },
        );
        final caConfirmData = json.decode(getData.body);
        print("response " + caConfirmData.toString());
        dataaa = caConfirmData['data']['detail'];
        print("dataaa " + dataaa.toString());
      }

      //hitung total
      sTTL = 0;
      // dTTL = 0;
      sTAX = 0;
      dTAX = '';
      nTTL = 0;
      gTTL = 0;
      for (var item in dataaa) {
        final qty = approvalToDouble(item["qty"]);
        final harga = approvalToDouble(item["harga"]);
        sTTL += harga * qty;

        sTAX += approvalToDouble(item["taxAmount"]);
        if (item["tax"] == ':0') {
          dTAX == '0';
          print("dTaxzzzzzzz  " + dTAX.toString());
        } else {
          dTAX = item["tax"];
          print("dTaxx  " + dTAX.toString());
        }

        var listtax = dTAX.split(",");

        for (var xx = 0; xx < listtax.length; xx++) {
          var snil = listtax[xx].split(":");
          if (dTAX != "") {
            if (snil.isNotEmpty) {
              if (snil[0].substring(0, 1) == "0") {
                ppn += double.parse(snil[1]);
              } else if (snil[0].substring(0, 1) == "1") {
                pph += double.parse(snil[1]);
              } else {
                otax += double.parse(snil[1]);
              }
            }
          }
        }
        nTTL = sTTL; //sTTL
        gTTL = nTTL + sTAX; //nTTL + sTAX
      }

      // });
      print("totalllll  " + sTTL.toString());
      print("dTax  " + dTAX.toString());

      if (mounted) setState(() {});
      return dataaa;
    } catch (e) {
      print(e);
    }
  }

//----------------------------------------------------------------
  Future<void> submitData() async {
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
    //   "urutan": selectedDetails,
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
      var sendData = await http.put(
        Uri.https(
          'v2rp.net',
          '/api/v1/mobile/approval/supplier/poscm/' +
              widget.seckey +
              '/' +
              updstatus,
        ),
        // body: body,
        headers: {
          'Content-type': 'application/json',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );
      // print("selected = " +
      //     selectedDetails.toString() +
      //     selectedDetails.runtimeType.toString());
      final response = json.decode(sendData.body);
      print(response.toString());
      setState(() {
        status = response['success'];
        messageError = response['message'];
        message = response['data']['message'] ?? '';
      });
      if (status == false) {
        var sendData = await http.put(
          Uri.https(
            'v2rp.net',
            '/api/v1/mobile/approval/supplier/pononscm/' +
                widget.seckey +
                '/' +
                updstatus,
          ),
          // body: body,
          headers: {
            'Content-type': 'application/json',
            'kulonuwun': finalKulonuwun ?? kulonuwun,
            'monggo': finalMonggo ?? monggo,
          },
        );
        final response = json.decode(sendData.body);
        print(response.toString());
        setState(() {
          status = response['success'];
          messageError = response['message'];
          message = response['data']['message'] ?? '';
        });
      }
      if (status == true) {
        // setState(() {
        //   message = response['data']['message'];
        // });
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            disableBackBtn: true,
            text: 'Success $message Data!',
            barrierDismissible: false,
            // confirmBtnText: 'OK',
            onConfirmBtnTap: () async {
              Get.to(() => PoUnapproved());
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
          title: 'Failed! ' + widget.pono,
          text: '$message',
          barrierDismissible: false,
          onConfirmBtnTap: () async {
            Get.to(() => PoUnapproved());
          },
        );
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        disableBackBtn: true,
        title: 'Error! ' + widget.pono,
        text: '$messageError',
        onConfirmBtnTap: () async {
          Get.to(() => PoUnapproved());
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
          prefixIcon: Icon(Icons.text_snippet_rounded),
        ),
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.text,
        controller: textControllers.PoUnapprovedControllerReason.value,
      ),
      onConfirmBtnTap: () {
        submitData();
      },
    );
    textControllers.PoUnapprovedControllerReason.value.clear();
  }
}
