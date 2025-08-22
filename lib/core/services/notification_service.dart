import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification channels
  static const String _orderUpdatesChannel = 'order_updates';
  static const String _newOrdersChannel = 'new_orders';
  static const String _generalChannel = 'general';

  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('🔔 NotificationService: Permission granted');
      } else {
        print('🔔 NotificationService: Permission denied');
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('🔔 NotificationService: FCM Token: $token');
        await _saveTokenToDatabase(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      print('🔔 NotificationService: Initialized successfully');
    } catch (e) {
      print('❌ NotificationService: Error initializing: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // Order Updates Channel (for customers)
    const AndroidNotificationChannel orderUpdatesChannel =
        AndroidNotificationChannel(
      _orderUpdatesChannel,
      'Order Updates',
      description: 'Notifications about your order status changes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // New Orders Channel (for admins)
    const AndroidNotificationChannel newOrdersChannel =
        AndroidNotificationChannel(
      _newOrdersChannel,
      'New Orders',
      description: 'Notifications about new customer orders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // General Channel
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      _generalChannel,
      'General',
      description: 'General app notifications',
      importance: Importance.low,
      playSound: true,
      enableVibration: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderUpdatesChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(newOrdersChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('🔔 NotificationService: FCM token saved to database');
      }
    } catch (e) {
      print('❌ NotificationService: Error saving token: $e');
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
    try {
      // Get customer's FCM token
      final customerDoc =
          await _firestore.collection('users').doc(customerId).get();
      final fcmToken = customerDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        // Send FCM notification
        await _sendFCMNotification(
          token: fcmToken,
          title: 'Order Status Updated',
          body:
              'Your order #$orderNumber status changed from $previousStatus to $newStatus',
          data: {
            'type': 'order_status_update',
            'orderId': orderId,
            'orderNumber': orderNumber,
            'newStatus': newStatus,
            'previousStatus': previousStatus,
          },
        );

        // Send local notification
        await _showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: 'Order Status Updated',
          body:
              'Your order #$orderNumber status changed from $previousStatus to $newStatus',
          payload: 'order_status_update:$orderId',
          channelId: _orderUpdatesChannel,
        );

        print(
            '🔔 NotificationService: Order status update notification sent to customer $customerId');
      } else {
        print('⚠️ NotificationService: Customer $customerId has no FCM token');
      }
    } catch (e) {
      print(
          '❌ NotificationService: Error sending order status update notification: $e');
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
    try {
      // Get all admin users
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final adminDoc in adminQuery.docs) {
        final fcmToken = adminDoc.data()['fcmToken'];
        if (fcmToken != null) {
          // Send FCM notification
          await _sendFCMNotification(
            token: fcmToken,
            title: 'New Order Received',
            body:
                'Order #$orderNumber from $customerName - ${currency}${totalAmount.toStringAsFixed(2)}',
            data: {
              'type': 'new_order',
              'orderId': orderId,
              'orderNumber': orderNumber,
              'customerName': customerName,
              'totalAmount': totalAmount.toString(),
              'currency': currency,
            },
          );

          // Send local notification
          await _showLocalNotification(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: 'New Order Received',
            body:
                'Order #$orderNumber from $customerName - ${currency}${totalAmount.toStringAsFixed(2)}',
            payload: 'new_order:$orderId',
            channelId: _newOrdersChannel,
          );
        }
      }

      print(
          '🔔 NotificationService: New order notifications sent to ${adminQuery.docs.length} admins');
    } catch (e) {
      print('❌ NotificationService: Error sending new order notifications: $e');
    }
  }

  // Send FCM notification
  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // This would typically be done through a backend server
      // For now, we'll just log it
      print('🔔 NotificationService: FCM notification would be sent:');
      print('  Token: $token');
      print('  Title: $title');
      print('  Body: $body');
      print('  Data: $data');

      // TODO: Implement actual FCM sending through backend
      // await http.post(
      //   Uri.parse('https://fcm.googleapis.com/fcm/send'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'key=YOUR_SERVER_KEY',
      //   },
      //   body: jsonEncode({
      //     'to': token,
      //     'notification': {
      //       'title': title,
      //       'body': body,
      //     },
      //     'data': data,
      //   }),
      // );
    } catch (e) {
      print('❌ NotificationService: Error sending FCM notification: $e');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required String channelId,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 NotificationService: Foreground message received:');
    print('  Title: ${message.notification?.title}');
    print('  Body: ${message.notification?.body}');
    print('  Data: ${message.data}');

    // Show local notification for foreground messages
    _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      channelId: _generalChannel,
    );
  }

  // Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 NotificationService: Notification tapped:');
    print('  Data: ${message.data}');

    // Handle navigation based on notification type
    _handleNotificationNavigation(message.data);
  }

  // Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 NotificationService: Local notification tapped:');
    print('  Payload: ${response.payload}');

    if (response.payload != null) {
      final parts = response.payload!.split(':');
      if (parts.length == 2) {
        final type = parts[0];
        final id = parts[1];
        _handleNotificationNavigation({'type': type, 'id': id});
      }
    }
  }

  // Handle navigation based on notification type
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final id = data['id'];

    switch (type) {
      case 'order_status_update':
        print('🔔 NotificationService: Navigate to order details: $id');
        // TODO: Navigate to order details screen
        break;
      case 'new_order':
        print('🔔 NotificationService: Navigate to order management: $id');
        // TODO: Navigate to order management screen
        break;
      default:
        print('🔔 NotificationService: Unknown notification type: $type');
    }
  }

  // Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('🔔 NotificationService: Subscribed to topic: $topic');
    } catch (e) {
      print('❌ NotificationService: Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('🔔 NotificationService: Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ NotificationService: Error unsubscribing from topic: $e');
    }
  }

  // Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ NotificationService: Error getting current token: $e');
      return null;
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 NotificationService: Background message received:');
  print('  Title: ${message.notification?.title}');
  print('  Body: ${message.notification?.body}');
  print('  Data: ${message.data}');
}
