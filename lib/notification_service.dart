import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize Firebase Messaging and Local Notifications
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permission for iOS devices
    await _firebaseMessaging.requestPermission();

    // Background and terminated state
    FirebaseMessaging.onBackgroundMessage(_firebaseMessageHandler);

    // Foreground state
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message.notification!);
      }
    });
  }

  // Show a notification in the system notification bar
  static Future<void> _showNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'default_channel', // Notification Channel ID
      'Default Channel', // Channel Name
      channelDescription: 'Channel for app notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      notification.title,
      notification.body,
      notificationDetails,
    );
  }

  // Background message handler
  static Future<void> _firebaseMessageHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
    if (message.notification != null) {
      _showNotification(message.notification!);
    }
  }

  // Send a test notification
  static Future<void> sendTestNotification() async {
    await _firebaseMessaging.subscribeToTopic("test");
    // Add logic here to send the notification from Firebase Cloud Messaging backend
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Notification Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Send a test notification when the button is pressed
            await NotificationService.sendTestNotification();
          },
          child: const Text('Show Notification'),
        ),
      ),
    );
  }
}
