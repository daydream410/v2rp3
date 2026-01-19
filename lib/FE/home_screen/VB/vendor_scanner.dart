// TEMPORARILY DISABLED FOR iOS SIMULATOR
// This file requires mobile_scanner which doesn't work on iOS Simulator
// To enable: uncomment mobile_scanner in pubspec.yaml and restore original file

import 'package:flutter/material.dart';

// Alias for compatibility
typedef ScanVb = ScanVendor;

class ScanVendor extends StatefulWidget {
  final String? trxNo;
  final String? vendorCode;
  final String? vendorDesc;
  final String? idstock;
  final String? itemname;
  
  const ScanVendor({
    Key? key,
    this.trxNo,
    this.vendorCode,
    this.vendorDesc,
    this.idstock,
    this.itemname,
  }) : super(key: key);

  @override
  State<ScanVendor> createState() => _ScanVendorState();
}

class _ScanVendorState extends State<ScanVendor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanner"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Scanner Not Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Barcode scanner is temporarily disabled for iOS Simulator testing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please test scanner features on a physical device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
