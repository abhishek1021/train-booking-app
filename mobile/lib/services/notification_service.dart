import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/material.dart';
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

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Access to the notification stream
  Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;

  // Global key for accessing scaffold messenger for in-app notifications
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
    
    // Request permission for Android devices (Android 13+)
    if (!kIsWeb && io.Platform.isAndroid) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Configure FCM message handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapped);

    // Register FCM token
    await _registerToken();
    
    // Show a test notification after a short delay in debug mode
    if (kDebugMode) {
      Future.delayed(const Duration(seconds: 3), () {
        showTestNotification();
      });
    }
  }


  // Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kIsWeb) return; // Skip on web platform
    
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      
      // Add to stream for UI updates
      final Map<String, dynamic> notificationData = Map<String, dynamic>.from(message.data);
      notificationData['title'] = message.notification!.title;
      notificationData['message'] = message.notification!.body;
      
      _notificationStreamController.add(notificationData);
      
      // Display notification using our custom method
      if (!kIsWeb) {
        try {
          print('NOTIFICATION: ${message.notification!.title} - ${message.notification!.body}');
          
          // Show notification using custom method
          await showNotification(
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? '',
            data: message.data,
          );
        } catch (e) {
          print('Error showing notification: $e');
        }
      }
    }
  }

  // Handle notification tap from FCM
  void _handleNotificationTapped(RemoteMessage message) {
    if (kIsWeb) return; // Skip on web platform
    
    print('Notification tapped: ${message.data}');
    _notificationStreamController.add(message.data);
  }
  
  // Handle tapped notification from UI
  void handleTappedNotification(Map<String, dynamic> notification) {
    print('Notification tapped from UI: $notification');
    _notificationStreamController.add(notification);
  }



  // Register FCM token
  Future<void> _registerToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Save token locally
        await _saveFcmTokenLocally(token);
        // Send token to backend
        await _sendFcmTokenToServer(token);
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        // Save refreshed token locally
        await _saveFcmTokenLocally(newToken);
        // Send refreshed token to backend
        await _sendFcmTokenToServer(newToken);
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
      
      print('DEBUG: Attempting to send FCM token to server: $token');
      print('DEBUG: User profile JSON: ${userProfileJson?.substring(0, math.min(100, userProfileJson?.length ?? 0))}...');
      
      if (userProfileJson == null || userProfileJson.isEmpty) {
        print('DEBUG: User not logged in, skipping token registration');
        return;
      }
      
      final userProfile = json.decode(userProfileJson);
      
      // First try to get email as the primary identifier (based on your DynamoDB structure)
      String userId = userProfile['Email'] as String? ?? '';
      
      // If email not found, fall back to UserID
      if (userId.isEmpty) {
        userId = userProfile['UserID'] as String? ?? 
                userProfile['userId'] as String? ?? 
                userProfile['user_id'] as String? ?? 
                userProfile['id'] as String? ?? 
                '';
        
        // Check if the ID has a USER# prefix and remove it for the API call
        if (userId.startsWith('USER#')) {
          userId = userId.substring(5); // Remove 'USER#' prefix
        }
      }
      
      print('DEBUG: User identifier for FCM registration: $userId');
      
      if (userId.isEmpty) {
        print('DEBUG: No valid user identifier found, skipping token registration');
        return;
      }
      
      // Send the FCM token to the server
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId/fcm-token');
      print('DEBUG: Sending FCM token to URL: $url');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          // Include additional info as a string to avoid type errors
          'device_info': jsonEncode({
            'platform': kIsWeb ? 'web' : io.Platform.operatingSystem,
            'app_version': '1.0.0',
            'timestamp': DateTime.now().toIso8601String(),
          })
        }),
      );
      
      print('DEBUG: FCM token registration response status: ${response.statusCode}');
      print('DEBUG: FCM token registration response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('FCM token registered successfully');
        // Save that we've successfully registered the token
        await prefs.setBool('fcm_token_registered', true);
        await prefs.setString('registered_fcm_token', token);
      } else {
        print('Failed to register FCM token: ${response.statusCode}');
        // Store the token locally so we can retry registration later
        await prefs.setString('pending_fcm_token', token);
        
        // Try with UUID as fallback if we used email first
        final userUUID = userProfile['UserID'] as String?;
        if (userId != userUUID && userUUID != null) {
          print('DEBUG: Trying fallback with UserID instead of Email');
          final fallbackUrl = Uri.parse('${ApiConfig.baseUrl}/users/$userUUID/fcm-token');
          
          final fallbackResponse = await http.post(
            fallbackUrl,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'token': token}),
          );
          
          print('DEBUG: Fallback FCM registration response: ${fallbackResponse.statusCode}');
          
          if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
            print('FCM token registered successfully with fallback ID');
            await prefs.setBool('fcm_token_registered', true);
            await prefs.setString('registered_fcm_token', token);
          }
        }
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
    if (kIsWeb) return; // Skip on web platform
    
    // Create notification data for the stream
    final Map<String, dynamic> notificationData = data ?? {};
    notificationData['title'] = title;
    notificationData['message'] = body;
    notificationData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    
    // Add to stream for UI components to handle
    _notificationStreamController.add(notificationData);
    print('Notification added to stream: $title - $body');
    
    // If scaffoldMessengerKey has a current state, show a snackbar
    if (scaffoldMessengerKey.currentState != null) {
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7C3AED), // Purple color to match app theme
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              // Handle notification tap
              _notificationStreamController.add({
                ...notificationData,
                'tapped': true,
              });
            },
          ),
        ),
      );
    }
  }

  // Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
  
  // Show a test notification for debugging purposes
  Future<void> showTestNotification() async {
    print('DEBUG: Showing test notification');
    await showNotification(
      title: 'Test Notification',
      body: 'This is a test notification to verify that foreground notifications are working properly.',
      data: {
        'notification_type': 'test',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'test_id': 'debug-${math.Random().nextInt(10000)}'
      },
    );
  }
  
  // Trigger a test notification with a specific type for debugging
  Future<void> triggerTestNotification(String type) async {
    print('DEBUG: Triggering test notification of type: $type');
    
    String title;
    String body;
    Map<String, dynamic> data = {
      'notification_type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'test_id': 'manual-${math.Random().nextInt(10000)}'
    };
    
    switch (type) {
      case 'booking':
        title = 'Booking Confirmed';
        body = 'Your train booking has been confirmed. Tap to view details.';
        data['reference_id'] = 'PNR${math.Random().nextInt(10000000)}';
        break;
      case 'wallet':
        title = 'Wallet Updated';
        body = 'Your wallet has been credited with ₹500. Tap to check balance.';
        data['amount'] = 500;
        break;
      case 'alert':
        title = 'Price Alert';
        body = 'Prices for your saved route have dropped. Book now!';
        data['route'] = 'Delhi to Mumbai';
        break;
      default:
        title = 'Test Notification';
        body = 'This is a test notification of type: $type';
    }
    
    await showNotification(
      title: title,
      body: body,
      data: data,
    );
  }
}
