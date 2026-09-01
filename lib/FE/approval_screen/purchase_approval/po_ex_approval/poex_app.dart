import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:http/http.dart' as http;

import '../../../../../BE/controller.dart';
import '../../../../../BE/reqip.dart';
import '../../../../../BE/resD.dart';
import '../../../../../main.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/po_ex_approval/poex_app2.dart';

class PoExApp extends StatefulWidget {
  PoExApp({Key? key}) : super(key: key);

  @override
  State<PoExApp> createState() => _PoExAppState();
}

class _PoExAppState extends State<PoExApp> {
  static TextControllers textControllers = Get.put(TextControllers());
  static late List dataaa = <CaConfirmData>[];
  static late List dataaa2 = <CaConfirmData>[];
  static late List gabung = <CaConfirmData>[];
  static late List _foundUsers = <CaConfirmData>[];
  var tipe = '0';
  late Future dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = getDataa();
  }

  void _runFilter(String enteredKeyword) {
    List results = [];
    if (enteredKeyword.isEmpty) {
      results = gabung;
    } else {
      results = gabung
          .where((item) => item['header']['pono']
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() => _foundUsers = results);
  }

  void _openDetail(dynamic item) {
    Get.to(() => PoExApp2(
                                              seckey: item
                                                  ['seckey'],
                                              pono: item['header']
                                                  ['pono'],
                                              tanggal: item
                                                  ['header']['tanggal'],
                                              requestor: item
                                                  ['header']['requestor'],
                                              projectid: item
                                                  ['header']['projectid'],
                                              itemcoa: item
                                                  ['header']['itemcoa'],
                                              sppbjamount: item
                                                  ['header']['sppbjamount'],
                                              poamount: item
                                                  ['header']['poamount'],
                                              different: item
                                                  ['header']['different'],
                                              budgetavailable:
                                                  item['header']
                                                          ['budget']
                                                      ['budgetavailable'],
                                              tipe: tipe,
                                            ));
  }

  Widget _buildList() {
    return FutureBuilder(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error Loading Data'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: ApprovalTheme.primary),
            ),
          );
        }
        if (_foundUsers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No documents found',
                  style: TextStyle(color: Colors.grey.shade500)),
            ),
          );
        }
        return Column(
          children: _foundUsers.map<Widget>((item) {
            final header = item['header'];
            return ApprovalListCard(
              title: header['pono']?.toString() ?? '-',
              subtitle:
                  "${header['requestorname'] ?? ''} · ${DateFormat('dd MMM yyyy').format(DateTime.parse(header['tanggal']))}",
              onTap: () => _openDetail(item),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are You sure?'),
            content: const Text('Do you want to exit V2RP Mobile?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (shouldPop == true) SystemNavigator.pop();
        return false;
      },
      child: ApprovalListScaffold(
        title: 'PO Exception Approval',
        onBack: () => Get.to(const Navbar()),
        searchController: textControllers.poexAppController.value,
        onSearchChanged: _runFilter,
        onRefresh: getDataa2,
        child: _buildList(),
      ),
    );
  }

  Future<void> getDataa() async {
    HttpOverrides.global = MyHttpOverrides();
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    var finalKulonuwun = sharedPreferences.getString('kulonuwun');
    var finalMonggo = sharedPreferences.getString('monggo');
    var kulonuwun = MsgHeader.kulonuwun;
    var monggo = MsgHeader.monggo;

    try {
      var getData = await http.get(
        // Uri.http('156.67.217.113', '/api/v1/mobile/approval/exeption/poscm/'),
        Uri.https('v2rp.net', '/api/v1/mobile/approval/exeption/poscm/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );
      var getData2 = await http.get(
        // Uri.http('156.67.217.113', '/api/v1/mobile/approval/exeption/poscm/'),
        Uri.https('v2rp.net', '/api/v1/mobile/approval/exeption/pononscm/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );
      final responseData = json.decode(getData.body);
      final responseData2 = json.decode(getData2.body);

      // final data = responseData['data'];
      setState(() {
        dataaa = responseData['data'];
        dataaa2 = responseData2['data'];
        gabung = dataaa + dataaa2;
        _foundUsers = gabung;
        tipe = '0';
      });

      if (dataaa.isNotEmpty) {
        setState(() {
          tipe = '0';
        });
      } else {
        setState(() {
          tipe = '1';
        });
      }

      // print("getdataaaa " + responseData.toString());
      print("dataaaaaaaaaaaaaaa " + dataaa.toString());
      print("data2 " + dataaa2.toString());
      print("gabung " + gabung.toString());
      print("tipe " + tipe.toString());
    } catch (e) {
      print(e);
    }
  }
  Future<void> getDataa2() async => getDataa();
}
