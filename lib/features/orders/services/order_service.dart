import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/order_model.dart';

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'orders';

  // Create a new order
  static Future<String> createOrder(OrderModel order) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(order.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get user orders
  static Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Get user orders once (for initial load)
  static Future<List<OrderModel>> getUserOrdersOnce(String userId) async {
    try {
      print('OrderService: Fetching orders for user $userId'); // Debug log
      

      
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      print('OrderService: Got ${snapshot.docs.length} documents'); // Debug log
      
      if (snapshot.docs.isEmpty) {
        print('OrderService: No orders found for user $userId'); // Debug log
        return [];
      }
      
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();
      print('OrderService: Parsed ${orders.length} orders'); // Debug log
      return orders;
    } catch (e) {
      print('OrderService: Error fetching orders: $e'); // Debug log
      if (e.toString().contains('permission-denied')) {
        throw Exception('Access denied. Please check your permissions.');
      } else if (e.toString().contains('unavailable')) {
        throw Exception('Service unavailable. Please try again later.');
      } else {
        throw Exception('Failed to get user orders: $e');
      }
    }
  }

  // Get order by ID
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Update order status
  static Future<void> updateOrderStatus(
      String orderId, OrderStatus status) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Update payment status
  static Future<void> updatePaymentStatus(
      String orderId, PaymentStatus status) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'paymentStatus': status.toString().split('.').last,
        'paymentDate':
            status == PaymentStatus.paid ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Cancel order
  static Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'status': OrderStatus.cancelled.toString().split('.').last,
        'notes': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Test method to check if orders collection exists and has data
  static Future<bool> testOrdersCollection() async {
    try {
      print('OrderService: Testing orders collection...'); // Debug log
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      print('OrderService: Collection test successful, found ${snapshot.docs.length} documents'); // Debug log
      return true;
    } catch (e) {
      print('OrderService: Collection test failed: $e'); // Debug log
      return false;
    }
  }
}
