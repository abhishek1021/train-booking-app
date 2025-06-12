// Web-specific implementation of the notification service
// This file provides empty implementations for web platform

import 'dart:async';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => 
      _notificationStreamController.stream;

  // Initialize notification service - empty implementation for web
  Future<void> initialize() async {
    print('NotificationService: Web implementation - no initialization needed');
  }

  // Show notification - empty implementation for web
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    print('NotificationService: Web implementation - notification would show: $title');
    
    // Still add to stream for UI consistency
    _notificationStreamController.add({
      'title': title,
      'message': body,
      ...?data,
    });
  }

  // Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
}
