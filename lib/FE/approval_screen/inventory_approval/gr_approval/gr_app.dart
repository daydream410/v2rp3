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
import '../../../../../BE/controller.dart';
import '../../../../../BE/reqip.dart';
import '../../../../../BE/resD.dart';
import '../../../../../main.dart';
import 'gr_app2.dart';

class GrApp extends StatefulWidget {
  GrApp({Key? key}) : super(key: key);

  @override
  State<GrApp> createState() => _GrAppState();
}

class _GrAppState extends State<GrApp> {
  static TextControllers textControllers = Get.put(TextControllers());
  static late List dataaa = <CaConfirmData>[];
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
      results = dataaa;
    } else {
      results = dataaa
          .where((item) => item['header']['grno']
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() => _foundUsers = results);
  }

  void _openDetail(dynamic item) {
    Get.to(() => GrApp2(
                                              seckey: item
                                                  ['seckey'],
                                              grno: item['header']
                                                  ['grno'],
                                              tanggal: item
                                                  ['header']['tanggal'],
                                              requestorname: item
                                                  ['header']['requestorname'],
                                              locationname: item
                                                  ['header']['locationname'],
                                              suppliername: item
                                                  ['header']['suppliername'],
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
              title: header['grno']?.toString() ?? '-',
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
        title: 'Goods Received Approval',
        onBack: () => Get.to(const Navbar()),
        searchController: textControllers.grAppController.value,
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
      // http://156.67.217.113/api/v1/mobile
      var getData = await http.get(
        // Uri.http('156.67.217.113', '/api/v1/mobile/approval/goodreceive'),
        Uri.https(ApiName.v2rp, ApiName.grApp),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );
      final caConfirmData = json.decode(getData.body);

      // final data = caConfirmData['data'];
      setState(() {
        dataaa = caConfirmData['data'];
        _foundUsers = dataaa;
      });

      print("getdataaaa " + caConfirmData.toString());
      print("dataaaaaaaaaaaaaaa " + dataaa.toString());
    } catch (e) {
      print(e);
    }
  }
  Future<void> getDataa2() async => getDataa();
}
