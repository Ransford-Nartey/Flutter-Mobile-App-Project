import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';

class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get _userId => _auth.currentUser?.uid;

  // Get cart collection reference
  static CollectionReference<Map<String, dynamic>> get _cartCollection {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(userId).collection('cart');
  }

  // Save cart to Firestore
  static Future<void> saveCart(Map<String, CartItem> items) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      // Clear existing cart
      await _cartCollection.get().then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Add new cart items
      for (final item in items.values) {
        await _cartCollection.doc(item.productId).set(item.toMap());
      }
    } catch (e) {
      print('Error saving cart to Firestore: $e');
      throw Exception('Failed to save cart: $e');
    }
  }

  // Load cart from Firestore
  static Future<Map<String, CartItem>> loadCart() async {
    try {
      final userId = _userId;
      if (userId == null) return {};

      final snapshot = await _cartCollection.get();
      final Map<String, CartItem> items = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final item = CartItem.fromMap(data);
        items[item.productId] = item;
      }

      return items;
    } catch (e) {
      print('Error loading cart from Firestore: $e');
      return {};
    }
  }

  // Add single item to cart in Firestore
  static Future<void> addCartItem(CartItem item) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      await _cartCollection.doc(item.productId).set(item.toMap());
    } catch (e) {
      print('Error adding cart item to Firestore: $e');
      throw Exception('Failed to add item to cart: $e');
    }
  }

  // Update cart item quantity in Firestore
  static Future<void> updateCartItemQuantity(
      String productId, int quantity) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      if (quantity <= 0) {
        await _cartCollection.doc(productId).delete();
      } else {
        await _cartCollection.doc(productId).update({'quantity': quantity});
      }
    } catch (e) {
      print('Error updating cart item in Firestore: $e');
      throw Exception('Failed to update cart item: $e');
    }
  }

  // Remove cart item from Firestore
  static Future<void> removeCartItem(String productId) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      await _cartCollection.doc(productId).delete();
    } catch (e) {
      print('Error removing cart item from Firestore: $e');
      throw Exception('Failed to remove cart item: $e');
    }
  }

  // Clear cart from Firestore
  static Future<void> clearCart() async {
    try {
      final userId = _userId;
      if (userId == null) return;

      final snapshot = await _cartCollection.get();
      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing cart from Firestore: $e');
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Get cart item count from Firestore
  static Future<int> getCartItemCount() async {
    try {
      final userId = _userId;
      if (userId == null) return 0;

      final snapshot = await _cartCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting cart count from Firestore: $e');
      return 0;
    }
  }

  // Listen to cart changes in real-time
  static Stream<Map<String, CartItem>> cartStream() {
    try {
      final userId = _userId;
      if (userId == null) return Stream.value({});

      return _cartCollection.snapshots().map((snapshot) {
        final Map<String, CartItem> items = {};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final item = CartItem.fromMap(data);
          items[item.productId] = item;
        }
        return items;
      });
    } catch (e) {
      print('Error creating cart stream: $e');
      return Stream.value({});
    }
  }
}
