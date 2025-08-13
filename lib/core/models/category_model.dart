import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String? image;
  final String? icon;
  final String? parentCategoryId; // For subcategories
  final List<String> subcategoryIds;
  final int productCount;
  final bool isActive;
  final int sortOrder;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    this.icon,
    this.parentCategoryId,
    this.subcategoryIds = const [],
    this.productCount = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      image: data['image'],
      icon: data['icon'],
      parentCategoryId: data['parentCategoryId'],
      subcategoryIds: data['subcategoryIds'] != null
          ? List<String>.from(data['subcategoryIds'])
          : [],
      productCount: data['productCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'icon': icon,
      'parentCategoryId': parentCategoryId,
      'subcategoryIds': subcategoryIds,
      'productCount': productCount,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy with updated fields
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    String? icon,
    String? parentCategoryId,
    List<String>? subcategoryIds,
    int? productCount,
    bool? isActive,
    int? sortOrder,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      icon: icon ?? this.icon,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      productCount: productCount ?? this.productCount,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if this is a main category (no parent)
  bool get isMainCategory => parentCategoryId == null;

  // Check if this is a subcategory
  bool get isSubcategory => parentCategoryId != null;

  // Get display name with product count
  String get displayName {
    if (productCount > 0) {
      return '$name ($productCount)';
    }
    return name;
  }

  // Get short description (first 50 characters)
  String get shortDescription {
    if (description.length <= 50) return description;
    return '${description.substring(0, 50)}...';
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, productCount: $productCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Predefined categories for Cycle Farms
class CycleFarmsCategories {
  static const String tilapia = 'tilapia';
  static const String catfish = 'catfish';
  static const String hatchery = 'hatchery';
  static const String general = 'general';

  static const Map<String, String> categoryNames = {
    tilapia: 'Tilapia Feed',
    catfish: 'Catfish Feed',
    hatchery: 'Hatchery Feed',
    general: 'General Feed',
  };

  static const Map<String, String> categoryDescriptions = {
    tilapia:
        'High-quality feed specifically formulated for tilapia farming operations',
    catfish: 'Premium feed optimized for catfish growth and health',
    hatchery: 'Specialized feed for young fish in hatchery operations',
    general: 'Versatile feed suitable for various aquaculture species',
  };

  static const Map<String, String> categoryIcons = {
    tilapia: '🐟',
    catfish: '🐠',
    hatchery: '🥚',
    general: '🌊',
  };

  static List<String> get allCategories => categoryNames.keys.toList();

  static String getCategoryName(String categoryId) {
    return categoryNames[categoryId] ?? 'Unknown Category';
  }

  static String getCategoryDescription(String categoryId) {
    return categoryDescriptions[categoryId] ?? 'No description available';
  }

  static String getCategoryIcon(String categoryId) {
    return categoryIcons[categoryId] ?? '📦';
  }
}
