import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/order_model.dart';

class OrderManagementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _sortBy = 'createdAt';
  bool _sortAscending = false; // Most recent first by default

  // Getters
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Filtered and sorted orders
  List<OrderModel> get filteredOrders {
    List<OrderModel> filtered = _orders;

    // Filter by status
    if (_selectedStatus != 'All') {
      filtered = filtered
          .where((order) => order.statusText == _selectedStatus)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((order) =>
              order.customerName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              order.customerEmail
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              order.customerPhone.contains(_searchQuery) ||
              order.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort orders
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'total':
          comparison = a.total.compareTo(b.total);
          break;
        case 'customerName':
          comparison = a.customerName.compareTo(b.customerName);
          break;
        case 'status':
          comparison = a.statusText.compareTo(b.statusText);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // Load all orders
  Future<void> loadOrders() async {
    _setLoading(true);
    _clearError();

    try {
      final querySnapshot = await _firestore.collection('orders').get();
      _orders = querySnapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      _setError('Failed to load orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    _setLoading(true);
    _clearError();

    try {
      // Convert string status to OrderStatus enum
      OrderStatus status;
      switch (newStatus.toLowerCase()) {
        case 'pending':
          status = OrderStatus.pending;
          break;
        case 'confirmed':
          status = OrderStatus.confirmed;
          break;
        case 'processing':
          status = OrderStatus.processing;
          break;
        case 'shipped':
          status = OrderStatus.shipped;
          break;
        case 'delivered':
          status = OrderStatus.delivered;
          break;
        case 'cancelled':
          status = OrderStatus.cancelled;
          break;
        case 'refunded':
          status = OrderStatus.refunded;
          break;
        default:
          status = OrderStatus.pending;
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local order
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to update order status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update order delivery information
  Future<bool> updateOrderDelivery(
      String orderId, DateTime estimatedDelivery) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'estimatedDelivery': Timestamp.fromDate(estimatedDelivery),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local order
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          estimatedDelivery: estimatedDelivery,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to update order delivery: $e');
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local order
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: OrderStatus.cancelled,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to cancel order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mark order as delivered
  Future<bool> markOrderDelivered(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'delivered',
        'actualDelivery': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local order
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: OrderStatus.delivered,
          actualDelivery: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to mark order as delivered: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get order by ID
  OrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get order statistics
  Map<String, dynamic> getOrderStats() {
    final totalOrders = _orders.length;
    final pendingOrders = _orders.where((o) => o.status == 'pending').length;
    final processingOrders =
        _orders.where((o) => o.status == 'processing').length;
    final shippedOrders = _orders.where((o) => o.status == 'shipped').length;
    final deliveredOrders =
        _orders.where((o) => o.status == 'delivered').length;
    final cancelledOrders =
        _orders.where((o) => o.status == 'cancelled').length;
    final refundedOrders = _orders.where((o) => o.status == 'refunded').length;

    final totalRevenue = _orders
        .where((o) => o.status != 'cancelled' && o.status != 'refunded')
        .fold(0.0, (sum, order) => sum + order.total);

    final averageOrderValue =
        totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return {
      'totalOrders': totalOrders,
      'pendingOrders': pendingOrders,
      'processingOrders': processingOrders,
      'shippedOrders': shippedOrders,
      'deliveredOrders': deliveredOrders,
      'cancelledOrders': cancelledOrders,
      'refundedOrders': refundedOrders,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
    };
  }

  // Get recent orders
  List<OrderModel> getRecentOrders({int limit = 10}) {
    final sortedOrders = List<OrderModel>.from(_orders);
    sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedOrders.take(limit).toList();
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = true;
    }
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedStatus = 'All';
    _sortBy = 'createdAt';
    _sortAscending = false;
    notifyListeners();
  }

  // Get available statuses for filter
  List<String> get availableStatuses {
    final statuses = _orders.map((o) => o.statusText).toSet().toList();
    statuses.sort();
    return ['All', ...statuses];
  }

  // Private methods
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
