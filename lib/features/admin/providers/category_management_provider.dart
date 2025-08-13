import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/category_model.dart';

class CategoryManagementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Filtered categories
  List<CategoryModel> get filteredCategories {
    if (_searchQuery.isEmpty) return _categories;

    return _categories
        .where((category) =>
            category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            category.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // Load all categories
  Future<void> loadCategories() async {
    _setLoading(true);
    _clearError();

    try {
      final querySnapshot = await _firestore.collection('categories').get();
      _categories = querySnapshot.docs.map((doc) {
        return CategoryModel.fromFirestore(doc.data(), doc.id);
      }).toList();

      // Sort by name
      _categories.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _setError('Failed to load categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new category
  Future<String?> createCategory(CategoryModel category) async {
    _setLoading(true);
    _clearError();

    try {
      final docRef =
          await _firestore.collection('categories').add(category.toFirestore());
      category = category.copyWith(id: docRef.id);
      _categories.add(category);
      _categories.sort((a, b) => a.name.compareTo(b.name));
      return docRef.id;
    } catch (e) {
      _setError('Failed to create category: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing category
  Future<bool> updateCategory(
      String categoryId, Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestore.collection('categories').doc(categoryId).update(updates);

      // Update local category
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        final updatedCategory = _categories[index].copyWith(
          name: updates['name'] ?? _categories[index].name,
          description: updates['description'] ?? _categories[index].description,
          image: updates['image'] ?? _categories[index].image,
          isActive: updates['isActive'] ?? _categories[index].isActive,
          updatedAt: DateTime.now(),
        );
        _categories[index] = updatedCategory;
        _categories.sort((a, b) => a.name.compareTo(b.name));
      }

      return true;
    } catch (e) {
      _setError('Failed to update category: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete category
  Future<bool> deleteCategory(String categoryId) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if category has products
      final productsQuery = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .limit(1)
          .get();

      if (productsQuery.docs.isNotEmpty) {
        _setError('Cannot delete category: It contains products');
        return false;
      }

      await _firestore.collection('categories').doc(categoryId).delete();
      _categories.removeWhere((c) => c.id == categoryId);
      return true;
    } catch (e) {
      _setError('Failed to delete category: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle category active status
  Future<bool> toggleCategoryStatus(String categoryId) async {
    try {
      final category = _categories.firstWhere((c) => c.id == categoryId);
      final newStatus = !category.isActive;

      await _firestore.collection('categories').doc(categoryId).update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local category
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(
          isActive: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to toggle category status: $e');
      return false;
    }
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get active categories
  List<CategoryModel> get activeCategories {
    return _categories.where((category) => category.isActive).toList();
  }

  // Search categories
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Check if category name exists
  bool categoryNameExists(String name, {String? excludeId}) {
    return _categories.any((category) =>
        category.name.toLowerCase() == name.toLowerCase() &&
        category.id != excludeId);
  }

  // Get category statistics
  Map<String, int> getCategoryStats() {
    final stats = <String, int>{};
    for (final category in _categories) {
      stats[category.name] =
          0; // This would be populated with actual product counts
    }
    return stats;
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
