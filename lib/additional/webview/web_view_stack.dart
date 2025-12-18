// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:v2rp3/utils/hex_color.dart';
// import 'package:v2rp3/FE/notif/notif_screen.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class WebViewStack extends StatefulWidget {
//   const WebViewStack({Key? key}) : super(key: key);

//   @override
//   State<WebViewStack> createState() => _WebViewStackState();
// }

// class _WebViewStackState extends State<WebViewStack> {
//   var loadingPercentage = 0;
//   late WebViewController controller;

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
//         appBar: AppBar(
//           title: const Text("V2RP Mobile Web View"),
//           centerTitle: true,
//           backgroundColor: Colors.white,
//           foregroundColor: Colors.black,
//           elevation: 1,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const NotifScreen()),
//               );
//             },
//           ),
//           actions: [
//             IconButton(
//               onPressed: () {},
//               icon: const Icon(Icons.refresh),
//             ),
//           ],
//         ),
//         body: Stack(
//           children: [
//             WebView(
//               initialUrl: 'https://flutter.dev',
//               onPageStarted: (url) {
//                 setState(() {
//                   loadingPercentage = 0;
//                 });
//               },
//               onProgress: (progress) {
//                 setState(() {
//                   loadingPercentage = progress;
//                 });
//               },
//               onPageFinished: (url) {
//                 setState(() {
//                   loadingPercentage = 100;
//                 });
//               },
//             ),
//             if (loadingPercentage < 100)
//               LinearProgressIndicator(
//                 value: loadingPercentage / 100.0,
//                 color: HexColor('#F4A62A'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
