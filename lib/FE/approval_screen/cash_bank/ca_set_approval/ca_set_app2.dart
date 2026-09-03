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
import 'package:v2rp3/FE/approval_screen/cash_bank/ca_set_approval/ca_set_app.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;
import 'package:v2rp3/BE/controller.dart';
import 'package:v2rp3/routes/api_name.dart';
import 'package:v2rp3/BE/approval_notif_controller.dart';

import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import '../../../../main.dart';

class CaSetApproval2 extends StatefulWidget {
  final seckey;
  final lpjk;
  final ket;
  final tanggal;
  final requestorname;
  CaSetApproval2({
    Key? key,
    required this.seckey,
    required this.lpjk,
    required this.ket,
    required this.tanggal,
    required this.requestorname,
  }) : super(key: key);

  @override
  State<CaSetApproval2> createState() => _CaSetApproval2State();
}

class _CaSetApproval2State extends State<CaSetApproval2> {
  static late List dataaa = <CaConfirmData>[];
  late Future dataFuture;
  @override
  void initState() {
    super.initState();
    dataFuture = getDataa();
  }

  List selectedDetails = [];
  bool selectedGak = false;
  double totalPrice = 0;
  var valueButton;
  static TextControllers textControllers = Get.put(TextControllers());
  String reasonValue = '';
  String _selectionAction = '';
  static const _selectionActions = [
    ApprovalActionMeta(label: 'Reject Selected', icon: Icons.cancel_outlined, color: Color(0xFFE53935)),
    ApprovalActionMeta(label: 'Send To Draft (ALL)', icon: Icons.edit_note_outlined, color: Color(0xFFFF9800)),
  ];

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  void _onSelectionAction(String label) {
    setState(() {
      _selectionAction = label;
      if (label == 'Reject Selected') valueButton = '-1';
      else if (label == 'Send To Draft (ALL)') valueButton = '-9';
    });
  }
  List<ApprovalInfoField> _itemDetailFields(dynamic e) {
    return [
      ApprovalInfoField('CA No', (e['nokasbon'] ?? '').toString()),
      ApprovalInfoField('Project Name', approvalProjectName(e)),
      ApprovalInfoField('Project ID', approvalProjectId(e)),
      ApprovalInfoField('Req By', (e['requestorname'] ?? '').toString()),
      ApprovalInfoField('Type', approvalCashAdvanceTypeLabel(e['tipe'])),
      ApprovalInfoField('Acc Name', approvalAccountName(e)),
      ApprovalInfoField('Desc', e['ket']?.toString() ?? '-'),
      ApprovalInfoField('QTY', (e['qty'].toString())),
      ApprovalInfoField('Price', (ApprovalTheme.currencyFmt.format(e['harga'])).toString()),
      ApprovalInfoField('Amount', (ApprovalTheme.currencyFmt.format(e['amount'])).toString()),
      ApprovalInfoField('Buget Avail', (ApprovalTheme.currencyFmt.format(approvalBudgetAvailable(e))).toString()),
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
        docNo: widget.lpjk ?? '',
        subtitle: _formattedDate,
        onBack: () => Get.to(() => CaSetApproval()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.requestorname ?? '-',
          fields: [
            ApprovalInfoField('Date', _formattedDate),
            ApprovalInfoField('Request By', widget.requestorname ?? '-'),
          ],
          reason: widget.ket,
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
        // Uri.http(
        //     '156.67.217.113', ApiName.lpjkApp + widget.seckey),
        Uri.https(ApiName.v2rp, ApiName.lpjkApp + widget.seckey),
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
    // var reffno;
    var message;
    var messageError;

    var body = json.encode({
      "urutan": selectedDetails,
      "reason": textControllers.caSetAppControllerReason.value.text,
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
          ApiName.v2rp,
          ApiName.lpjkApp + widget.seckey + '/' + valueButton,
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
      // print("urutan = " + urutan.toString() + urutan.runtimeType.toString());
      final response = json.decode(sendData.body);
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
              Get.to(() => CaSetApproval());
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
          title: 'Failed! ' + widget.lpjk,
          text: '$message',
          onConfirmBtnTap: () async {
            Get.to(() => CaSetApproval());
          },
        );
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        disableBackBtn: true,
        title: 'Error! ' + widget.lpjk,
        text: '$messageError',
        onConfirmBtnTap: () async {
          Get.to(() => CaSetApproval());
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
        controller: textControllers.caSetAppControllerReason.value,
      ),
      onConfirmBtnTap: () {
        print(textControllers.caSetAppControllerReason.value.text);
        submitData();
      },
    );
    textControllers.caSetAppControllerReason.value.clear();
  }
}
