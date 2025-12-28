import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        debugPrint('User granted permission');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        debugPrint('User granted provisional permission');
      }
    } else {
      if (kDebugMode) {
        debugPrint('User declined or has not accepted permission');
      }
    }

    // Get Token
    String? token = await _fcm.getToken();
    if (kDebugMode) {
      debugPrint('FCM Token: $token');
    }

    // Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          debugPrint(
              'Message also contained a notification: ${message.notification}');
        }
        // In a real app, show a local notification here using flutter_local_notifications
      }
    });
  }
}
