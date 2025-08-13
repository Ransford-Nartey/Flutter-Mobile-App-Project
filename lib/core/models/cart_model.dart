import 'package:cloud_firestore/cloud_firestore.dart';

class CartModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory CartModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CartModel(
      id: id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>)
          .map((item) => CartItem.fromMap(item))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy with updated fields
  CartModel copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get total number of items
  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get subtotal
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Get formatted subtotal
  String get formattedSubtotal {
    return '₵${subtotal.toStringAsFixed(2)}';
  }

  // Check if cart is empty
  bool get isEmpty => items.isEmpty;

  // Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  // Get item by product ID
  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Add item to cart
  CartModel addItem(CartItem newItem) {
    final existingItemIndex = items.indexWhere(
      (item) => item.productId == newItem.productId,
    );

    List<CartItem> updatedItems;
    if (existingItemIndex != -1) {
      // Update existing item quantity
      updatedItems = List.from(items);
      final existingItem = updatedItems[existingItemIndex];
      updatedItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + newItem.quantity,
        totalPrice: (existingItem.unitPrice *
            (existingItem.quantity + newItem.quantity)),
      );
    } else {
      // Add new item
      updatedItems = [...items, newItem];
    }

    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  // Update item quantity
  CartModel updateItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }

    final updatedItems = items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(
          quantity: quantity,
          totalPrice: item.unitPrice * quantity,
        );
      }
      return item;
    }).toList();

    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  // Remove item from cart
  CartModel removeItem(String productId) {
    final updatedItems =
        items.where((item) => item.productId != productId).toList();
    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
  }

  // Clear cart
  CartModel clear() {
    return copyWith(
      items: [],
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CartModel(id: $id, userId: $userId, itemCount: $itemCount, subtotal: $formattedSubtotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CartItem {
  final String productId;
  final String productName;
  final String? productImage;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final String unit;
  final Map<String, dynamic>? specifications;

  CartItem({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.unit,
    this.specifications,
  });

  // Create from Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'],
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'kg',
      specifications: map['specifications'],
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'unit': unit,
      'specifications': specifications,
    };
  }

  // Create a copy with updated fields
  CartItem copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? unitPrice,
    int? quantity,
    double? totalPrice,
    String? unit,
    Map<String, dynamic>? specifications,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      unit: unit ?? this.unit,
      specifications: specifications ?? this.specifications,
    );
  }

  // Get formatted unit price
  String get formattedUnitPrice {
    return '₵${unitPrice.toStringAsFixed(2)}';
  }

  // Get formatted total price
  String get formattedTotalPrice {
    return '₵${totalPrice.toStringAsFixed(2)}';
  }

  // Get price per unit
  String get pricePerUnit {
    return '$formattedUnitPrice/$unit';
  }

  @override
  String toString() {
    return 'CartItem(productName: $productName, quantity: $quantity, totalPrice: $formattedTotalPrice)';
  }
}
