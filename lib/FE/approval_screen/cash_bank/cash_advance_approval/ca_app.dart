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
import 'package:v2rp3/FE/approval_screen/cash_bank/cash_advance_approval/ca_app2.dart';
import 'dart:async';

class CashAdvanceApproval extends StatefulWidget {
  CashAdvanceApproval({Key? key}) : super(key: key);

  @override
  State<CashAdvanceApproval> createState() => _CashAdvanceApprovalState();
}

class _CashAdvanceApprovalState extends State<CashAdvanceApproval> {
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
          .where((item) => item['header']['nokasbon']
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() => _foundUsers = results);
  }

  void _openDetail(dynamic item) {
    Get.to(() => CashAdvanceApproval2(
                                              seckey: item
                                                  ['seckey'],
                                              nokasbon: item
                                                  ['header']['nokasbon'],
                                              ket: item['header']
                                                  ['ket'],
                                              tanggal: item
                                                  ['header']['tanggal'],
                                              requestorname: item
                                                  ['header']['requestorname'],
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
              title: header['nokasbon']?.toString() ?? '-',
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
        title: 'Cash Advance Approval',
        onBack: () => Get.to(const Navbar()),
        searchController: textControllers.caConfirmController.value,
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
        Uri.https(ApiName.v2rp, ApiName.kasbonApp),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timeout. Please try again.');
        },
      );
      final responseData = json.decode(getData.body);

      // final data = responseData['data'];
      setState(() {
        dataaa = responseData['data'] ?? [];
        _foundUsers = dataaa;
      });

      // print("getdataaaa " + responseData.toString());
      print("dataaaaaaaaaaaaaaa " + dataaa.toString());
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      setState(() {
        dataaa = [];
        _foundUsers = [];
      });
    } on SocketException catch (e) {
      print('Network error: $e');
      setState(() {
        dataaa = [];
        _foundUsers = [];
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        dataaa = [];
        _foundUsers = [];
      });
    }
  }
  Future<void> getDataa2() async {
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
        // Uri.http('156.67.217.113', '/api/v1/mobile/approval/kasbon/'),
        Uri.https(ApiName.v2rp, ApiName.kasbonApp),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timeout. Please try again.');
        },
      );
      final responseData = json.decode(getData.body);

      // final data = responseData['data'];
      setState(() {
        dataaa = responseData['data'] ?? [];
        _foundUsers = dataaa;
      });

      // print("getdataaaa " + responseData.toString());
      print("dataaaaaaaaaaaaaaa " + dataaa.toString());
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      setState(() {
        dataaa = [];
        _foundUsers = [];
      });
    } on SocketException catch (e) {
      print('Network error: $e');
      setState(() {
        dataaa = [];
        _foundUsers = [];
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        dataaa = [];
        _foundUsers = [];
      });
    }
  }
}
