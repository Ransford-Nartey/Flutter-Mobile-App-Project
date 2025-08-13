import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/category_model.dart';

class CategoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'categories';

  // Get all main categories (no parent)
  static Future<List<CategoryModel>> getMainCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('parentCategoryId', isNull: true)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get main categories: $e');
    }
  }

  // Get subcategories for a specific parent category
  static Future<List<CategoryModel>> getSubcategories(String parentCategoryId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('parentCategoryId', isEqualTo: parentCategoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get subcategories: $e');
    }
  }

  // Get all categories (main + subcategories)
  static Future<List<CategoryModel>> getAllCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all categories: $e');
    }
  }

  // Get category by ID
  static Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(categoryId).get();
      if (doc.exists) {
        return CategoryModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  // Search categories by name
  static Future<List<CategoryModel>> searchCategories(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final allCategories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();

      // Filter by name (case-insensitive)
      return allCategories
          .where((category) => category.name
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search categories: $e');
    }
  }

  // Get featured categories (for home screen)
  static Future<List<CategoryModel>> getFeaturedCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('sortOrder', isLessThan: 10) // Featured categories have lower sort order
          .orderBy('sortOrder')
          .limit(6)
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get featured categories: $e');
    }
  }

  // Create a new category
  static Future<String> createCategory(CategoryModel category) async {
    try {
      final docRef = await _firestore.collection(_collection).add(category.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Update category
  static Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(categoryId).update(data);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category (soft delete by setting isActive to false)
  static Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection(_collection).doc(categoryId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Update product count for a category
  static Future<void> updateProductCount(String categoryId, int newCount) async {
    try {
      await _firestore.collection(_collection).doc(categoryId).update({
        'productCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update product count: $e');
    }
  }
}
