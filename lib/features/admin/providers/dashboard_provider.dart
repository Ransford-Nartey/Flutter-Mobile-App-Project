import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _recentProducts = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _salesData = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get recentOrders => _recentOrders;
  List<Map<String, dynamic>> get recentProducts => _recentProducts;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<Map<String, dynamic>> get salesData => _salesData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load dashboard data
  Future<void> loadDashboardData() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        _loadStats(),
        _loadRecentOrders(),
        _loadRecentProducts(),
        _loadTopProducts(),
        _loadSalesData(),
      ]);
    } catch (e) {
      _setError('Failed to load dashboard data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load overall statistics
  Future<void> _loadStats() async {
    try {
      // Get total orders
      final ordersQuery = await _firestore.collection('orders').get();
      final totalOrders = ordersQuery.docs.length;

      // Get total revenue
      double totalRevenue = 0;
      for (final doc in ordersQuery.docs) {
        final data = doc.data();
        if (data['status'] != 'cancelled' && data['status'] != 'refunded') {
          totalRevenue += (data['total'] ?? 0).toDouble();
        }
      }

      // Get total products
      final productsQuery = await _firestore.collection('products').get();
      final totalProducts = productsQuery.docs.length;

      // Get total customers
      final customersQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'customer')
          .get();
      final totalCustomers = customersQuery.docs.length;

      // Get pending orders
      final pendingOrders = ordersQuery.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;

      // Get low stock products
      final lowStockProducts = productsQuery.docs
          .where((doc) => (doc.data()['stockQuantity'] ?? 0) < 10)
          .length;

      _stats = {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'totalProducts': totalProducts,
        'totalCustomers': totalCustomers,
        'pendingOrders': pendingOrders,
        'lowStockProducts': lowStockProducts,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      };
    } catch (e) {
      _setError('Failed to load statistics: $e');
    }
  }

  // Load recent orders
  Future<void> _loadRecentOrders() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      _recentOrders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'customerName': data['customerName'] ?? '',
          'total': data['total'] ?? 0.0,
          'status': data['status'] ?? 'pending',
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
          'items': data['items'] ?? [],
        };
      }).toList();
    } catch (e) {
      _setError('Failed to load recent orders: $e');
    }
  }

  // Load recent products
  Future<void> _loadRecentProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      _recentProducts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'price': data['price'] ?? 0.0,
          'stockQuantity': data['stockQuantity'] ?? 0,
          'rating': data['rating'] ?? 0.0,
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      _setError('Failed to load recent products: $e');
    }
  }

  // Load top selling products
  Future<void> _loadTopProducts() async {
    try {
      // Get all products ordered by rating
      final productsQuery = await _firestore
          .collection('products')
          .orderBy('rating', descending: true)
          .limit(5)
          .get();

      // Get all completed orders to calculate sales counts
      final ordersQuery = await _firestore.collection('orders').where('status',
          whereIn: ['confirmed', 'processing', 'shipped', 'delivered']).get();

      // Calculate sales count for each product
      final Map<String, int> productSalesCount = {};

      for (final orderDoc in ordersQuery.docs) {
        final orderData = orderDoc.data();
        final items = orderData['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          final productId = item['productId']?.toString() ?? '';
          if (productId.isNotEmpty) {
            final quantity = (item['quantity'] ?? 0) as int;
            productSalesCount[productId] =
                (productSalesCount[productId] ?? 0) + quantity;
          }
        }
      }

      _topProducts = productsQuery.docs.map((doc) {
        final data = doc.data();
        final productId = doc.id;
        return {
          'id': productId,
          'name': data['name'] ?? '',
          'price': data['price'] ?? 0.0,
          'rating': data['rating'] ?? 0.0,
          'stockQuantity': data['stockQuantity'] ?? 0,
          'salesCount': productSalesCount[productId] ?? 0,
        };
      }).toList();
    } catch (e) {
      _setError('Failed to load top products: $e');
    }
  }

  // Load sales data for charts
  Future<void> _loadSalesData() async {
    try {
      // Get orders from the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final querySnapshot = await _firestore
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .where('status', whereIn: [
        'confirmed',
        'processing',
        'shipped',
        'delivered'
      ]).get();

      // Group by date
      final Map<String, double> dailySales = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final date = (data['createdAt'] as Timestamp).toDate();
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        dailySales[dateKey] =
            (dailySales[dateKey] ?? 0) + (data['total'] ?? 0).toDouble();
      }

      // Convert to list and sort by date
      _salesData = dailySales.entries.map((entry) {
        return {
          'date': entry.key,
          'sales': entry.value,
        };
      }).toList();

      _salesData.sort((a, b) => a['date'].compareTo(b['date']));
    } catch (e) {
      _setError('Failed to load sales data: $e');
    }
  }

  // Refresh dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  // Get revenue for specific period
  Future<double> getRevenueForPeriod(DateTime start, DateTime end) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('status', whereIn: [
        'confirmed',
        'processing',
        'shipped',
        'delivered'
      ]).get();

      double totalRevenue = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['total'] ?? 0).toDouble();
      }

      return totalRevenue;
    } catch (e) {
      _setError('Failed to get revenue for period: $e');
      return 0.0;
    }
  }

  // Get orders count for specific period
  Future<int> getOrdersCountForPeriod(DateTime start, DateTime end) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      _setError('Failed to get orders count for period: $e');
      return 0;
    }
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
