import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/BE/notif_type.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:http/http.dart' as http;

import '../../../../../BE/controller.dart';
import '../../../../../BE/reqip.dart';
import '../../../../../main.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/po_ex_approval/poex_app2.dart';

class PoExApp extends StatefulWidget {
  PoExApp({Key? key}) : super(key: key);

  @override
  State<PoExApp> createState() => _PoExAppState();
}

class _PoExAppState extends State<PoExApp> {
  static TextControllers textControllers = Get.put(TextControllers());
  List _allItems = [];
  List _foundUsers = [];
  late Future dataFuture;
  String _typeFilter = 'ALL'; // ALL | POE | PNE

  static const _listEndpoints = <String, String>{
    NotifType.poe: '/api/v1/mobile/approval/exeption/poscm/',
    NotifType.pne: '/api/v1/mobile/approval/exeption/pononscm/',
  };

  @override
  void initState() {
    super.initState();
    dataFuture = getDataa();
  }

  String _itemType(dynamic item) {
    if (item is! Map) return '';
    final header = _headerOf(item);
    return (item['type'] ?? header['type'] ?? '').toString().trim().toUpperCase();
  }

  int _countFor(String type) {
    if (type == 'ALL') return _allItems.length;
    return _allItems.where((item) => _itemType(item) == type).length;
  }

  void _applyFilters([String? enteredKeyword]) {
    final keyword = (enteredKeyword ??
            textControllers.poexAppController.value.text)
        .trim()
        .toLowerCase();

    var results = _allItems.where((item) {
      if (_typeFilter != 'ALL' && _itemType(item) != _typeFilter) {
        return false;
      }
      if (keyword.isEmpty) return true;
      final header = _headerOf(item);
      return header['pono'].toString().toLowerCase().contains(keyword);
    }).toList();

    setState(() => _foundUsers = results);
  }

  void _runFilter(String enteredKeyword) => _applyFilters(enteredKeyword);

  void _setTypeFilter(String type) {
    if (_typeFilter == type) return;
    _typeFilter = type;
    _applyFilters();
  }

  Widget _buildTypeFilter() {
    Widget chip({
      required String id,
      required String label,
      required int count,
    }) {
      final selected = _typeFilter == id;
      return FilterChip(
        selected: selected,
        showCheckmark: false,
        label: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
        selectedColor: ApprovalTheme.primary,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? ApprovalTheme.primary : Colors.grey.shade300,
        ),
        onSelected: (_) => _setTypeFilter(id),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(id: 'ALL', label: 'All', count: _countFor('ALL')),
          const SizedBox(width: 8),
          chip(
            id: NotifType.poe,
            label: 'PO SCM',
            count: _countFor(NotifType.poe),
          ),
          const SizedBox(width: 8),
          chip(
            id: NotifType.pne,
            label: 'PO Non SCM',
            count: _countFor(NotifType.pne),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _headerOf(dynamic item) {
    if (item is! Map) return <String, dynamic>{};
    final header = item['header'];
    if (header is Map) return Map<String, dynamic>.from(header);
    return Map<String, dynamic>.from(item);
  }

  String _resolveType(Map<String, dynamic> item, String fallbackType) {
    final fromItem = item['type']?.toString().trim().toUpperCase();
    if (fromItem == NotifType.poe || fromItem == NotifType.pne) {
      return fromItem!;
    }
    final header = _headerOf(item);
    final fromHeader = header['type']?.toString().trim().toUpperCase();
    if (fromHeader == NotifType.poe || fromHeader == NotifType.pne) {
      return fromHeader!;
    }
    return fallbackType;
  }

  List<dynamic> _normalizeItems(dynamic rawData, String fallbackType) {
    if (rawData is! List) return <dynamic>[];

    return rawData.whereType<Map>().map((rawItem) {
      final item = Map<String, dynamic>.from(rawItem);
      final type = _resolveType(item, fallbackType);
      final header = _headerOf(item);
      header['requestorname'] ??= header['requestor'];
      header['type'] = type;
      item['header'] = header;
      item['type'] = type;
      return item;
    }).toList();
  }

  void _openDetail(dynamic item) {
    final header = _headerOf(item);
    final type = (item['type'] ?? header['type'] ?? NotifType.poe).toString();
    Get.to(() => PoExApp2(
          seckey: item['seckey'],
          pono: header['pono'],
          tanggal: header['tanggal'],
          requestor: header['requestorname'] ?? header['requestor'],
          projectid: header['projectid'],
          itemcoa: header['itemcoa'],
          sppbjamount: header['sppbjamount'],
          poamount: header['poamount'],
          different: header['different'],
          budgetavailable: approvalBudgetAvailable(header),
          type: type,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeFilter(),
            const SizedBox(height: 12),
            if (_foundUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No documents found',
                      style: TextStyle(color: Colors.grey.shade500)),
                ),
              )
            else
              ..._foundUsers.map((item) {
                final header = _headerOf(item);
                final type = _itemType(item);
                final date =
                    DateTime.tryParse(header['tanggal']?.toString() ?? '');
                final requestor =
                    header['requestorname'] ?? header['requestor'] ?? '';
                final dateLabel = date == null
                    ? '-'
                    : DateFormat('dd MMM yyyy').format(date);
                return ApprovalListCard(
                  title: header['pono']?.toString() ?? '-',
                  subtitle:
                      '${NotifType.poExceptionLabel(type)} · $requestor · $dateLabel',
                  onTap: () => _openDetail(item),
                );
              }),
          ],
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

  Future<Map<String, String>> _authHeaders() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    final finalKulonuwun = sharedPreferences.getString('kulonuwun');
    final finalMonggo = sharedPreferences.getString('monggo');
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'kulonuwun': finalKulonuwun ?? MsgHeader.kulonuwun,
      'monggo': finalMonggo ?? MsgHeader.monggo,
    };
  }

  Future<void> getDataa() async {
    HttpOverrides.global = MyHttpOverrides();
    final headers = await _authHeaders();

    try {
      final responses = await Future.wait(
        _listEndpoints.entries.map(
          (entry) => http.get(
            Uri.https('v2rp.net', entry.value),
            headers: headers,
          ),
        ),
      );

      final merged = <dynamic>[];
      var index = 0;
      for (final entry in _listEndpoints.entries) {
        final decoded = json.decode(responses[index].body);
        merged.addAll(_normalizeItems(decoded['data'], entry.key));
        index++;
      }

      if (!mounted) return;
      setState(() {
        _allItems = merged;
      });
      _applyFilters();
    } catch (e) {
      print(e);
    }
  }

  Future<void> getDataa2() async => getDataa();
}
