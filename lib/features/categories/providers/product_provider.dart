import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _currentCategory = '';
  String _currentSubcategory = '';
  String _currentProductId = '';
  bool _hasMoreProducts = true;
  DocumentSnapshot? _lastDocument;

  // Getters
  List<ProductModel> get products => [..._products];
  List<ProductModel> get featuredProducts => [..._featuredProducts];
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get currentCategory => _currentCategory;
  String get currentSubcategory => _currentSubcategory;
  bool get hasMoreProducts => _hasMoreProducts;

  // Get filtered products based on search query
  List<ProductModel> get filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products
        .where((product) =>
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product.tags.any((tag) =>
                tag.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  // Load products by category
  Future<void> loadProductsByCategory(String category) async {
    try {
      _isLoading = true;
      _error = null;
      _currentCategory = category;
      _currentSubcategory = '';
      _products.clear();
      _hasMoreProducts = true;
      _lastDocument = null;
      notifyListeners();

      _products = await ProductService.getProductsByCategory(category);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load products: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load products by category and subcategory
  Future<void> loadProductsByCategoryAndSubcategory(
      String category, String subcategory) async {
    try {
      _isLoading = true;
      _error = null;
      _currentCategory = category;
      _currentSubcategory = subcategory;
      _products.clear();
      _hasMoreProducts = true;
      _lastDocument = null;
      notifyListeners();

      _products = await ProductService.getProductsByCategoryAndSubcategory(
          category, subcategory);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load products: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load featured products by category
  Future<void> loadFeaturedProductsByCategory(String category) async {
    try {
      _featuredProducts =
          await ProductService.getFeaturedProductsByCategory(category);
      notifyListeners();
    } catch (e) {
      // Don't set error for featured products as it's not critical
      print('Failed to load featured products: $e');
    }
  }

  // Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (!_hasMoreProducts || _isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final newProducts =
          await ProductService.getProductsByCategoryWithPagination(
        _currentCategory,
        lastDocument: _lastDocument,
        limit: 10,
      );

      if (newProducts.isNotEmpty) {
        _products.addAll(newProducts);
        // Note: This is a simplified approach. In a real app, you'd need to store the actual DocumentSnapshot
        // For now, we'll just track if we have more products
        if (newProducts.length < 10) {
          _hasMoreProducts = false;
        }
      }

      if (newProducts.length < 10) {
        _hasMoreProducts = false;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load more products: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search products within current category
  Future<void> searchProducts(String query) async {
    try {
      _searchQuery = query;
      if (query.isEmpty) {
        // If search is empty, reload products
        if (_currentSubcategory.isNotEmpty) {
          await loadProductsByCategoryAndSubcategory(
              _currentCategory, _currentSubcategory);
        } else {
          await loadProductsByCategory(_currentCategory);
        }
      } else {
        // Perform search
        _isLoading = true;
        notifyListeners();

        _products = await ProductService.searchProductsInCategory(
            _currentCategory, query);
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to search products: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    if (_currentSubcategory.isNotEmpty) {
      loadProductsByCategoryAndSubcategory(
          _currentCategory, _currentSubcategory);
    } else {
      loadProductsByCategory(_currentCategory);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data (for logout or category change)
  void clearData() {
    _products.clear();
    _featuredProducts.clear();
    _error = null;
    _searchQuery = '';
    _currentCategory = '';
    _currentSubcategory = '';
    _hasMoreProducts = true;
    _lastDocument = null;
    notifyListeners();
  }

  // Refresh products
  Future<void> refreshProducts() async {
    if (_currentSubcategory.isNotEmpty) {
      await loadProductsByCategoryAndSubcategory(
          _currentCategory, _currentSubcategory);
    } else {
      await loadProductsByCategory(_currentCategory);
    }

    if (_currentCategory.isNotEmpty) {
      await loadFeaturedProductsByCategory(_currentCategory);
    }
  }

  // Load product by ID
  Future<void> loadProductById(String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final product = await ProductService.getProductById(productId);
      if (product != null) {
        _products = [product];
        _currentProductId = productId;
      } else {
        _error = 'Product not found';
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load product: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get current product
  ProductModel? get currentProduct {
    if (_products.isNotEmpty) {
      return _products.first;
    }
    return null;
  }
}
