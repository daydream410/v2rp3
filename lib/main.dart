// ignore_for_file: unrelated_type_equality_checks, avoid_print

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/FE/mainScreen/login_screen4.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/navbar/navbar.dart' as navbar_module;
import 'package:v2rp3/FE/approval_screen/cash_bank/cash_advance_confirm/ca_confirm.dart';
import 'package:v2rp3/FE/approval_screen/cash_bank/cash_advance_approval/ca_app.dart';
import 'package:v2rp3/FE/approval_screen/cash_bank/ca_set_confirm/ca_set_confirm.dart';
import 'package:v2rp3/FE/approval_screen/cash_bank/ca_set_approval/ca_set_app.dart';
import 'package:v2rp3/FE/approval_screen/sales_approval/ar_app/ar_app.dart';
import 'package:v2rp3/FE/approval_screen/sales_approval/sales_order_app/sales_order_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/sppbj_confirm/sppbj_confirm.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/sppbj_approval/sppbj_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/po_scm_approval/poscm_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/np_app/newap_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/dpreq_approval/dpreq_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/ap_refund/ap_refund.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/ap_adjustment/apadj_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/dn_approval/dn_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/po_ex_approval/poex_app.dart';
import 'package:v2rp3/FE/approval_screen/purchase_approval/poscm_unapproved/poscm_unapproved.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/mu_approval/mu_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/gr_approval/gr_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/it_approval/it_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/sm_approval/sm_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/stockadj_approval/stockadj_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/stock_trf_approval/stocktrf_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/mr_approval/mr_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/stock_topup_approval/topup_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/stockprice_approval/stockprice_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/update_minmax_approval/minmax_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/itstock_adj_approval/itstock_app.dart';
import 'package:v2rp3/FE/approval_screen/inventory_approval/assembling_approval/asmb_app.dart';
import 'package:v2rp3/FE/approval_screen/ppc_approval/wo_app/wo_app.dart';
import 'package:v2rp3/FE/approval_screen/ppc_approval/wo_completed/we_completed.dart';
import 'additional/splash.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
      '🔔 [FCM:BACKGROUND] Handling a background message: ${message.messageId}');
  print('🔔 [FCM:BACKGROUND] Data: ${message.data}');
  print(
      '🔔 [FCM:BACKGROUND] Notification: ${message.notification?.title} | ${message.notification?.body}');

  // iOS does not auto-display data-only messages in background; show locally.
  if (Platform.isIOS &&
      (message.notification != null || message.data.isNotEmpty)) {
    await initializeNotifications();
    await _showFcmLocalNotification(message);
  }
}

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global variable to store FCM token
String? fcmToken;

// Helper to print long strings in chunks to avoid truncation
void _printLongString(String label, String? value) {
  if (value == null) {
    print('$label: null');
    return;
  }

  const int chunkSize = 800; // Print in chunks to avoid truncation
  if (value.length <= chunkSize) {
    print('$label: $value');
  } else {
    print('$label (length: ${value.length}):');
    for (int i = 0; i < value.length; i += chunkSize) {
      int end = (i + chunkSize < value.length) ? i + chunkSize : value.length;
      print('  [${i}-${end}]: ${value.substring(i, end)}');
    }
  }
}

// Debug helper to inspect stored credentials/tokens
Future<void> _debugPrintAuthState({String context = 'unknown'}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final seckey = prefs.getString('seckey');
    final kulonuwun = prefs.getString('kulonuwun');
    final monggo = prefs.getString('monggo');
    final storedFcm = prefs.getString('fcm_token');

    print('[debug:$context] === AUTH STATE DEBUG ===');
    _printLongString('[debug:$context] seckey', seckey);
    _printLongString('[debug:$context] kulonuwun', kulonuwun);
    _printLongString('[debug:$context] monggo', monggo);
    _printLongString('[debug:$context] fcm_token(prefs)', storedFcm);
    _printLongString('[debug:$context] fcmToken(var)', fcmToken);
    print('[debug:$context] === END AUTH STATE ===');
  } catch (e) {
    print('[debug:$context] Failed to read auth state: $e');
  }
}

// Global navigator key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Function to handle notification navigation
void _handleNotificationNavigation(String payload) {
  try {
    final data = jsonDecode(payload);
    final String? route = data['route'] as String?;
    final String? screen = data['screen'] as String?;
    final String? type = data['type'] as String?;
    final String? company = data['company'] as String?;
    final String? role = data['role'] as String?;
    final String? reffno = data['reffno'] as String?;
    final String? seckeyPayload = data['seckey'] as String?;
    final Map<String, dynamic>? extraData =
        data['data'] as Map<String, dynamic>?;

    print(
        'Navigating from notification - route: $route, screen: $screen, type: $type, company: $company, role: $role, reffno: $reffno, seckey: $seckeyPayload');

    // Check if user is logged in
    SharedPreferences.getInstance().then((prefs) {
      final String? kulonuwun = prefs.getString('kulonuwun');
      final String? monggo = prefs.getString('monggo');

      if (kulonuwun == null || monggo == null) {
        print('User not logged in, cannot navigate');
        _debugPrintAuthState(context: 'notification_no_login');
        return;
      }

      // Navigate based on route/screen/type
      if (route != null || screen != null || type != null) {
        _navigateToScreen(
            route: route, screen: screen, type: type, data: extraData);
      }
    });
  } catch (e) {
    print('Error parsing notification payload: $e');
  }
}

// Normalize payload so every listener produces the same structure
Map<String, dynamic> _normalizeFcmPayload(Map<String, dynamic> rawData) {
  return {
    // navigation hints
    'route': rawData['route'] ?? rawData['screen'],
    'screen': rawData['screen'],
    'type': rawData['type'] ?? rawData['menu'] ?? rawData['route'],
    // business identifiers
    'company': rawData['company'],
    'role': rawData['role'],
    'reffno': rawData['reffno'] ?? rawData['refno'],
    'seckey': rawData['seckey'],
    // keep original data for downstream usage
    'data': rawData,
  };
}

// Function to navigate to specific screen
void _navigateToScreen({
  String? route,
  String? screen,
  String? type,
  Map<String, dynamic>? data,
}) {
  // Wait for app to be ready
  Future.delayed(const Duration(milliseconds: 500), () {
    if (navigatorKey.currentContext == null) {
      print('Navigator context not ready yet');
      return;
    }

    // Navigate to Navbar first if not already there
    try {
      Get.offAll(const Navbar());
    } catch (e) {
      print('Error navigating to Navbar: $e');
      return;
    }

    // Then navigate to specific screen based on route/screen/type
    Future.delayed(const Duration(milliseconds: 500), () {
      int? targetTabIndex;

      // Handle route-based navigation (main tabs)
      if (route != null) {
        switch (route.toLowerCase()) {
          case 'home':
          case 'home_screen':
            targetTabIndex = 0; // Home screen (index 0)
            break;
          case 'approval':
          case 'approval_screen':
            targetTabIndex = 1; // Approval screen (index 1)
            break;
          case 'setting':
          case 'setting_screen':
            targetTabIndex = 2; // Setting screen (index 2)
            break;
          default:
            print('Unknown route: $route');
        }
      }

      // Handle type-based navigation (fallback)
      if (targetTabIndex == null && type != null) {
        switch (type.toLowerCase()) {
          case 'home':
            targetTabIndex = 0;
            break;
          case 'approval':
          case 'approve':
            targetTabIndex = 1;
            break;
          case 'setting':
          case 'settings':
          case 'profile':
            targetTabIndex = 2;
            break;
          default:
            print('Unknown type: $type');
        }
      }

      // Navigate to the target tab if found
      if (targetTabIndex != null) {
        // Try to access Navbar state and navigate
        try {
          // Wait a bit more for navbar to be fully built
          Future.delayed(const Duration(milliseconds: 200), () {
            // Use global reference from navbar.dart
            if (navbar_module.currentNavbarState != null) {
              navbar_module.currentNavbarState!.navigateToTab(targetTabIndex!);
              print('Navigated to tab index: $targetTabIndex');
            } else {
              // If navbar not ready, navigate first then set tab
              Get.offAll(() => const Navbar());
              Future.delayed(const Duration(milliseconds: 500), () {
                if (navbar_module.currentNavbarState != null) {
                  navbar_module.currentNavbarState!
                      .navigateToTab(targetTabIndex!);
                  print('Navigated to tab index: $targetTabIndex (delayed)');
                }
              });
            }
          });
        } catch (e) {
          print('Error navigating to tab: $e');
        }
      }

      // Handle specific screens within approval (if needed)
      if (screen != null) {
        print('Navigate to screen: $screen with data: $data');
        // This would need custom navigation logic based on screen name
        // For example, navigate to specific approval detail screen
      }

      // Additionally, handle direct approval detail navigation based on type code
      if (type != null) {
        _openApprovalDetailByType(type, data);
      }
    });
  });
}

// Navigate directly to specific approval detail screen based on type code
void _openApprovalDetailByType(String? type, Map<String, dynamic>? data) {
  if (type == null) return;

  final String t = type.toUpperCase();
  print('_openApprovalDetailByType called with type: $t, data: $data');

  // Slight delay to ensure main navigation (Navbar/Approval tab) is ready
  Future.delayed(const Duration(milliseconds: 800), () {
    try {
      switch (t) {
        // Cash & Bank
        case 'KC': // Cash Advance Confirmation
          Get.to(() => CashAdvanceConfirm());
          break;
        case 'KA': // Cash Advance Approval
          Get.to(() => CashAdvanceApproval());
          break;
        case 'LC': // C/A Settlement Confirmation
          Get.to(() => CaSettleConfirm());
          break;
        case 'LA': // C/A Settlement Approval
          Get.to(() => CaSetApproval());
          break;

        // Sales
        case 'ARRA': // A/R Receipt Approval
          Get.to(() => ArApproval());
          break;
        case 'SOA': // Sales Order Approval
          Get.to(() => SalesOrderApproval());
          break;

        // Purchase
        case 'SC': // SPPBJ Confirmation
          Get.to(() => SppbjConfirm());
          break;
        case 'SA': // SPPBJ Approval
          Get.to(() => SppbjApp());
          break;
        case 'PA': // PO SCM Approval
          Get.to(() => PoScmApp());
          break;
        case 'NA': // New Payable Approval
          Get.to(() => NpApp());
          break;
        case 'DPA': // D/P Request Approval
          Get.to(() => DpReqApp());
          break;
        case 'APRA': // A/P Refund Approval
          Get.to(() => ApRefundApp());
          break;
        case 'APAA': // A/P Adjustment Approval
          Get.to(() => ApAdjApp());
          break;
        case 'DNA': // D/N to Supplier Approval
          Get.to(() => DebitNotesApp());
          break;
        case 'POE': // PO Exception Approval
          Get.to(() => PoExApp());
          break;
        case 'POS': // PO SCM Supplier Unapproved Approval (grouped)
        case 'PNS':
          Get.to(() => PoUnapproved());
          break;

        // Inventory
        case 'MUA': // Material Used Approval
          Get.to(() => MuApp());
          break;
        case 'GRA': // Goods Received Approval
          Get.to(() => GrApp());
          break;
        case 'ITA': // Internal Transfer Approval
          Get.to(() => ItApp());
          break;
        case 'SMA': // Stock Movement Approval
          Get.to(() => SmApp());
          break;
        case 'SAA': // Stock Adjustment Approval
          Get.to(() => StockAdjApp());
          break;
        case 'STA': // Stock Transfer Approval
          Get.to(() => StockTrfApp());
          break;
        case 'MRA': // Material Return Approval
          Get.to(() => MrApp());
          break;
        case 'STUA': // Stock Top Up Approval
          Get.to(() => StockTopupApp());
          break;
        case 'SPA': // Stock Price Approval
          Get.to(() => StockPriceApp());
          break;
        case 'MMU': // Update Min/Max Parameter
          Get.to(() => UpdateMinMaxApp());
          break;
        case 'ITSA': // IT/Stock Adjustment Approval (grouped)
        case 'STSA':
          Get.to(() => ItStockAdjApp());
          break;
        case 'AA': // Assembling Approval
          Get.to(() => AssemblingApp());
          break;

        // PPC
        case 'WOA': // Work Order Approval
          Get.to(() => WoApp());
          break;
        case 'WOU': // Work Order Completed
          Get.to(() => WoCompleted());
          break;

        default:
          print('No direct approval detail mapping for type: $t');
      }
    } catch (e) {
      print('Error navigating to approval detail for type $t: $e');
    }
  });
}

// Function to save FCM token to SharedPreferences
Future<void> saveFcmTokenToLocal(String? token) async {
  if (token != null) {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    print('FCM Token saved to local storage');
  }
}

// Function to get and save FCM token
Future<String?> getAndSaveFcmToken() async {
  try {
    print('🔑 [FCM:TOKEN] Requesting FCM token...');
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // For iOS: Wait for APNS token to be available
    if (Platform.isIOS) {
      print('📱 [FCM:TOKEN] iOS detected - checking APNS token...');
      String? apnsToken = await messaging.getAPNSToken();

      // If APNS token is not available, wait and retry
      if (apnsToken == null) {
        print('⏳ [FCM:TOKEN] APNS token not available yet, waiting...');
        int retryCount = 0;
        const maxRetries = 10;

        while (apnsToken == null && retryCount < maxRetries) {
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await messaging.getAPNSToken();
          retryCount++;
          print(
              '⏳ [FCM:TOKEN] Retry $retryCount/$maxRetries - APNS token: ${apnsToken != null ? "available" : "not available"}');
        }

        if (apnsToken == null) {
          print(
              '❌ [FCM:TOKEN] APNS token still not available after $maxRetries retries');
          print(
              'ℹ️ [FCM:TOKEN] This might be a simulator (push notifications not fully supported)');
          return null;
        }
      }

      print(
          '✅ [FCM:TOKEN] APNS token is available: ${apnsToken.substring(0, 20)}...');
    }

    String? token = await messaging.getToken();

    if (token != null) {
      fcmToken = token;
      await saveFcmTokenToLocal(token);
      print('✅ [FCM:TOKEN] FCM Token generated successfully');
      print('✅ [FCM:TOKEN] Token length: ${token.length}');
      print(
          '✅ [FCM:TOKEN] Token (first 50 chars): ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
      print('✅ [FCM:TOKEN] Token saved to SharedPreferences');
    } else {
      print('❌ [FCM:TOKEN] FCM Token is null!');
    }

    return token;
  } catch (e) {
    print('❌ [FCM:TOKEN] Error getting FCM token: $e');
    return null;
  }
}

// Initialize local notifications
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      if (response.payload != null) {
        _handleNotificationNavigation(response.payload!);
      }
    },
  );

  // Android notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> _showFcmLocalNotification(RemoteMessage message) async {
  final normalized = _normalizeFcmPayload(message.data);
  final String payload = jsonEncode(normalized);
  final String title =
      message.notification?.title ?? message.data['title']?.toString() ?? 'V2RP';
  final String body = message.notification?.body ??
      message.data['body']?.toString() ??
      jsonEncode(message.data);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFFF4A62A),
        colorized: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: payload,
  );
}

// Initialize Firebase and FCM in background (non-blocking)
Future<void> _initializeFirebaseAndFCM() async {
  print('🚀 [FCM:INIT] Starting Firebase and FCM initialization...');
  try {
    // Initialize Firebase with timeout
    print('🚀 [FCM:INIT] Step 1: Initializing Firebase...');
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('❌ [FCM:INIT] Firebase initialization timeout');
        throw TimeoutException('Firebase initialization timeout');
      },
    );
    print('✅ [FCM:INIT] Firebase initialized successfully');

    // Set up background message handler
    print('🚀 [FCM:INIT] Step 2: Registering background message handler...');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ [FCM:INIT] Background message handler registered');

    // Initialize local notifications with timeout
    print('🚀 [FCM:INIT] Step 3: Initializing local notifications...');
    await initializeNotifications().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('⚠️ [FCM:INIT] Local notifications initialization timeout');
      },
    );
    print('✅ [FCM:INIT] Local notifications initialized successfully');

    // Request notification permissions (no timeout for user interaction)
    print('🚀 [FCM:INIT] Step 4: Requesting notification permissions...');
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings;
    try {
      settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('📱 [FCM:INIT] Permission status: ${settings.authorizationStatus}');
      print('📱 [FCM:INIT] Alert: ${settings.alert}');
      print('📱 [FCM:INIT] Badge: ${settings.badge}');
      print('📱 [FCM:INIT] Sound: ${settings.sound}');
    } catch (e) {
      print('❌ [FCM:INIT] Error requesting notification permission: $e');
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ [FCM:INIT] User granted notification permission');

      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('✅ [FCM:INIT] iOS foreground presentation options set');
      }

      // Get and save FCM token with timeout
      print('🚀 [FCM:INIT] Step 5: Getting FCM token...');
      try {
        final token = await getAndSaveFcmToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ [FCM:INIT] FCM token generation timeout');
            return null;
          },
        );
        if (token != null) {
          print(
              '✅ [FCM:INIT] FCM token obtained: ${token.substring(0, 20)}...');
        } else {
          print('❌ [FCM:INIT] FCM token is null!');
        }
      } catch (e) {
        print('❌ [FCM:INIT] Error getting FCM token: $e');
      }
      await _debugPrintAuthState(context: 'startup_after_token');

      // Listen for token refresh
      print('🚀 [FCM:INIT] Step 6: Setting up token refresh listener...');
      messaging.onTokenRefresh.listen((String newToken) {
        print(
            '🔄 [FCM:TOKEN] FCM Token refreshed: ${newToken.substring(0, 20)}...');
        fcmToken = newToken;
        saveFcmTokenToLocal(newToken);
        _debugPrintAuthState(context: 'token_refresh');
      });
      print('✅ [FCM:INIT] Token refresh listener registered');

      // Handle foreground messages
      print(
          '🚀 [FCM:INIT] Step 7: Setting up onMessage listener (foreground)...');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 [FCM:onMessage] ==========================================');
        print('🔔 [FCM:onMessage] Got a message whilst in the foreground!');
        print('🔔 [FCM:onMessage] Message ID: ${message.messageId}');
        print('🔔 [FCM:onMessage] From: ${message.from}');
        print('🔔 [FCM:onMessage] Data: ${message.data}');
        print(
            '🔔 [FCM:onMessage] Notification title: ${message.notification?.title}');
        print(
            '🔔 [FCM:onMessage] Notification body: ${message.notification?.body}');
        print(
            '🔔 [FCM:onMessage] Has notification: ${message.notification != null}');
        print('🔔 [FCM:onMessage] Has data: ${message.data.isNotEmpty}');

        // Tampilkan notifikasi juga untuk pesan data-only
        if (message.notification != null || message.data.isNotEmpty) {
          print(
              '🔔 [FCM:onMessage] Showing local notification for incoming FCM');

          _showFcmLocalNotification(message).then((_) {
            print('✅ [FCM:onMessage] Local notification shown successfully');
          }).catchError((error) {
            print('❌ [FCM:onMessage] Error showing local notification: $error');
          });
        } else {
          print('⚠️ [FCM:onMessage] No notification/data payload to display');
        }
        print('🔔 [FCM:onMessage] ==========================================');
      });
      print('✅ [FCM:INIT] onMessage listener registered');

      // Handle notification taps when app is in background/terminated
      print('🚀 [FCM:INIT] Step 8: Setting up onMessageOpenedApp listener...');
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
            '🔔 [FCM:onMessageOpenedApp] ==========================================');
        print('🔔 [FCM:onMessageOpenedApp] Notification tap from background');
        print('🔔 [FCM:onMessageOpenedApp] Message ID: ${message.messageId}');
        print('🔔 [FCM:onMessageOpenedApp] Data: ${message.data}');
        print('🔔 [FCM:onMessageOpenedApp] Notification: '
            '${message.notification?.title} | ${message.notification?.body}');

        // Handle navigation from background notification
        if (message.data.isNotEmpty) {
          final normalized = _normalizeFcmPayload(message.data);
          String payload = jsonEncode(normalized);
          print(
              '🔔 [FCM:onMessageOpenedApp] Navigating with payload: $payload');
          _handleNotificationNavigation(payload);
        }
        print(
            '🔔 [FCM:onMessageOpenedApp] ==========================================');
      });
      print('✅ [FCM:INIT] onMessageOpenedApp listener registered');

      // Check if app was opened from a terminated state via notification (with timeout)
      print(
          '🚀 [FCM:INIT] Step 9: Checking for initial message (terminated state)...');
      RemoteMessage? initialMessage =
          await messaging.getInitialMessage().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ [FCM:INIT] getInitialMessage timeout');
          return null;
        },
      );
      if (initialMessage != null) {
        print(
            '🔔 [FCM:INIT] App opened from terminated state via notification');
        print('🔔 [FCM:INIT] Message data: ${initialMessage.data}');

        // Handle navigation from terminated state notification
        if (initialMessage.data.isNotEmpty) {
          final normalized = _normalizeFcmPayload(initialMessage.data);
          String payload = jsonEncode(normalized);
          _handleNotificationNavigation(payload);
        }
      } else {
        print(
            'ℹ️ [FCM:INIT] No initial message (app not opened from notification)');
      }

      // Verify listeners are actually subscribed
      print('🔍 [FCM:INIT] Verifying listeners are active...');
      print(
          '🔍 [FCM:INIT] onMessage subscription: ${FirebaseMessaging.onMessage}');
      print(
          '🔍 [FCM:INIT] onMessageOpenedApp subscription: ${FirebaseMessaging.onMessageOpenedApp}');

      print('✅ [FCM:INIT] ==========================================');
      print('✅ [FCM:INIT] FCM initialization COMPLETE!');
      print(
          '✅ [FCM:INIT] All listeners are now active and ready to receive messages');
      print('✅ [FCM:INIT] ==========================================');
    } else {
      print(
          '❌ [FCM:INIT] User declined or has not accepted notification permissions');
      print(
          '❌ [FCM:INIT] Authorization status: ${settings.authorizationStatus}');
      print('❌ [FCM:INIT] FCM will not work without notification permissions!');
    }
  } catch (e, stackTrace) {
    print('❌ [FCM:INIT] ==========================================');
    print('❌ [FCM:INIT] Error initializing Firebase/FCM: $e');
    print('❌ [FCM:INIT] Stack trace: $stackTrace');
    print('❌ [FCM:INIT] ==========================================');
    // Continue even if Firebase fails to initialize
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and FCM before running app
  await _initializeFirebaseAndFCM();

  // Run app after Firebase is initialized
  runApp(MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  String? finalUsername;

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      title: 'V2RP',
      initialRoute: '/',
      routes: {
        '/Login': (context) => const LoginPage4(),
        // '/Second': (context) => const SecondScreen()
      },
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
