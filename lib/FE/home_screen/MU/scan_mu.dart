// // ignore_for_file: prefer_const_constructors

// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:v2rp3/FE/MU/material_use.dart';

// class ScanWh extends StatefulWidget {
//   const ScanWh({Key? key}) : super(key: key);

//   @override
//   State<ScanWh> createState() => _ScanWhState();
// }

// class _ScanWhState extends State<ScanWh> {
//   MobileScannerController cameraController = MobileScannerController();

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         final shouldPop = await showDialog<bool>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Are You sure?'),
//             content: const Text('Do you want to exit the App?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('No'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: const Text('Yes'),
//               ),
//             ],
//           ),
//         );
//         if (shouldPop == true) {
//           SystemNavigator.pop();
//         }
//         return false;
//       },
//       child: Scaffold(
//           appBar: AppBar(
//             title: const Text("Scanner"),
//             centerTitle: true,
//             backgroundColor: Colors.white,
//             foregroundColor: Colors.black,
//             elevation: 1,
//             actions: [
//               IconButton(
//                 color: const Color.fromARGB(255, 139, 0, 0),
//                 icon: ValueListenableBuilder(
//                   valueListenable: cameraController.torchState,
//                   builder: (context, state, child) {
//                     switch (state as TorchState) {
//                       case TorchState.off:
//                         return const Icon(Icons.flash_off, color: Colors.grey);
//                       case TorchState.on:
//                         return const Icon(Icons.flash_on, color: Colors.yellow);
//                     }
//                   },
//                 ),
//                 iconSize: 32.0,
//                 onPressed: () => cameraController.toggleTorch(),
//               ),
//               IconButton(
//                 color: const Color.fromARGB(255, 106, 0, 0),
//                 icon: ValueListenableBuilder(
//                   valueListenable: cameraController.cameraFacingState,
//                   builder: (context, state, child) {
//                     switch (state as CameraFacing) {
//                       case CameraFacing.front:
//                         return const Icon(Icons.camera_front);
//                       case CameraFacing.back:
//                         return const Icon(Icons.camera_rear);
//                     }
//                   },
//                 ),
//                 iconSize: 32.0,
//                 onPressed: () => cameraController.switchCamera(),
//               ),
//             ],
//           ),
//           body: MobileScanner(
//               allowDuplicates: false,
//               controller: cameraController,
//               onDetect: (barcode, args) {
//                 final String? code = barcode.rawValue;
//                 debugPrint('Barcode found! $code');
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     backgroundColor: Colors.white,
//                     elevation: 10.0,
//                     shape: Border.all(
//                         color: const Color.fromARGB(255, 0, 215, 4),
//                         width: 0.5,
//                         style: BorderStyle.solid),
//                     content: Text(
//                       "Barcode Found! = $code",
//                       style: const TextStyle(
//                         color: Colors.black,
//                         fontSize: 16.0,
//                         fontStyle: FontStyle.italic,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 1.0,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 );
//                 // Navigator.of(context).pushReplacement(MaterialPageRoute(
//                 //   builder: (context) => const MaterialUse(),
//                 // ));
//                 Get.to(() => MaterialUse());
//               })),
//     );
//   }
// }
