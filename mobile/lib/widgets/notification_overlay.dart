import 'package:flutter/material.dart';
import 'package:tatkalpro/services/notification_service.dart';

class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  final NotificationService _notificationService = NotificationService();
  final List<Map<String, dynamic>> _notifications = [];
  
  @override
  void initState() {
    super.initState();
    _notificationService.notificationStream.listen(_handleNotification);
  }

  void _handleNotification(Map<String, dynamic> notification) {
    setState(() {
      _notifications.add(notification);
      // Keep only the last 5 notifications
      if (_notifications.length > 5) {
        _notifications.removeAt(0);
      }
    });
    
    // Auto-remove notification after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _notifications.remove(notification);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_notifications.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            left: 10,
            child: Column(
              children: _notifications.map((notification) {
                return _buildNotificationCard(notification);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        color: const Color(0xFF7C3AED), // Purple color to match app theme
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            // Handle notification tap
            setState(() {
              _notifications.remove(notification);
            });
            
            // Create a new notification with tapped flag
            Map<String, dynamic> tappedNotification = {
              ...notification,
              'tapped': true,
            };
            
            // Handle the tapped notification directly
            _notificationService.handleTappedNotification(tappedNotification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? 'New Notification',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
