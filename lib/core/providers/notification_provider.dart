import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  List<NotificationItem> _notifications = [];

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NotificationItem> get notifications => _notifications;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      await _notificationService.initialize();
      _isInitialized = true;
      print('🔔 NotificationProvider: Initialized successfully');
    } catch (e) {
      _setError('Failed to initialize notifications: $e');
      print('❌ NotificationProvider: Error initializing: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Send order status update notification to customer
  Future<void> sendOrderStatusUpdateNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required String newStatus,
    required String previousStatus,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _notificationService.sendOrderStatusUpdateNotification(
        customerId: customerId,
        orderId: orderId,
        orderNumber: orderNumber,
        newStatus: newStatus,
        previousStatus: previousStatus,
      );

      // Add to local notifications list
      _addNotification(
        NotificationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Order Status Updated',
          body:
              'Order #$orderNumber status changed from $previousStatus to $newStatus',
          type: NotificationType.orderStatusUpdate,
          timestamp: DateTime.now(),
          data: {
            'orderId': orderId,
            'orderNumber': orderNumber,
            'newStatus': newStatus,
            'previousStatus': previousStatus,
          },
        ),
      );

      print('🔔 NotificationProvider: Order status update notification sent');
    } catch (e) {
      _setError('Failed to send order status update notification: $e');
      print('❌ NotificationProvider: Error sending order status update: $e');
    }
  }

  // Send new order notification to all admins
  Future<void> sendNewOrderNotification({
    required String orderId,
    required String orderNumber,
    required String customerName,
    required double totalAmount,
    required String currency,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _notificationService.sendNewOrderNotification(
        orderId: orderId,
        orderNumber: orderNumber,
        customerName: customerName,
        totalAmount: totalAmount,
        currency: currency,
      );

      // Add to local notifications list
      _addNotification(
        NotificationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'New Order Received',
          body:
              'Order #$orderNumber from $customerName - ${currency}${totalAmount.toStringAsFixed(2)}',
          type: NotificationType.newOrder,
          timestamp: DateTime.now(),
          data: {
            'orderId': orderId,
            'orderNumber': orderNumber,
            'customerName': customerName,
            'totalAmount': totalAmount,
            'currency': currency,
          },
        ),
      );

      print('🔔 NotificationProvider: New order notification sent');
    } catch (e) {
      _setError('Failed to send new order notification: $e');
      print('❌ NotificationProvider: Error sending new order notification: $e');
    }
  }

  // Add notification to local list
  void _addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);

    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications = _notifications.take(50).toList();
    }

    notifyListeners();
  }

  // Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _notificationService.subscribeToTopic(topic);
      print('🔔 NotificationProvider: Subscribed to topic: $topic');
    } catch (e) {
      _setError('Failed to subscribe to topic: $e');
      print('❌ NotificationProvider: Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _notificationService.unsubscribeFromTopic(topic);
      print('🔔 NotificationProvider: Unsubscribed from topic: $topic');
    } catch (e) {
      _setError('Failed to unsubscribe from topic: $e');
      print('❌ NotificationProvider: Error unsubscribing from topic: $e');
    }
  }

  // Get current FCM token
  Future<String?> getCurrentToken() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _notificationService.getCurrentToken();
    } catch (e) {
      _setError('Failed to get FCM token: $e');
      print('❌ NotificationProvider: Error getting FCM token: $e');
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

// Notification item model
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.data,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }
}

// Notification types
enum NotificationType {
  orderStatusUpdate,
  newOrder,
  general,
}
