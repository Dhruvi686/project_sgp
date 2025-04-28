import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app/pages/splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showNotification(
    message.notification?.title ?? '',
    message.notification?.body ?? '',
  );
}

void _showNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'default_channel', // must match channelId in AndroidManifest
    'Default Notifications',
    channelDescription: 'Channel for default app notifications',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    platformDetails,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Ask permissions
  await FirebaseMessaging.instance.requestPermission();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // 🟡 Optional: Handle notification tap
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Order System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const SplashScreen(),
    );
  }
}