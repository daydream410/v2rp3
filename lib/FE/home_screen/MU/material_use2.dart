// ignore_for_file: non_constant_identifier_names, prefer_const_constructors

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:v2rp3/BE/controller.dart';
import 'package:v2rp3/FE/home_screen/MU/detail_mu.dart';
import 'package:v2rp3/FE/home_screen/MU/material_use.dart';
import 'package:v2rp3/FE/home_screen/MU/material_use3.dart';
// import 'package:v2rp3/additional/scanner.dart';

class MaterialUse2 extends StatefulWidget {
  const MaterialUse2({Key? key}) : super(key: key);

  @override
  State<MaterialUse2> createState() => _MaterialUse2State();
}

class _MaterialUse2State extends State<MaterialUse2> {
  static TextControllers textControllers = Get.put(TextControllers());

  bool isVisible = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are You sure?'),
            content: const Text('Do you want to exit the App?'),
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
        if (shouldPop == true) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        // floatingActionButton: Visibility(
        //   visible: isVisible,
        //   child: FloatingActionButton(
        //     onPressed: () {
        //       Navigator.of(context).push(MaterialPageRoute(
        //         builder: (context) => const BarcodeScannerWithController(),
        //       ));
        //     },
        //     elevation: 12,
        //     tooltip: 'Add Item',
        //     hoverColor: Colors.blue,
        //     backgroundColor: HexColor('#E6BF00'),
        //     foregroundColor: Colors.white,
        //     splashColor: Colors.black45,
        //     child: const Icon(Icons.add),
        //     // highlightElevation: 50,
        //   ),
        // ),
        appBar: AppBar(
          title: const Text("Material Used"),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const MaterialUse()),
              // );
              Get.to(() => MaterialUse());
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TextField(
                //   // controller: controller_wh,
                //   decoration: InputDecoration(
                //     prefixIcon: const Icon(Icons.warehouse),
                //     hintText: 'Warehouse',
                //     suffixIcon: IconButton(
                //       icon: const Icon(Icons.qr_code_scanner),
                //       onPressed: () {
                //         Get.to(() => ScanWh2());
                //       },
                //     ),
                //     border: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(15),
                //         borderSide: const BorderSide(color: Colors.black)),
                //   ),
                // ),
                TextField(
                  controller: textControllers.muWarehouseController.value,
                  onSubmitted: (value) {},
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.assignment),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_2),
                      color: HexColor('#F4A62A'),
                      onPressed: () async {},
                      splashColor: HexColor('#F4A62A'),
                      tooltip: 'Scan',
                      hoverColor: HexColor('#F4A62A'),
                    ),
                    hintText: 'Warehouse',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 10.0),
                TextField(
                  controller: textControllers.muSppbjController.value,
                  onSubmitted: (value) {},
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.assignment),
                    hintText: 'SPPBJ No.',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Colors.black)),
                  ),
                ),
                // TextField(
                //   controller: controller_sppbj,
                //   decoration: InputDecoration(
                //     prefixIcon: const Icon(Icons.article),
                //     hintText: 'SPPBJ No.',
                //     border: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(15),
                //         borderSide: const BorderSide(color: Colors.black)),
                //   ),
                // ),
                const SizedBox(
                  height: 10.0,
                ),
                TextButton(
                  onPressed: () => setState(() => isVisible = !isVisible),
                  child: const Text('Load Data'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: HexColor('#F4A62A'),
                  ),
                ),
                Visibility(
                  visible: isVisible,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(
                        color: Colors.black,
                        thickness: 0.8,
                        height: 25,
                      ),
                      const Text('Item List'),
                      const SizedBox(height: 15.0),
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 5.0),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('BUKU001'),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return const AddDetailMu(
                                        title: "SUBMIT DATA SUCCESFUL",
                                        descriptions:
                                            "Internal Transfer No.STTR/NEP/2022/03-000158",
                                        text: "Home",
                                        home: "OK",
                                      );
                                    });
                              },
                              child: Text(
                                "Detail",
                                style: TextStyle(color: HexColor("#F4A62A")),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Buku Panduan"),
                                Text("Untuk Pelatihan Kru Baru"),
                              ],
                            ),
                            Text("Qty : 10")
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Visibility(
          visible: isVisible,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('SAVE DATA'),
              ),
              onPressed: () async {
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const MaterialUse3(),
                //   ),
                // );
                Get.to(() => MaterialUse3());
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: HexColor('#F4A62A'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
