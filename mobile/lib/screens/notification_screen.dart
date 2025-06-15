import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import '../config/api_config.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _userId = '';
  List<Map<String, dynamic>> _notifications = [];
  int _totalCount = 0;
  int _unreadCount = 0;
  String? _lastEvaluatedKey;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadUserData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _lastEvaluatedKey != null) {
        _loadMoreNotifications();
      }
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileJson = prefs.getString('user_profile');

      if (userProfileJson != null && userProfileJson.isNotEmpty) {
        final userProfile = jsonDecode(userProfileJson);
        final userId = userProfile['UserID'] ?? '';

        setState(() {
          _userId = userId;
        });

        if (userId.isNotEmpty) {
          await _fetchNotifications();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch notifications from API
  Future<void> _fetchNotifications() async {
    if (_userId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/user/$_userId');
      
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<Map<String, dynamic>> notifications = [];
        for (var notif in data['notifications']) {
          notifications.add({
            'notification_id': notif['notification_id'],
            'title': notif['title'],
            'message': notif['message'],
            'notification_type': notif['notification_type'],
            'status': notif['status'],
            'created_at': notif['created_at'],
            'reference_id': notif['reference_id'],
            'metadata': notif['metadata'],
          });
        }

        setState(() {
          _notifications = notifications;
          _totalCount = data['total_count'] ?? 0;
          _unreadCount = data['unread_count'] ?? 0;
          _lastEvaluatedKey = data['last_evaluated_key'];
          _isLoading = false;
        });

        // Trigger animation if we have unread notifications
        if (_unreadCount > 0) {
          _animationController.forward();
        }
      } else {
        print('Error fetching notifications: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception fetching notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load more notifications (pagination)
  Future<void> _loadMoreNotifications() async {
    if (_userId.isEmpty || _lastEvaluatedKey == null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/user/$_userId?last_evaluated_key=$_lastEvaluatedKey');
      
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<Map<String, dynamic>> newNotifications = [];
        for (var notif in data['notifications']) {
          newNotifications.add({
            'notification_id': notif['notification_id'],
            'title': notif['title'],
            'message': notif['message'],
            'notification_type': notif['notification_type'],
            'status': notif['status'],
            'created_at': notif['created_at'],
            'reference_id': notif['reference_id'],
            'metadata': notif['metadata'],
          });
        }

        setState(() {
          _notifications.addAll(newNotifications);
          _lastEvaluatedKey = data['last_evaluated_key'];
          _isLoadingMore = false;
        });
      } else {
        print('Error fetching more notifications: ${response.statusCode}');
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Exception fetching more notifications: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // Mark a notification as read
  Future<void> _markAsRead(String notificationId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/read?user_id=$_userId');
      
      final response = await http.patch(url);

      if (response.statusCode == 200) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['notification_id'] == notificationId);
          if (index != -1) {
            _notifications[index]['status'] = 'read';
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          }
        });
      } else {
        print('Error marking notification as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> _markAllAsRead() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/user/$_userId/read-all');
      
      final response = await http.patch(url);

      if (response.statusCode == 200) {
        setState(() {
          for (var i = 0; i < _notifications.length; i++) {
            _notifications[i]['status'] = 'read';
          }
          _unreadCount = 0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      } else {
        print('Error marking all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception marking all notifications as read: $e');
    }
  }

  // Format the date for display
  String _formatDate(String dateString) {
    try {
      // Parse the date from the string (already in IST from backend)
      final dateIst = DateTime.parse(dateString);
      
      // Get current time
      final now = DateTime.now();
      
      final difference = now.difference(dateIst);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        // Show day of week for notifications within a week
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else {
        // Show full date for older notifications
        return DateFormat('dd MMM yyyy, hh:mm a').format(dateIst);
      }
    } catch (e) {
      print('Error formatting date: $e');
      return 'Unknown date';
    }
  }

  // Get icon based on notification type
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'account':
        return Icons.person;
      case 'booking':
        return Icons.train;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'system':
        return Icons.info;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  // Get color based on notification type
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'account':
        return const Color(0xFF7C3AED); // Purple
      case 'booking':
        return const Color(0xFF059669); // Green
      case 'wallet':
        return const Color(0xFF0369A1); // Blue
      case 'system':
        return const Color(0xFFB45309); // Orange
      case 'promotion':
        return const Color(0xFFB91C1C); // Red
      default:
        return const Color(0xFF7C3AED); // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          // Debug menu in debug mode
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.white),
              onPressed: _showDebugOptions,
              tooltip: 'Test Notifications',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Notification counter
                    if (_totalCount > 0)
                      _buildNotificationCounter(),
                    
                    // Notification list
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _notifications.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                                ),
                              ),
                            );
                          }
                          
                          final notification = _notifications[index];
                          final isUnread = notification['status'] == 'unread';
                          
                          return _buildNotificationItem(notification, isUnread);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNotificationCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$_totalCount Notification${_totalCount != 1 ? 's' : ''}',
            style: const TextStyle(
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
          if (_unreadCount > 0)
            FadeTransition(
              opacity: _animation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount Unread',
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, bool isUnread) {
    final type = notification['notification_type'] ?? 'system';
    final color = _getNotificationColor(type);
    final icon = _getNotificationIcon(type);
    final date = _formatDate(notification['created_at']);

    return Dismissible(
      key: Key(notification['notification_id']),
      background: Container(
        color: const Color(0xFF7C3AED),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.done,
          color: Colors.white,
        ),
      ),
      direction: isUnread ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) {
        _markAsRead(notification['notification_id']);
      },
      child: InkWell(
        onTap: () {
          if (isUnread) {
            _markAsRead(notification['notification_id']);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF3F0FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0A000000),
                blurRadius: isUnread ? 6 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title with unread indicator
                          Expanded(
                            child: Row(
                              children: [
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    notification['title'],
                                    style: TextStyle(
                                      fontFamily: 'ProductSans',
                                      fontSize: 16,
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                      color: const Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Date
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              date,
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                fontSize: 12,
                                color: isUnread 
                                    ? const Color(0xFF7C3AED) 
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Message
                      Text(
                        notification['message'],
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll notify you when something important happens',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(
                fontFamily: 'ProductSans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Show debug options for testing notifications
  void _showDebugOptions() {
    final notificationService = NotificationService();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Notifications', 
          style: TextStyle(color: Color(0xFF7C3AED)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send a test notification to verify that the notification system is working properly.'),
              const SizedBox(height: 16),
              const Text('Choose notification type:', 
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDebugButton(
                context: context,
                label: 'General Test',
                onPressed: () {
                  notificationService.showTestNotification();
                  Navigator.pop(context);
                },
              ),
              _buildDebugButton(
                context: context,
                label: 'Booking Confirmation',
                onPressed: () {
                  notificationService.triggerTestNotification('booking');
                  Navigator.pop(context);
                },
              ),
              _buildDebugButton(
                context: context,
                label: 'Wallet Update',
                onPressed: () {
                  notificationService.triggerTestNotification('wallet');
                  Navigator.pop(context);
                },
              ),
              _buildDebugButton(
                context: context,
                label: 'Price Alert',
                onPressed: () {
                  notificationService.triggerTestNotification('alert');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build consistent debug buttons
  Widget _buildDebugButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
