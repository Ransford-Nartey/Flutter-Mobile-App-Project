import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  partial,
}

enum PaymentMethod {
  bankTransfer,
  card,
  cash,
  mobileMoney,
  other,
}

class OrderModel {
  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? customerAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final double total;
  final String currency;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String? paymentReference;
  final DateTime? paymentDate;
  final String? notes;
  final String? deliveryInstructions;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  OrderModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    this.shippingCost = 0.0,
    required this.total,
    this.currency = 'GHS',
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod = PaymentMethod.bankTransfer,
    this.paymentReference,
    this.paymentDate,
    this.notes,
    this.deliveryInstructions,
    this.estimatedDelivery,
    this.actualDelivery,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  // Create from Firestore document
  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      return OrderModel(
      id: id,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'],
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item))
          .toList(),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      shippingCost: (data['shippingCost'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'GHS',
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == data['paymentMethod'],
        orElse: () => PaymentMethod.bankTransfer,
      ),
      paymentReference: data['paymentReference'],
      paymentDate: data['paymentDate'] != null
          ? (data['paymentDate'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      deliveryInstructions: data['deliveryInstructions'],
      estimatedDelivery: data['estimatedDelivery'] != null
          ? (data['estimatedDelivery'] as Timestamp).toDate()
          : null,
      actualDelivery: data['actualDelivery'] != null
          ? (data['actualDelivery'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
      );
    } catch (e) {
      print('Error parsing OrderModel from Firestore: $e');
      print('Data: $data');
      rethrow;
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shippingCost': shippingCost,
      'total': total,
      'currency': currency,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'paymentReference': paymentReference,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'notes': notes,
      'deliveryInstructions': deliveryInstructions,
      'estimatedDelivery': estimatedDelivery != null ? Timestamp.fromDate(estimatedDelivery!) : null,
      'actualDelivery': actualDelivery != null ? Timestamp.fromDate(actualDelivery!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? shippingCost,
    double? total,
    String? currency,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    DateTime? paymentDate,
    String? notes,
    String? deliveryInstructions,
    DateTime? estimatedDelivery,
    DateTime? actualDelivery,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      actualDelivery: actualDelivery ?? this.actualDelivery,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get formatted total
  String get formattedTotal {
    return '₵${total.toStringAsFixed(2)}';
  }

  // Get item count
  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Check if order is completed
  bool get isCompleted => status == OrderStatus.delivered;

  // Check if order is cancelled
  bool get isCancelled => status == OrderStatus.cancelled;

  // Check if payment is completed
  bool get isPaid => paymentStatus == PaymentStatus.paid;

  // Get status display text
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  // Get payment status display text
  String get paymentStatusText {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partial:
        return 'Partial';
    }
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, customerName: $customerName, total: $formattedTotal, status: $statusText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class OrderItem {
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String unit;
  final Map<String, dynamic>? specifications;

  OrderItem({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.unit,
    this.specifications,
  });

  // Create from Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'],
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
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
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'unit': unit,
      'specifications': specifications,
    };
  }

  // Create a copy with updated fields
  OrderItem copyWith({
    String? productId,
    String? productName,
    String? productImage,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? unit,
    Map<String, dynamic>? specifications,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      unit: unit ?? this.unit,
      specifications: specifications ?? this.specifications,
    );
  }

  @override
  String toString() {
    return 'OrderItem(productName: $productName, quantity: $quantity, totalPrice: $totalPrice)';
  }
}
