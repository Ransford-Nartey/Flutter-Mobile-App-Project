import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/product_model.dart';

class ProductManagementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name';
  bool _sortAscending = true;

  // Getters
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Filtered and sorted products
  List<ProductModel> get filteredProducts {
    List<ProductModel> filtered = _products;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              product.brand.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort products
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'stock':
          comparison = a.stockQuantity.compareTo(b.stockQuantity);
          break;
        case 'rating':
          comparison = a.rating.compareTo(b.rating);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // Load all products
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      final querySnapshot = await _firestore.collection('products').get();
      _products = querySnapshot.docs.map((doc) {
        return ProductModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      _setError('Failed to load products: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new product
  Future<String?> createProduct(ProductModel product) async {
    _setLoading(true);
    _clearError();

    try {
      final docRef =
          await _firestore.collection('products').add(product.toFirestore());
      product = product.copyWith(id: docRef.id);
      _products.add(product);
      return docRef.id;
    } catch (e) {
      _setError('Failed to create product: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing product
  Future<bool> updateProduct(
      String productId, Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestore.collection('products').doc(productId).update(updates);

      // Update local product
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updatedProduct = _products[index].copyWith(
          name: updates['name'] ?? _products[index].name,
          description: updates['description'] ?? _products[index].description,
          price: updates['price'] ?? _products[index].price,
          stockQuantity:
              updates['stockQuantity'] ?? _products[index].stockQuantity,
          category: updates['category'] ?? _products[index].category,
          subcategory: updates['subcategory'] ?? _products[index].subcategory,
          brand: updates['brand'] ?? _products[index].brand,
          images: updates['images'] ?? _products[index].images,
          specifications:
              updates['specifications'] ?? _products[index].specifications,
          nutritionalInfo:
              updates['nutritionalInfo'] ?? _products[index].nutritionalInfo,
          tags: updates['tags'] ?? _products[index].tags,
          updatedAt: DateTime.now(),
        );
        _products[index] = updatedProduct;
      }

      return true;
    } catch (e) {
      _setError('Failed to update product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestore.collection('products').doc(productId).delete();
      _products.removeWhere((p) => p.id == productId);
      return true;
    } catch (e) {
      _setError('Failed to delete product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update stock quantity
  Future<bool> updateStock(String productId, int newQuantity) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'stockQuantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local product
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          stockQuantity: newQuantity,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to update stock: $e');
      return false;
    }
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = true;
    }
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _sortBy = 'name';
    _sortAscending = true;
    notifyListeners();
  }

  // Get product by ID
  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get categories for filter
  List<String> get categories {
    final categories = _products.map((p) => p.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
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
