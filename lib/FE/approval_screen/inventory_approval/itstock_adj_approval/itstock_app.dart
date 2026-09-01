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
import 'package:v2rp3/routes/api_name.dart';

import '../../../../BE/controller.dart';
import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import '../../../../main.dart';
import 'itstock_app2.dart';

class ItStockAdjApp extends StatefulWidget {
  ItStockAdjApp({Key? key}) : super(key: key);

  @override
  State<ItStockAdjApp> createState() => _ItStockAdjAppState();
}

class _ItStockAdjAppState extends State<ItStockAdjApp> {
  static TextControllers textControllers = Get.put(TextControllers());
  static late List dataaa = <CaConfirmData>[];
  static late List dataaa2 = <CaConfirmData>[];
  static late List gabung = <CaConfirmData>[];
  static late List _foundUsers = <CaConfirmData>[];
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
          .where((item) => item['header']['reffno']
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() => _foundUsers = results);
  }

  void _openDetail(dynamic item) {
    Get.to(() => ItStockAdjApp2(
          seckey: item['seckey'],
          reffno: item['header']['reffno'],
          warehouse: item['header']['towh'],
          tanggal: item['header']['tanggal'],
          requestor: item['header']['requestor'],
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
              title: header['reffno']?.toString() ?? '-',
              subtitle:
                  "${header['requestor'] ?? ''} · ${DateFormat('dd MMM yyyy').format(DateTime.parse(header['tanggal']))}",
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
        title: 'IT/Stock Adjustment Approval',
        onBack: () => Get.to(const Navbar()),
        searchController: textControllers.itstockadjAppController.value,
        onSearchChanged: _runFilter,
        onRefresh: getDataa2,
        child: _buildList(),
      ),
    );
  }

  Future<void> _fetchData() async {
    HttpOverrides.global = MyHttpOverrides();
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    var finalKulonuwun = sharedPreferences.getString('kulonuwun');
    var finalMonggo = sharedPreferences.getString('monggo');
    var kulonuwun = MsgHeader.kulonuwun;
    var monggo = MsgHeader.monggo;

    var getData = await http.get(
      Uri.https(ApiName.v2rp, ApiName.itAdj),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'kulonuwun': finalKulonuwun ?? kulonuwun,
        'monggo': finalMonggo ?? monggo,
      },
    );
    var getData2 = await http.get(
      Uri.http(ApiName.v2rp, ApiName.stockAdj),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'kulonuwun': finalKulonuwun ?? kulonuwun,
        'monggo': finalMonggo ?? monggo,
      },
    );
    final responseData = json.decode(getData.body);
    final responseData2 = json.decode(getData2.body);

    setState(() {
      dataaa = responseData['data'];
      dataaa2 = responseData2['data'];
      gabung = dataaa + dataaa2;
      _foundUsers = gabung;
    });
  }

  Future<void> getDataa() async {
    try {
      await _fetchData();
    } catch (e) {
      print(e);
    }
  }

  Future<void> getDataa2() async => getDataa();
}
