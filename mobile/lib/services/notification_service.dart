import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:tatkalpro/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Conditionally import Firebase packages only when not on web
// This prevents build errors with firebase_messaging_web
import 'package:firebase_core/firebase_core.dart' if (dart.library.html) 'package:tatkalpro/services/firebase_stub.dart';
import 'package:firebase_messaging/firebase_messaging.dart' if (dart.library.html) 'package:tatkalpro/services/firebase_stub.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => 
      _notificationStreamController.stream;

  // Initialize notification service
  Future<void> initialize() async {
    // Skip initialization on web platform
    if (kIsWeb) {
      print('NotificationService: Skipping initialization on web platform');
      return;
    }
    
    // Initialize Firebase
    await Firebase.initializeApp();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission for iOS devices
    if (!kIsWeb && io.Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Configure local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Configure FCM message handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapped);

    // Register FCM token
    await _registerToken();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final payload = json.decode(response.payload!);
        _notificationStreamController.add(payload);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kIsWeb) return; // Skip on web platform
    
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      
      // Show local notification
      await _showLocalNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        payload: json.encode(message.data),
      );
      
      // Add to stream for UI updates
      final Map<String, dynamic> notificationData = Map<String, dynamic>.from(message.data);
      notificationData['title'] = message.notification!.title;
      notificationData['message'] = message.notification!.body;
      
      _notificationStreamController.add(notificationData);
    }
  }

  // Handle notification tap from FCM
  void _handleNotificationTapped(RemoteMessage message) {
    if (kIsWeb) return; // Skip on web platform
    
    print('Notification tapped: ${message.data}');
    _notificationStreamController.add(message.data);
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'train_booking_channel',
      'Train Booking Notifications',
      channelDescription: 'Notifications for TatkalPro app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFF7C3AED),
    );
    
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Register FCM token
  Future<void> _registerToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Send token to backend
        await UserService().registerFcmToken(token);
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        // Send refreshed token to backend
        await UserService().registerFcmToken(newToken);
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Save FCM token locally
  Future<void> _saveFcmTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  // Send FCM token to server
  Future<void> _sendFcmTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileJson = prefs.getString('user_profile');
      
      if (userProfileJson == null || userProfileJson.isEmpty) {
        print('User not logged in, skipping token registration');
        return;
      }
      
      final userProfile = json.decode(userProfileJson);
      final userId = userProfile['UserID'] ?? '';
      
      if (userId.isEmpty) {
        print('User ID not found, skipping token registration');
        return;
      }
      
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId/fcm-token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('FCM token registered successfully');
      } else {
        print('Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending FCM token to server: $e');
    }
  }

  // Method to manually show a notification (for testing)
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: data != null ? json.encode(data) : null,
    );
  }

  // Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
}
