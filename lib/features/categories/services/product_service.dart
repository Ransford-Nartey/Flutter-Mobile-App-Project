import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/product_model.dart';

class ProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'products';

  // Get products by category
  static Future<List<ProductModel>> getProductsByCategory(
      String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .orderBy('isFeatured', descending: true)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  // Get products by category and subcategory
  static Future<List<ProductModel>> getProductsByCategoryAndSubcategory(
      String category, String subcategory) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('subcategory', isEqualTo: subcategory)
          .where('isAvailable', isEqualTo: true)
          .orderBy('isFeatured', descending: true)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category and subcategory: $e');
    }
  }

  // Get featured products by category
  static Future<List<ProductModel>> getFeaturedProductsByCategory(
      String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isFeatured', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(6)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get featured products by category: $e');
    }
  }

  // Search products within a category
  static Future<List<ProductModel>> searchProductsInCategory(
      String category, String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .get();

      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
          .toList();

      // Filter by name, description, or tags (case-insensitive)
      return allProducts
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.description.toLowerCase().contains(query.toLowerCase()) ||
              product.tags.any(
                  (tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products in category: $e');
    }
  }

  // Get product by ID
  static Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Get products with pagination
  static Future<List<ProductModel>> getProductsByCategoryWithPagination(
    String category, {
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .orderBy('isFeatured', descending: true)
          .orderBy('rating', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products with pagination: $e');
    }
  }
}
