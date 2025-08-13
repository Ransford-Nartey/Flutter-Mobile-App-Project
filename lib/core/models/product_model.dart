import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'tilapia', 'catfish', 'hatchery', 'general'
  final String subcategory; // 'starter', 'grower', 'finisher'
  final double price;
  final String currency; // 'GHS', 'USD', 'NGN'
  final String unit; // 'kg', 'ton', 'bag'
  final int stockQuantity;
  final List<String> images;
  final String? mainImage;
  final Map<String, dynamic> specifications; // Protein content, size, etc.
  final List<String> tags;
  final bool isAvailable;
  final bool isFeatured;
  final bool isOnSale;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final String brand; // 'Cycle Farms'
  final String? countryOfOrigin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? nutritionalInfo;
  final List<String>? certifications; // ISO, HACCP, etc.
  final String? usageInstructions;
  final String? storageInstructions;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.price,
    this.currency = 'GHS',
    this.unit = 'kg',
    required this.stockQuantity,
    required this.images,
    this.mainImage,
    required this.specifications,
    required this.tags,
    this.isAvailable = true,
    this.isFeatured = false,
    this.isOnSale = false,
    this.originalPrice,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.brand,
    this.countryOfOrigin,
    required this.createdAt,
    required this.updatedAt,
    this.nutritionalInfo,
    this.certifications,
    this.usageInstructions,
    this.storageInstructions,
  });

  // Create from Firestore document
  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'GHS',
      unit: data['unit'] ?? 'kg',
      stockQuantity: data['stockQuantity'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      mainImage: data['mainImage'],
      specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      isOnSale: data['isOnSale'] ?? false,
      originalPrice: data['originalPrice'] != null
          ? (data['originalPrice'] as num).toDouble()
          : null,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      brand: data['brand'] ?? 'Cycle Farms',
      countryOfOrigin: data['countryOfOrigin'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      nutritionalInfo: data['nutritionalInfo'],
      certifications: data['certifications'] != null
          ? List<String>.from(data['certifications'])
          : null,
      usageInstructions: data['usageInstructions'],
      storageInstructions: data['storageInstructions'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'price': price,
      'currency': currency,
      'unit': unit,
      'stockQuantity': stockQuantity,
      'images': images,
      'mainImage': mainImage,
      'specifications': specifications,
      'tags': tags,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'isOnSale': isOnSale,
      'originalPrice': originalPrice,
      'rating': rating,
      'reviewCount': reviewCount,
      'brand': brand,
      'countryOfOrigin': countryOfOrigin,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'nutritionalInfo': nutritionalInfo,
      'certifications': certifications,
      'usageInstructions': usageInstructions,
      'storageInstructions': storageInstructions,
    };
  }

  // Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? subcategory,
    double? price,
    String? currency,
    String? unit,
    int? stockQuantity,
    List<String>? images,
    String? mainImage,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    bool? isAvailable,
    bool? isFeatured,
    bool? isOnSale,
    double? originalPrice,
    double? rating,
    int? reviewCount,
    String? brand,
    String? countryOfOrigin,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? nutritionalInfo,
    List<String>? certifications,
    String? usageInstructions,
    String? storageInstructions,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      images: images ?? this.images,
      mainImage: mainImage ?? this.mainImage,
      specifications: specifications ?? this.specifications,
      tags: tags ?? this.tags,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      isOnSale: isOnSale ?? this.isOnSale,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      brand: brand ?? this.brand,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      certifications: certifications ?? this.certifications,
      usageInstructions: usageInstructions ?? this.usageInstructions,
      storageInstructions: storageInstructions ?? this.storageInstructions,
    );
  }

  // Get formatted price
  String get formattedPrice {
    return '${Currencies.getSymbol(currency)}${price.toStringAsFixed(2)}';
  }

  // Get formatted original price
  String get formattedOriginalPrice {
    if (originalPrice != null) {
      return '${Currencies.getSymbol(currency)}${originalPrice!.toStringAsFixed(2)}';
    }
    return '';
  }

  // Get price per unit
  String get pricePerUnit {
    return '$formattedPrice/$unit';
  }

  // Check if product is in stock
  bool get inStock => stockQuantity > 0 && isAvailable;

  // Get stock status
  String get stockStatus {
    if (!isAvailable) return 'Unavailable';
    if (stockQuantity == 0) return 'Out of Stock';
    if (stockQuantity < 10) return 'Low Stock';
    return 'In Stock';
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, category: $category, price: $formattedPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Currency constants
class Currencies {
  static const String ghs = 'GHS';
  static const String usd = 'USD';
  static const String ngn = 'NGN';

  static List<String> get allCurrencies => [ghs, usd, ngn];

  static String getDisplayName(String currency) {
    switch (currency) {
      case ghs:
        return 'Ghana Cedi';
      case usd:
        return 'US Dollar';
      case ngn:
        return 'Nigerian Naira';
      default:
        return 'Unknown';
    }
  }

  static String getSymbol(String currency) {
    switch (currency) {
      case ghs:
        return '₵';
      case usd:
        return '\$';
      case ngn:
        return '₦';
      default:
        return currency;
    }
  }

  static bool isValid(String currency) {
    return allCurrencies.contains(currency);
  }
}
