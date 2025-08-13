import 'package:flutter/foundation.dart';
import '../services/cart_service.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final String category;
  final double price;
  final String image;
  final int quantity;
  final double totalPrice;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    required this.quantity,
  }) : totalPrice = price * quantity;

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? category,
    double? price,
    String? image,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      image: image ?? this.image,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'category': category,
      'price': price,
      'image': image,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      productId: map['productId'],
      name: map['name'],
      category: map['category'],
      price: map['price'].toDouble(),
      image: map['image'],
      quantity: map['quantity'],
    );
  }
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  int get totalQuantity {
    int total = 0;
    _items.forEach((key, item) {
      total += item.quantity;
    });
    return total;
  }

  void addItem({
    required String productId,
    required String name,
    required String category,
    required double price,
    required String image,
    int quantity = 1,
  }) {
    if (_items.containsKey(productId)) {
      // Update existing item quantity
      final updatedItem = _items[productId]!.copyWith(
        quantity: _items[productId]!.quantity + quantity,
      );
      _items[productId] = updatedItem;
      // Update in Firestore
      CartService.updateCartItemQuantity(productId, updatedItem.quantity);
    } else {
      // Add new item
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        name: name,
        category: category,
        price: price,
        image: image,
        quantity: quantity,
      );
      _items[productId] = newItem;
      // Add to Firestore
      CartService.addCartItem(newItem);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    // Remove from Firestore
    CartService.removeCartItem(productId);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
    } else if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => existingItem.copyWith(quantity: quantity),
      );
      notifyListeners();
      // Update in Firestore
      CartService.updateCartItemQuantity(productId, quantity);
    }
  }

  void incrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      final newQuantity = _items[productId]!.quantity + 1;
      _items.update(
        productId,
        (existingItem) => existingItem.copyWith(quantity: newQuantity),
      );
      notifyListeners();
      // Update in Firestore
      CartService.updateCartItemQuantity(productId, newQuantity);
    }
  }

  void decrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      final currentQuantity = _items[productId]!.quantity;
      if (currentQuantity <= 1) {
        removeItem(productId);
      } else {
        final newQuantity = currentQuantity - 1;
        _items.update(
          productId,
          (existingItem) => existingItem.copyWith(quantity: newQuantity),
        );
        notifyListeners();
        // Update in Firestore
        CartService.updateCartItemQuantity(productId, newQuantity);
      }
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    // Clear from Firestore
    CartService.clearCart();
  }

  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  int getItemQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  // Listen to cart changes in real-time
  Stream<Map<String, CartItem>> get cartStream => CartService.cartStream();

  // Initialize cart from Firestore stream
  void initializeCartStream() {
    CartService.cartStream().listen((items) {
      _items.clear();
      _items.addAll(items);
      notifyListeners();
    });
  }
}
