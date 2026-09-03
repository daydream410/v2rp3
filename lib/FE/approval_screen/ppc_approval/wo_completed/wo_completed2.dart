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
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/shared/approval_ui.dart';
import 'package:http/http.dart' as http;
import 'package:v2rp3/routes/api_name.dart';
import '../../../../BE/reqip.dart';
import '../../../../BE/resD.dart';
import 'package:v2rp3/BE/approval_notif_controller.dart';
// import 'package:v2rp3/BE/controller.dart';

import '../../../../main.dart';
import 'we_completed.dart';

class WoCompleted2 extends StatefulWidget {
  final seckey;
  final reffno;
  final tanggal;
  final duedate;
  final amount;
  final username;
  final projectid;
  final locationname;
  final description;
  final wipacc;
  final wipaccName;

  WoCompleted2({
    Key? key,
    required this.seckey,
    required this.reffno,
    required this.tanggal,
    required this.duedate,
    required this.amount,
    required this.username,
    required this.projectid,
    required this.locationname,
    required this.description,
    required this.wipacc,
    required this.wipaccName,
  }) : super(key: key);

  @override
  State<WoCompleted2> createState() => _WoCompleted2State();
}

final fromdate = TextEditingController().obs;
late DateTime fromdatee;
List listWoAcc = [];

class _WoCompleted2State extends State<WoCompleted2> {
  static late List dataaa = <CaConfirmData>[];

  late Future dataFuture;

  @override
  void initState() {
    super.initState();

    // Reset form every time page is opened
    fromdate.value.text = '';
    valueStatus = '';
    valueWo = '';

    dataFuture = getDataa();
    getWoAcc();
  }

  bool get _dateSelected => fromdate.value.text.isNotEmpty;

  bool get _canSubmit {
    if (!_dateSelected || valueStatus.isEmpty) return false;
    return allDetailCompleted || (valueStatus == '-1' && dataaa.isEmpty);
  }

  String get _submitIdleHint {
    if (!_dateSelected) return 'Select closing date to continue';
    if (valueStatus.isEmpty) return 'Select Capitalized or Expended';
    if (valueStatus == '1' && valueWo.isEmpty) {
      return 'Select Posted to Account';
    }
    if (!_canSubmit) return 'All detail items must be Completed';
    return 'Tap submit to complete work order';
  }

  void _handleSubmit() {
    if (!_dateSelected) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Peringatan',
        text: 'Pilih tanggal terlebih dahulu!',
      );
      return;
    }
    if (valueStatus.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Peringatan',
        text: 'Pilih tipe Capitalized atau Expended!',
      );
      return;
    }
    if (valueStatus == '1' && valueWo.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Peringatan',
        text: 'Pilih Posted to Account terlebih dahulu!',
      );
      return;
    }
    if (!_canSubmit) return;
    sendConfirm();
  }

  Widget _buildCompletionStep() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Work Order',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),
          Text('Closing Date',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          TextField(
            controller: fromdate.value,
            readOnly: true,
            onTap: selectDateFrom,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Select date',
              prefixIcon: Icon(Icons.calendar_today_outlined,
                  size: 18, color: ApprovalTheme.primary),
              filled: true,
              fillColor: ApprovalTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          if (_dateSelected) ...[
            const SizedBox(height: 12),
            Text('Type',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Capitalized', style: TextStyle(fontSize: 13)),
                    value: '1',
                    groupValue: valueStatus,
                    activeColor: ApprovalTheme.primary,
                    onChanged: (val) {
                      setState(() {
                        valueStatus = val!;
                        valueWo = '';
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expended', style: TextStyle(fontSize: 13)),
                    value: '-1',
                    groupValue: valueStatus,
                    activeColor: ApprovalTheme.primary,
                    onChanged: (val) {
                      setState(() {
                        valueStatus = val!;
                        valueWo = '';
                      });
                    },
                  ),
                ),
              ],
            ),
            if (valueStatus == '1') ...[
              const SizedBox(height: 4),
              Text('Posted to Account',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: valueWo.isNotEmpty ? valueWo : null,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: ApprovalTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                hint: const Text('Select account'),
                items: listWoAcc.map<DropdownMenuItem<String>>((item) {
                  final ket = item['ket']?.toString() ?? '';
                  return DropdownMenuItem<String>(
                    value: ket,
                    child: Text(ket, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => valueWo = val ?? '');
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  String reasonValue = '';
  // static TextControllers textControllers = Get.put(TextControllers());
  var valueChooseRequest = "";
  var valueStatus = "";
  var valueWo = "";
  var updstatus = "0";
  double totalPrice = 0;
  bool allDetailCompleted = false;
  bool isHeaderExpanded = false;

  String get _formattedDate =>
      DateFormat('dd MMM yyyy').format(DateTime.parse(widget.tanggal));

  List<ApprovalInfoField> _itemDetailFields(dynamic e) {
    return [
      ApprovalInfoField('SPPBJ No', (e['sppbjno'] ?? e['nolpjk'] ?? e['nokasbon'] ?? '').toString()),
      ApprovalInfoField('Date', (e['tanggal'] ?? '').toString()),
      ApprovalInfoField('Status', (e['statusname'] ?? '').toString()),
      ApprovalInfoField('Item / Budget', ('${e['itemcoa']} - ${e['itemname']} - ${e['ket']}').toString()),
      ApprovalInfoField('Unit', (e['unit'] ?? '').toString()),
      ApprovalInfoField('QTY', (e['qty'].toString())),
      ApprovalInfoField('Price', (ApprovalTheme.currencyFmt.format(e['harga'])).toString()),
      ApprovalInfoField('Amount', (ApprovalTheme.currencyFmt.format(e['amount'])).toString()),
      ApprovalInfoField('Closing Date', ((e['completedate'] ?? '').toString()).toString()),
    ];
  }
  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCompletionStep(),
        Expanded(
          child: FutureBuilder(
            future: dataFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error Loading Data',
                        style: TextStyle(color: Colors.grey.shade500)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: ApprovalTheme.primary));
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = _canSubmit;
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
        onBack: () => Get.to(() => WoCompleted()),
        infoPanel: ApprovalInfoPanel(
          collapsedSubtitle: widget.username ?? '-',
          fields: [
            ApprovalInfoField('Request By', widget.username ?? '-'),
            ApprovalInfoField('Project', widget.projectid ?? '-'),
          ],
        ),
        actionSection: null,
        body: _buildBody(),
        bottomBar: ApprovalDetailBottomBar(
          totalPrice: totalPrice,
          itemCount: dataaa.length,
          selectedAction: hasAction ? 'Complete' : null,
          actionColor: hasAction ? ApprovalTheme.primary : null,
          idleHint: _submitIdleHint,
          onSubmit: hasAction ? _handleSubmit : null,
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
        Uri.https(ApiName.v2rp, ApiName.woCompleted + widget.seckey),
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
      if (mounted) { setState(() => dataaa = details); } else { dataaa = details; }
      print("totalllll  " + totalPrice.toString());
      print("dataaa " + dataaa.toString());

      //hitung total
      totalPrice = 0;
      bool allCompleted = true;
      for (var item in dataaa) {
        // Safe conversion for amount - handle both int and double
        var amount = item["amount"];
        if (amount != null) {
          if (amount is int) {
            totalPrice += amount.toDouble();
          } else if (amount is double) {
            totalPrice += amount;
          } else {
            // Fallback: try to parse as double
            try {
              totalPrice += double.parse(amount.toString());
            } catch (e) {
              print("Error parsing amount: $amount, error: $e");
            }
          }
        }
        
        String statusNameRaw = (item["statusname"] ?? '').toString().trim();
        String statusNameLower = statusNameRaw.toLowerCase();
        print("Item status raw: '$statusNameRaw'");
        print("Item status processed: '$statusNameLower'");
        
        // Check multiple possible variations of "completed"
        bool isCompleted = statusNameRaw == 'Completed' ||  // Exact match with capital C
                          statusNameLower == 'completed' ||   // lowercase match
                          statusNameLower == 'complete' ||
                          statusNameLower.contains('complet');
        
        print("Is completed: $isCompleted");
        if (!isCompleted) {
          allCompleted = false;
          print("Found non-completed item: '$statusNameRaw'");
        }
      }
      print("All details completed: $allCompleted");
      setState(() {
        allDetailCompleted = allCompleted;
      });
      if (mounted) setState(() {});
      return dataaa;
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> getWoAcc() async {
    HttpOverrides.global = MyHttpOverrides();
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    var finalKulonuwun = sharedPreferences.getString('kulonuwun');
    var finalMonggo = sharedPreferences.getString('monggo');
    var kulonuwun = MsgHeader.kulonuwun;
    var monggo = MsgHeader.monggo;
    try {
      var getData = await http.get(
        Uri.https(ApiName.v2rp, ApiName.woCompletedAcc),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'kulonuwun': finalKulonuwun ?? kulonuwun,
          'monggo': finalMonggo ?? monggo,
        },
      );
      final caConfirmData = json.decode(getData.body);
      var result = caConfirmData['data'];
      print("dataaa acccccc" + result.toString());
      print(result[0]['ket']);
      setState(() {
        listWoAcc = result;
      });
      for (var item in result) {
        print(item['ket']);
      }
      return result;
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

    // Build request body
    String? wipaccBody;
    if (valueStatus == '1') {
      // Capitalized: cari coa_acc dari listWoAcc berdasarkan valueWo (ket)
      final acc = listWoAcc.firstWhereOrNull((item) => item['ket'] == valueWo);
      wipaccBody = acc != null ? acc['coa_acc']?.toString() : null;
    }
    // tglselesai dari date input
    String tglselesaiBody = fromdate.value.text;
    // hasil: 1 jika Capitalized, -1 jika Expended (as int)
    int? hasilBody;
    if (valueStatus == '1') {
      hasilBody = 1;
    } else if (valueStatus == '-1') {
      hasilBody = -1;
    }
    print('Debug sendConfirm: valueStatus = '
        '$valueStatus, hasilBody = $hasilBody, wipaccBody = $wipaccBody, tglselesaiBody = $tglselesaiBody');

    var body = json.encode({
      'wipacc': wipaccBody,
      'tglselesai': tglselesaiBody,
      'hasil': hasilBody,
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
      var getData = await http.put(
        Uri.https(
          ApiName.v2rp,
          ApiName.woCompleted + widget.seckey + '/' + '1',
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
        approvalRefreshMenuCounts();
        setState(() {
          message = response['data']['message'];
        });
        
        // Invalidate cache for completed transaction - remove only specific transaction
        try {
          final prefs = await SharedPreferences.getInstance();
          
          // Load current main cache
          final cacheData = prefs.getString('wo_completed_cache');
          if (cacheData != null) {
            List cachedList = json.decode(cacheData);
            
            // Remove completed transaction from main cache
            cachedList.removeWhere((item) => 
              item is Map && 
              item['header'] is Map && 
              item['header']['reffno'] == widget.reffno);
            
            // Update main cache with JSON-safe data
            List jsonSafeList = [];
            try {
              String jsonString = json.encode(cachedList);
              jsonSafeList = json.decode(jsonString);
            } catch (e) {
              print("Error converting cache to JSON-safe format: $e");
              jsonSafeList = cachedList; // Use original if conversion fails
            }
            
            await prefs.setString('wo_completed_cache', json.encode(jsonSafeList));
            print("Transaction ${widget.reffno} removed from main cache");
          }
          
          // Load and update page-specific cache
          final cachedPagesData = prefs.getString('wo_completed_cache_pages');
          if (cachedPagesData != null) {
            try {
              final Map<String, dynamic> pages = json.decode(cachedPagesData);
              bool cacheUpdated = false;
              
              // Remove transaction from each cached page
              pages.forEach((pageKey, pageData) {
                if (pageData is List) {
                  int initialLength = pageData.length;
                  pageData.removeWhere((item) => 
                    item is Map && 
                    item['header'] is Map && 
                    item['header']['reffno'] == widget.reffno);
                  
                  if (pageData.length != initialLength) {
                    cacheUpdated = true;
                    print("Transaction ${widget.reffno} removed from cached page $pageKey");
                  }
                }
              });
              
              if (cacheUpdated) {
                // Save updated page cache
                await prefs.setString('wo_completed_cache_pages', json.encode(pages));
                print("Page cache updated - transaction removed but cache preserved");
              }
            } catch (e) {
              print("Error updating page cache: $e");
              // Don't clear cache on error, just log it
            }
          }
          
          // Update last access time to keep cache valid
          await prefs.setInt('wo_completed_cache_last_access', DateTime.now().millisecondsSinceEpoch);
          print("Cache last access time updated to keep cache valid");
          
        } catch (e) {
          print("Error invalidating cache: $e");
        }
        
        QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: 'Success $message Data!',
            barrierDismissible: false,
            disableBackBtn: true,
            // confirmBtnText: 'OK',
            onConfirmBtnTap: () async {
              Get.to(() => WoCompleted());
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
          title: 'Failed! ' + widget.reffno,
          text: '$message',
          onConfirmBtnTap: () async {
            Get.to(() => WoCompleted());
          },
        );
      }
    } catch (e) {
      print(e);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        disableBackBtn: true,
        title: 'Error! ' + widget.reffno,
        text: '$messageError',
        onConfirmBtnTap: () async {
          Get.to(() => WoCompleted());
        },
      );
    }
  }

  Future<void> selectDateFrom() async {
    DateTime? pickedFrom = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HexColor("#F4A62A"), // header background color
              onPrimary: Colors.black, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: HexColor("#F4A62A"), // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedFrom != null) {
      setState(() {
        fromdate.value.text = pickedFrom.toString().split(" ")[0];
        fromdatee = pickedFrom;
      });
      print(fromdate.value.text);
      print(fromdatee.toString());
    }
  }
}
