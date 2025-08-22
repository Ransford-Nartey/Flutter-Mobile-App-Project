import 'package:flutter/foundation.dart';
import '../../../core/models/order_model.dart';
import '../services/order_service.dart';
import '../../../core/services/notification_service.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => [..._orders];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get orders by status
  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Get pending orders
  List<OrderModel> get pendingOrders => getOrdersByStatus(OrderStatus.pending);

  // Get confirmed orders
  List<OrderModel> get confirmedOrders =>
      getOrdersByStatus(OrderStatus.confirmed);

  // Get processing orders
  List<OrderModel> get processingOrders =>
      getOrdersByStatus(OrderStatus.processing);

  // Get shipped orders
  List<OrderModel> get shippedOrders => getOrdersByStatus(OrderStatus.shipped);

  // Get delivered orders
  List<OrderModel> get deliveredOrders =>
      getOrdersByStatus(OrderStatus.delivered);

  // Get cancelled orders
  List<OrderModel> get cancelledOrders =>
      getOrdersByStatus(OrderStatus.cancelled);

  // Load user orders
  Future<void> loadUserOrders(String userId) async {
    try {
      print('Loading orders for user: $userId'); // Debug log
      _isLoading = true;
      _error = null;
      notifyListeners();

      // First test if the orders collection is accessible
      final collectionTest = await OrderService.testOrdersCollection();
      if (!collectionTest) {
        throw Exception('Orders collection is not accessible');
      }

      // Use a one-time fetch instead of stream to avoid infinite waiting
      // Add timeout to prevent infinite waiting
      final orders = await OrderService.getUserOrdersOnce(userId)
          .timeout(const Duration(seconds: 10));
      print('Loaded ${orders.length} orders'); // Debug log
      _orders = orders;
      notifyListeners();
    } catch (e) {
      print('Error loading orders: $e'); // Debug log
      if (e.toString().contains('timeout')) {
        _error = 'Request timed out. Please check your internet connection.';
      } else {
        _error = 'Failed to load orders: $e';
      }
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new order
  Future<String?> createOrder(OrderModel order) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final orderId = await OrderService.createOrder(order);

      // Add the new order to the list
      _orders.insert(0, order);
      notifyListeners();

      // Send notification to all admins about new order
      try {
        // Use the existing NotificationProvider from context instead of creating new instance
        // This will be handled by the UI layer that has access to the context
        print(
            '🔔 OrderProvider: New order created, notification should be sent via UI');
      } catch (e) {
        print('⚠️ OrderProvider: Failed to handle notification: $e');
        // Don't fail the order creation if notification fails
      }

      return orderId;
    } catch (e) {
      _error = 'Failed to create order: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await OrderService.updateOrderStatus(orderId, status);

      // Update local order
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(status: status);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update order status: $e';
      notifyListeners();
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String orderId, PaymentStatus status) async {
    try {
      await OrderService.updatePaymentStatus(orderId, status);

      // Update local order
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(
          paymentStatus: status,
          paymentDate: status == PaymentStatus.paid ? DateTime.now() : null,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update payment status: $e';
      notifyListeners();
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await OrderService.cancelOrder(orderId, reason);

      // Update local order
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(
          status: OrderStatus.cancelled,
          notes: reason,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to cancel order: $e';
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear orders (for logout)
  void clearOrders() {
    _orders.clear();
    _error = null;
    notifyListeners();
  }
}
