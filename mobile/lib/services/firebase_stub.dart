// This is a stub file for Firebase on web platforms
// It provides empty implementations of Firebase classes to prevent web build errors
import 'dart:async';
import 'package:flutter/foundation.dart';

// Platform stub for web
class Platform {
  static bool get isIOS => false;
  static bool get isAndroid => false;
}

// Firebase core stubs
class Firebase {
  static Future<FirebaseApp> initializeApp({FirebaseOptions? options}) async {
    print('Firebase stub: initializeApp called');
    return FirebaseApp();
  }
}

class FirebaseApp {
  // Empty implementation
}

class FirebaseOptions {
  static final currentPlatform = FirebaseOptions();
}

// Default Firebase options stub
class DefaultFirebaseOptions {
  static final currentPlatform = FirebaseOptions();
}

// Remote message stub for FCM
class RemoteMessage {
  final String? messageId;
  final Map<String, dynamic> data;
  final RemoteNotification? notification;
  
  RemoteMessage({
    this.messageId = 'stub-message-id',
    this.data = const {},
    this.notification,
  });
}

class RemoteNotification {
  final String? title;
  final String? body;
  
  RemoteNotification({this.title, this.body});
}

// Firebase messaging stubs
class FirebaseMessaging {
  static final instance = FirebaseMessaging();
  static final Stream<RemoteMessage> onMessage = Stream.empty();
  static final Stream<RemoteMessage> onMessageOpenedApp = Stream.empty();
  
  static void onBackgroundMessage(Function(RemoteMessage) handler) {
    // No-op implementation
    print('Firebase stub: onBackgroundMessage registered');
  }
  
  Future<void> requestPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    print('Firebase stub: requestPermission called');
  }
  
  Future<String?> getToken() async {
    print('Firebase stub: getToken called');
    return null;
  }
  
  Stream<String> get onTokenRefresh {
    return Stream.empty();
  }
}
