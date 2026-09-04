import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yoked_in/auth/retry_token_update.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
  // Background messages are automatically shown by FCM
}

class NotificationService {
  static final NotificationService _instance = NotificationService._interna();
  factory NotificationService() => _instance;
  NotificationService._interna();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'chat_messages_channel',
    'Chat Messages',
    description: 'This channel is used for chat message notifications',
    importance: Importance.high,
    playSound: true,
  );

  // initialization metnod

  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    await _localNotifications.resolvePlatformSpecificImplementation;
    AndroidFlutterLocalNotificationsPlugin().createNotificationChannel(
      _channel,
    );

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.notification?.title}');
    final notification = message.notification;
    if (notification != null) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['chatId'],
      );
    }
  }

  // Handle when notification is tapped
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped with payload: ${response.payload}');
    // You can navigate to chat screen here using the payload (chatId)
    // We'll handle this in main.dart using a StreamController
  }

  //   Handle when app is opened from background notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
  }

  Future<String?> getToken() async {
    try {
      // iOS specific handling
      if (Platform.isIOS) {
        // Wait for APNs token with timeout
        String? apnsToken;
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('APNs token timeout - will retry later');
              return null;
            },
          );
        } catch (e) {
          debugPrint('Error getting APNs token: $e');
          // Continue without APNs token
        }

        if (apnsToken == null) {
          debugPrint('APNs token not available yet, getting FCM token anyway');
        }
      }

      // Get FCM token (works even without APNs on iOS)
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null; // Return null instead of throwing error
    }
  }

  void initTokenListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'token': newToken});
      }
    });
  }

  /// 🔑 Call this AFTER any successful login/signup it will update a toke even if new token is available
  Future<void> updateUserToken(String uid) async {
    final token = await getToken();
    if (token == null) {
      debugPrint('FCM token null, retrying later');
      retryTokenUpdate(uid);
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'token': token,
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  Future<void> requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }
}

// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_firebase_chat_app/auth/service/token_update.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_core/firebase_core.dart';

// // ========== BACKGROUND MESSAGE HANDLER ==========
// // THIS MUST BE TOP-LEVEL FUNCTION (outside class)
// // Required by Firebase - runs in separate isolate when app is terminated/background
// // @pragma prevents tree-shaking (ensures function isn't removed during compilation)
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Initialize Firebase in background isolate (separate from main app)
//   await Firebase.initializeApp();
//   debugPrint('Handling background message: ${message.messageId}');
//   // Background messages are automatically shown by FCM on Android/iOS notification tray
//   // No need to manually show notification here - system handles it
// }

// // ========== NOTIFICATION SERVICE CLASS ==========
// // Singleton pattern - ensures only one instance exists throughout app lifecycle
// class NotificationService {
//   // Private constructor and static instance for singleton pattern
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   // Plugin for showing local notifications when app is in foreground
//   // FCM automatically shows notifications in background, but NOT in foreground
//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   // Notification channel for Android - categorizes notifications
//   // Required for Android 8.0+ to control notification behavior (sound, vibration, priority)
//   final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
//     'chat_messages_channel',        // Unique ID - must match Cloud Function
//     'Chat Messages',                // User-visible name in Android settings
//     description: 'This channel is used for chat message notifications', // Description shown in settings
//     importance: Importance.high,    // High priority = heads-up notification
//     playSound: true,                // Enable notification sound
//   );

//   // ========== INITIALIZATION METHOD ==========
//   // Called once in main.dart before app starts
//   // Sets up all notification handlers and permissions
//   Future<void> initialize() async {
//     // Configure local notifications for Android
//     // @mipmap/ic_launcher = app icon used for notification icon
//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );

//     // Configure local notifications for iOS
//     // Request permissions to show alerts, badges, and play sounds
//     const iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,   // Ask permission to show notification banners
//       requestBadgePermission: true,   // Ask permission to show badge count on app icon
//       requestSoundPermission: true,   // Ask permission to play notification sounds
//     );

//     // Combine Android and iOS settings
//     const initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     // Initialize the local notifications plugin
//     // onDidReceiveNotificationResponse = callback when user taps notification
//     await _localNotifications.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: _onNotificationTapped,
//     );

//     // Create Android notification channel
//     // Required for Android 8.0+ to show notifications with correct settings
//     await _localNotifications.resolvePlatformSpecificImplementation;
//     AndroidFlutterLocalNotificationsPlugin().createNotificationChannel(
//       _channel,
//     );

//     // Register the background message handler
//     // This function runs when notification arrives and app is terminated/background
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//     // Listen to messages when app is in FOREGROUND
//     // Foreground = app is open and visible to user
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//     // Listen when user TAPS notification while app is in BACKGROUND
//     // Background = app is minimized but still running
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

//     // Check if app was OPENED by tapping notification while TERMINATED
//     // Terminated = app was completely closed and not in memory
//     final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null) {
//       _handleMessageOpenedApp(initialMessage);
//     }
//   }

//   // ========== FOREGROUND MESSAGE HANDLER ==========
//   // Called when notification arrives while app is OPEN and visible
//   // FCM doesn't automatically show notifications in foreground - we must manually show them
//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     debugPrint('Foreground message received: ${message.notification?.title}');

//     // Extract notification data from FCM message
//     final notification = message.notification;

//     // Only show notification if data exists
//     if (notification != null) {
//       // Show local notification manually using flutter_local_notifications
//       await _localNotifications.show(
//         notification.hashCode,        // Unique ID for this notification
//         notification.title,           // Notification title (bold text)
//         notification.body,            // Notification body (regular text)
//         NotificationDetails(
//           // Android-specific notification settings
//           android: AndroidNotificationDetails(
//             _channel.id,                        // Channel ID - must match channel created above
//             _channel.name,                      // Channel name
//             channelDescription: _channel.description,
//             importance: Importance.high,        // High importance = heads-up notification
//             priority: Priority.high,            // High priority = appears at top of notification list
//             icon: 'ic_notification',            // Custom icon (must exist in drawable folder)
//           ),
//           // iOS-specific notification settings
//           iOS: const DarwinNotificationDetails(
//             presentAlert: true,       // Show banner
//             presentBadge: true,       // Update badge count
//             presentSound: true,       // Play sound
//           ),
//         ),
//         payload: message.data['chatId'], // Extra data passed when notification is tapped
//       );
//     }
//   }

//   // ========== NOTIFICATION TAP HANDLER ==========
//   // Called when user TAPS the notification (from foreground local notification)
//   // Response contains the payload we passed in _handleForegroundMessage
//   void _onNotificationTapped(NotificationResponse response) {
//     debugPrint('Notification tapped with payload: ${response.payload}');
//     // payload contains chatId - can be used to navigate to specific chat screen
//     // Navigation logic would go here (using Navigator or routing package)
//   }

//   // ========== MESSAGE OPENED APP HANDLER ==========
//   // Called when app is opened by tapping notification (background or terminated state)
//   // Can use message.data to navigate to specific screen based on notification type
//   void _handleMessageOpenedApp(RemoteMessage message) {
//     debugPrint('Message opened app: ${message.data}');

//     // Extract notification type from data payload (sent by Cloud Function)
//     final notificationType = message.data['type'];

//     // Navigate to different screens based on notification type
//     if (notificationType == 'friend_request') {
//       // Navigate to friend requests screen
//       debugPrint('Should navigate to friend requests');
//       // Example: navigatorKey.currentState?.pushNamed('/friend-requests');
//     } else if (notificationType == 'message') {
//       // Navigate to one-to-one chat screen
//       final chatId = message.data['chatId'];
//       debugPrint('Should navigate to chat: $chatId');
//       // Example: navigatorKey.currentState?.pushNamed('/chat', arguments: chatId);
//     } else if (notificationType == 'group_message') {
//       // Navigate to group chat screen
//       final groupId = message.data['groupId'];
//       debugPrint('Should navigate to group chat: $groupId');
//       // Example: navigatorKey.currentState?.pushNamed('/group-chat', arguments: groupId);
//     }
//   }

//   // ========== GET FCM TOKEN ==========
//   // Gets the unique device token (FCM token) required to send notifications to this device
//   // Must be saved to Firestore so Cloud Function can send notifications to this device
//   Future<String?> getToken() async {
//     try {
//       // iOS-specific handling - APNs token might not be available immediately
//       if (Platform.isIOS) {
//         // Wait for APNs (Apple Push Notification service) token with timeout
//         String? apnsToken;
//         try {
//           // Try to get APNs token with 3-second timeout
//           // APNs token is required on iOS before FCM token works properly
//           apnsToken = await FirebaseMessaging.instance.getAPNSToken().timeout(
//             const Duration(seconds: 3),
//             onTimeout: () {
//               debugPrint('APNs token timeout - will retry later');
//               return null; // Continue without APNs token
//             },
//           );
//         } catch (e) {
//           debugPrint('Error getting APNs token: $e');
//           // Continue without APNs token - FCM token might still work
//         }

//         if (apnsToken == null) {
//           debugPrint('APNs token not available yet, getting FCM token anyway');
//         }
//       }

//       // Get FCM token (works on both Android and iOS)
//       // This is the unique device identifier used to send push notifications
//       final token = await FirebaseMessaging.instance.getToken();
//       debugPrint('FCM Token: $token');
//       return token;
//     } catch (e) {
//       debugPrint('Error getting FCM token: $e');
//       return null; // Return null instead of throwing error - app continues working
//     }
//   }

//   // ========== TOKEN REFRESH LISTENER ==========
//   // FCM tokens can change (app reinstall, device change, etc.)
//   // Listen for token changes and update Firestore automatically
//   void initTokenListener() {
//     // Listen to token refresh events
//     FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
//       debugPrint('FCM token refreshed: $newToken');

//       // Get current logged-in user
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         // Update the new token in Firestore
//         // This ensures Cloud Function always has the latest token
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .update({'token': newToken});
//       }
//     });
//   }

//   // ========== UPDATE USER TOKEN ==========
//   // Called after login/signup to save FCM token to Firestore
//   // Cloud Function needs this token to send notifications to the user's device
//   Future<void> updateUserToken(String uid) async {
//     // Get the current FCM token
//     final token = await getToken();

//     // If token is null (iOS APNs not ready), retry later in background
//     if (token == null) {
//       debugPrint('FCM token null, retrying later');
//       retryTokenUpdate(uid); // Retry logic from token_update.dart
//       return;
//     }

//     // Save token to Firestore user document
//     // Also update lastSeen and online status
//     await FirebaseFirestore.instance.collection('users').doc(uid).update({
//       'token': token,                              // FCM token for sending notifications
//       'lastSeen': FieldValue.serverTimestamp(),    // Update last seen time
//       'isOnline': true,                            // Mark user as online
//     });
//   }

//   // ========== REQUEST PERMISSIONS ==========
//   // Ask user for notification permissions (iOS requires explicit permission)
//   // Android 13+ also requires runtime permission
//   Future<void> requestPermissions() async {
//     final messaging = FirebaseMessaging.instance;

//     // Request notification permissions from user
//     await messaging.requestPermission(
//       alert: true,        // Show notification banners
//       badge: true,        // Show badge count on app icon
//       sound: true,        // Play notification sounds
//       provisional: false, // Don't use provisional authorization (iOS 12+)
//     );
//   }
// }
