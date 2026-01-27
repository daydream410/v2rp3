import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("🚀 [iOS] AppDelegate: didFinishLaunchingWithOptions started")
    
    // Configure Firebase BEFORE registering plugins
    FirebaseApp.configure()
    print("✅ [iOS] Firebase configured")
    
    GeneratedPluginRegistrant.register(with: self)
    print("✅ [iOS] Plugins registered")
    
    // Set Firebase Messaging delegate
    Messaging.messaging().delegate = self
    print("✅ [iOS] Firebase Messaging delegate set")
    
    // Request notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if let error = error {
            print("❌ [iOS] Error requesting notification permission: \(error)")
          } else {
            print("✅ [iOS] Notification permission granted: \(granted)")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    print("✅ [iOS] Registered for remote notifications")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Remote Notification Registration
  
  // Handle successful APNS registration
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("📱 [APNS] Device token received")
    
    // Convert token to string for logging
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("📱 [APNS] Device Token: \(token)")
    
    // Pass APNS token to Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    print("✅ [APNS] APNS token set to Firebase Messaging")
  }
  
  // Handle APNS registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ [APNS] Failed to register for remote notifications: \(error.localizedDescription)")
  }
  
  // MARK: - UNUserNotificationCenterDelegate
  
  // Handle notification when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    
    print("🔔 [iOS] Notification received in foreground")
    print("🔔 [iOS] UserInfo: \(userInfo)")
    
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .badge, .sound]])
    } else {
      completionHandler([[.alert, .badge, .sound]])
    }
  }
  
  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    
    print("🔔 [iOS] Notification tapped")
    print("🔔 [iOS] UserInfo: \(userInfo)")
    
    // Handle notification tap and navigation here if needed
    // The Flutter side will also handle this via FirebaseMessaging.onMessageOpenedApp
    
    completionHandler()
  }
}

// MARK: - Firebase Messaging Delegate Extension
extension AppDelegate: MessagingDelegate {
  // Handle FCM token updates
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔑 [FCM] Firebase registration token received")
    if let token = fcmToken {
      print("🔑 [FCM] Token: \(token)")
      // You can send this token to your backend server if needed
      let dataDict: [String: String] = ["token": token]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
    } else {
      print("❌ [FCM] Token is nil")
    }
  }
}
