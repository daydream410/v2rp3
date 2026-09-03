// ignore_for_file: avoid_print

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
import 'package:v2rp3/FE/approval_screen/purchase_approval/po_ex_approval/poex_app.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;
import 'package:v2rp3/BE/controller.dart';
import 'package:v2rp3/BE/approval_notif_controller.dart';

import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import '../../../../main.dart';

class PoExApp2 extends StatefulWidget {
  final seckey;
  final pono;
  final tanggal;
  final requestor;
  final projectid;
  final itemcoa;
  final sppbjamount;
  final poamount;
  final different;
  final budgetavailable;
  final tipe;

  PoExApp2({
    Key? key,
    required this.seckey,
    required this.pono,
    required this.tanggal,
    required this.requestor,
    required this.projectid,
    required this.itemcoa,
    required this.sppbjamount,
    required this.poamount,
    required this.different,
    required this.budgetavailable,
    required this.tipe,
  }) : super(key: key);

  @override
  State<PoExApp2> createState() => _PoExApp2State();
}

class _PoExApp2State extends State<PoExApp2> {
  static late List dataaa = <CaConfirmData>[];
  late Future dataFuture;
  @override
  void initState() {
    super.initState();
    dataFuture = getDataa();
  }

  static TextControllers textControllers = Get.put(TextControllers());
  List selectedDetails = [];
  bool selectedGak = false;
  double totalPrice = 0;
  var valueButton;
  String reasonValue = '';
  String _selectionAction = '';
  static const _selectionActions = [
    ApprovalActionMeta(label: 'Send To Draft (ALL)', icon: Icons.edit_note_outlined, color: Color(0xFFFF9800)),
  ];

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  void _onSelectionAction(String label) {
    setState(() {
      _selectionAction = label;
      if (label == 'Send To Draft (ALL)') valueButton = '-9';
    });
  }
  List<ApprovalInfoField> _itemDetailFields(dynamic e) {
    return [
      ApprovalInfoField('SPPBJ No', (e['sppbjno'] ?? '').toString()),
      ApprovalInfoField('Item COA', (e['itemcoa'] ?? '').toString()),
      ApprovalInfoField('Item Name', (e['itemname'] ?? '').toString()),
      ApprovalInfoField('Remarks', (e['ket'] ?? '').toString()),
      ApprovalInfoField('Unit', (e['unit'].toString())),
      ApprovalInfoField('QTY', (e['qty'].toString())),
      ApprovalInfoField('Price', (ApprovalTheme.currencyFmt.format(double.parse(e['harga']))).toString()),
      ApprovalInfoField('Amount', (ApprovalTheme.currencyFmt.format(double.parse(e['amount']))).toString()),
      ApprovalInfoField('Disc', ('${double.parse(e['disc']) / 100}%').toString()),
      ApprovalInfoField('Tax', (ApprovalTheme.currencyFmt.format(double.parse( e['taxAmount'].toString())))),
      ApprovalInfoField('Total', (ApprovalTheme.currencyFmt.format(double.parse(e['qty']) * double.parse(e['harga']) + double.parse( e['taxAmount'].toString())))),
      ApprovalInfoField('Budget Avail', (ApprovalTheme.currencyFmt.format(approvalBudgetAvailable(e)))),
      ApprovalInfoField('Project', (e['projectname'] ?? e['projectid'] ?? '').toString()),
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
          selectable: true,
          isRowSelected: (i) =>
              selectedDetails.contains(dataaa[i]['urutan']),
          onRowSelectionChanged: (i, v) {
            setState(() {
              final id = dataaa[i]['urutan'];
              if (v == true) {
                selectedDetails.add(id);
                selectedGak = true;
              } else {
                selectedDetails.remove(id);
                if (selectedDetails.isEmpty) {
                  selectedGak = false;
                  _selectionAction = '';
                }
              }
            });
          },
          tableRows: [
            for (var i = 0; i < dataaa.length; i++)
              _itemDetailFields(dataaa[i]),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedGak;
    final displayAction = _selectionAction.isNotEmpty ? _selectionAction : 'Approve All';
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
        onBack: () => Get.to(() => PoExApp()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.requestor ?? '-',
          fields: [
            ApprovalInfoField('Project', widget.projectid ?? '-'),
            ApprovalInfoField('Request By', widget.requestor ?? '-'),
            ApprovalInfoField(
              'Budget Available',
              ApprovalTheme.currencyFmt.format(
                approvalToDouble(widget.budgetavailable),
              ),
            ),
          ],
        ),
        actionSection: hasSelection ? ApprovalActionGrid(
          actions: _selectionActions, selectedLabel: _selectionAction, onSelected: _onSelectionAction,
        ) : null,
        body: _buildBody(),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: totalPrice, itemCount: dataaa.length,
          selectedAction: hasSelection ? displayAction : null,
          actionColor: hasSelection ? (_selectionAction.isNotEmpty
              ? ApprovalActions.colorFor(_selectionAction, _selectionActions) : ApprovalTheme.primary) : null,
          submitLabel: _selectionAction.isNotEmpty ? 'Submit' : 'Approve All',
          idleHint: 'Select items to continue',
          onSubmit: hasSelection ? () {
            if (_selectionAction.contains('Draft') || _selectionAction.contains('Reject')) reason();
            else { setState(() => valueButton = '1'); submitData(); }
          } : null,
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
        //     '/api/v1/mobile/approval/exeption/poscm/' + widget.seckey),
        Uri.https('v2rp.net',
            '/api/v1/mobile/approval/exeption/pononscm/' + widget.seckey),
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
      dataaa = caConfirmData['data']['details'];
      print("dataaa " + dataaa.toString());
      if (dataaa.isEmpty) {
        var getData = await http.get(
          Uri.https('v2rp.net',
              '/api/v1/mobile/approval/exeption/poscm/' + widget.seckey),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'kulonuwun': finalKulonuwun ?? kulonuwun,
            'monggo': finalMonggo ?? monggo,
          },
        );
        final caConfirmData = json.decode(getData.body);
        print("response " + caConfirmData.toString());
        dataaa = caConfirmData['data']['details'];
        print("dataaa " + dataaa.toString());
      }
      totalPrice = approvalSumField(dataaa, 'amount');
      // print(dTax);
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

    var body = json.encode({
      "urutan": selectedDetails,
      "reason": textControllers.poexAppControllerReason.value.text,
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
      var sendData = await http.put(
        Uri.https(
          'v2rp.net',
          '/api/v1/mobile/approval/exeption/poscm/' +
              widget.seckey +
              '/' +
              valueButton,
        ),
        body: body,
        headers: {
          'Content-type': 'application/json',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );
      print("selected = " +
          selectedDetails.toString() +
          selectedDetails.runtimeType.toString());
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
            '/api/v1/mobile/approval/exeption/pononscm/' +
                widget.seckey +
                '/' +
                valueButton,
          ),
          body: body,
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
        approvalRefreshMenuCounts();
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            disableBackBtn: true,
            text: 'Success $message Data!',
            barrierDismissible: false,
            // confirmBtnText: 'OK',
            onConfirmBtnTap: () async {
              Get.to(() => PoExApp());
            },
            showCancelBtn: true,
            cancelBtnText: 'Home',
            onCancelBtnTap: () async {
              Get.to(const Navbar());
            });
      } else {
        // setState(() {
        //   message = response['data']['message'];
        // });
        await Future.delayed(const Duration(milliseconds: 1000));
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          disableBackBtn: true,
          title: 'Failed! ' + widget.pono,
          text: '$message',
          barrierDismissible: false,
          onConfirmBtnTap: () async {
            Get.to(() => PoExApp());
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
          Get.to(() => PoExApp());
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
        controller: textControllers.poexAppControllerReason.value,
      ),
      onConfirmBtnTap: () {
        print(textControllers.poexAppControllerReason.value.text);
        submitData();
      },
    );
    textControllers.poexAppControllerReason.value.clear();
  }
}
