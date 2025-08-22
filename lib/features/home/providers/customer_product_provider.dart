import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/product_model.dart';

class CustomerProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Getters
  List<ProductModel> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Check if data has been initialized
  bool get isInitialized => _products.isNotEmpty || _categories.isNotEmpty;

  // Filtered products for customer view
  List<ProductModel> get filteredProducts {
    List<ProductModel> filtered = _products
        .where((product) => product.isAvailable && product.stockQuantity > 0)
        .toList();

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((product) {
        // Check if product.category matches the selected category name
        if (product.category.toLowerCase() == _selectedCategory.toLowerCase()) {
          return true;
        }

        // Also check if product.category is a category ID that maps to the selected category name
        final categoryData = _categories.firstWhere(
          (cat) => cat['id'] == product.category,
          orElse: () => {'name': ''},
        );
        return categoryData['name']?.toLowerCase() ==
            _selectedCategory.toLowerCase();
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              product.brand
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              product.subcategory
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  // Get available categories for customer view
  List<String> get availableCategories {
    final categoryNames = _categories
        .where((category) => category['isActive'] == true)
        .map((c) => c['name'] as String)
        .toList();

    categoryNames.sort();
    return ['All', ...categoryNames];
  }

  // Load products from Firestore
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      print('Attempting to load products from Firebase...');

      // First, ensure categories are loaded
      if (_categories.isEmpty) {
        print('Categories not loaded yet, loading categories first...');
        await loadCategories();
        print('Categories loaded: ${_categories.length} categories available');
      }

      final querySnapshot = await _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .get();

      print(
          'Firebase query result: ${querySnapshot.docs.length} documents found');

      if (querySnapshot.docs.isEmpty) {
        print(
            'No products found in Firebase. This might be normal if no products have been added yet.');
        print('Loading sample data for testing...');
        _products = _getSampleProducts();
        print('Sample data loaded: ${_products.length} products');
        // Don't return here, continue to notify listeners
      } else {
        _products = querySnapshot.docs.map((doc) {
          final data = doc.data();
          print('Processing product document: ${doc.id} with data: $data');

          // Get the category ID from the product
          String categoryId = data['category'] ?? '';
          print('Product category ID: "$categoryId"');

          // Find the category name from our loaded categories
          String categoryName = categoryId; // Default to original value
          if (categoryId.isNotEmpty && _categories.isNotEmpty) {
            print(
                'Looking for category ID "$categoryId" in ${_categories.length} categories');
            print(
                'Available category IDs: ${_categories.map((c) => c['id']).join(', ')}');

            final categoryDoc = _categories.firstWhere(
              (cat) => cat['id'] == categoryId,
              orElse: () => {
                'name': categoryId,
                'id': categoryId
              }, // Keep original if not found
            );

            if (categoryDoc['name'] != null &&
                categoryDoc['name'] != categoryId) {
              categoryName = categoryDoc['name'];
              print(
                  'Successfully mapped category ID "$categoryId" to name: "$categoryName"');
            } else {
              print(
                  'Category ID "$categoryId" not found in categories, keeping original value');
              categoryName = categoryId;
            }
          } else {
            print(
                'No categories available or empty category ID, using original value: "$categoryId"');
          }

          // Create a modified data map with the resolved category name
          final modifiedData = Map<String, dynamic>.from(data);
          modifiedData['category'] = categoryName;

          return ProductModel.fromFirestore(modifiedData, doc.id);
        }).toList();

        print('Successfully loaded ${_products.length} products from Firebase');

        // Recalculate product counts for categories after loading products
        if (_categories.isNotEmpty) {
          await _calculateProductCounts();
        }

        // Print first few products for debugging
        if (_products.isNotEmpty) {
          print(
              'First product: ${_products.first.name} - Category: ${_products.first.category}');
        }
      }
    } catch (e) {
      print('Error loading products from Firebase: $e');
      print('Loading sample data as fallback...');
      _products = _getSampleProducts();
      print('Sample data loaded as fallback: ${_products.length} products');
      _setError(
          'Failed to load products from Firebase: $e. Using sample data instead.');
    } finally {
      _setLoading(false);
      // Ensure listeners are notified after loading is complete
      notifyListeners();
    }
  }

  // Load categories from Firestore
  Future<void> loadCategories() async {
    try {
      print('Attempting to load categories from Firebase...');

      // First, try to get all categories without filters to see what exists
      final allCategoriesQuery =
          await _firestore.collection('categories').get();

      print(
          'All categories found: ${allCategoriesQuery.docs.length} documents');

      if (allCategoriesQuery.docs.isEmpty) {
        print(
            'No categories collection exists in Firebase, loading sample categories...');
        _categories = _getSampleCategories();
        print('Sample categories loaded: ${_categories.length} categories');
        notifyListeners();
        return;
      }

      // Now try to get active categories with filters
      final querySnapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();

      print(
          'Active categories query result: ${querySnapshot.docs.length} documents found');

      if (querySnapshot.docs.isEmpty) {
        print('No active categories found, using all categories instead...');
        // If no active categories, use all categories
        _categories = allCategoriesQuery.docs.map((doc) {
          final data = doc.data();
          print('Processing category document: ${doc.id} with data: $data');
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Category',
            'description': data['description'] ?? '',
            'image': data['image'] ?? '',
            'icon': data['icon'] ?? 'category',
            'isActive': data['isActive'] ?? true,
            'sortOrder': data['sortOrder'] ?? 0,
            'productCount': data['productCount'] ?? 0,
          };
        }).toList();
      } else {
        _categories = querySnapshot.docs.map((doc) {
          final data = doc.data();
          print('Processing category document: ${doc.id} with data: $data');
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Category',
            'description': data['description'] ?? '',
            'image': data['image'] ?? '',
            'icon': data['icon'] ?? 'category',
            'isActive': data['isActive'] ?? true,
            'sortOrder': data['sortOrder'] ?? 0,
            'productCount': data['productCount'] ?? 0,
          };
        }).toList();
      }

      print(
          'Successfully loaded ${_categories.length} categories from Firebase');

      // Calculate actual product counts for each category
      await _calculateProductCounts();

      // Print categories for debugging
      for (final category in _categories) {
        print(
            'Category: ${category['name']} - ID: ${category['id']} - Active: ${category['isActive']} - Product Count: ${category['productCount']}');
      }
    } catch (e) {
      print('Error loading categories from Firebase: $e');
      print('Loading sample categories as fallback...');
      // Load sample categories as fallback
      _categories = _getSampleCategories();
      print(
          'Sample categories loaded as fallback: ${_categories.length} categories');
    }

    notifyListeners();
  }

  // Preload all data (categories and products) in sequence
  Future<void> preloadData() async {
    _setLoading(true);
    _clearError();

    try {
      // Load categories first
      await loadCategories();

      // Then load products
      await loadProducts();
    } catch (e) {
      print('Error preloading data: $e');
      _setError('Failed to preload data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get product by ID
  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
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

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    notifyListeners();
  }

  // Reset the provider state (useful for app restart scenarios)
  void resetState() {
    _products = [];
    _categories = [];
    _isLoading = false;
    _error = null;
    _searchQuery = '';
    _selectedCategory = 'All';
    notifyListeners();
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

  // Calculate actual product counts for each category
  Future<void> _calculateProductCounts() async {
    try {
      // Get all available products
      final availableProducts = _products
          .where((product) => product.isAvailable && product.stockQuantity > 0)
          .toList();

      // Calculate product count for each category
      for (final category in _categories) {
        final categoryId = category['id'];
        final categoryName = category['name'];

        // Count products that match this category by ID or name
        int count = availableProducts.where((product) {
          // Check if product category matches category ID
          if (product.category == categoryId) return true;

          // Check if product category matches category name
          if (product.category.toLowerCase() == categoryName.toLowerCase())
            return true;

          return false;
        }).length;

        // Update the category with the calculated product count
        category['productCount'] = count;
        category['calculatedProductCount'] =
            count; // Keep original for reference
      }

      print('Product counts calculated for ${_categories.length} categories');
    } catch (e) {
      print('Error calculating product counts: $e');
    }
  }

  // Sample data for testing when Firebase is empty
  List<ProductModel> _getSampleProducts() {
    return [
      ProductModel(
        id: 'sample-1',
        name: 'Tilapia Starter Feed',
        description: 'High-quality starter feed for young tilapia',
        category: 'Breeders', // This will be the actual category name
        subcategory: 'Starter',
        price: 300.0,
        currency: 'GHS',
        unit: 'kg',
        stockQuantity: 100,
        images: [
          'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Tilapia+Feed'
        ],
        mainImage:
            'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Tilapia+Feed',
        specifications: {'protein': '35%', 'size': '0.5mm'},
        tags: ['tilapia', 'starter', 'feed'],
        isAvailable: true,
        isFeatured: true,
        isOnSale: false,
        rating: 4.5,
        reviewCount: 12,
        brand: 'Cycle Farms',
        countryOfOrigin: 'Ghana',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'sample-2',
        name: 'Catfish Grower Feed',
        description: 'Premium grower feed for catfish development',
        category: 'Breeders', // This will be the actual category name
        subcategory: 'Grower',
        price: 400.0,
        currency: 'GHS',
        unit: 'kg',
        stockQuantity: 75,
        images: [
          'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Catfish+Feed'
        ],
        mainImage:
            'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Catfish+Feed',
        specifications: {'protein': '32%', 'size': '1.0mm'},
        tags: ['catfish', 'grower', 'feed'],
        isAvailable: true,
        isFeatured: false,
        isOnSale: true,
        originalPrice: 450.0,
        rating: 4.2,
        reviewCount: 8,
        brand: 'Cycle Farms',
        countryOfOrigin: 'Ghana',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'sample-3',
        name: 'Hatchery Starter Mix',
        description: 'Essential nutrition for fish hatcheries',
        category: 'Breeders', // This will be the actual category name
        subcategory: 'Starter',
        price: 250.0,
        currency: 'GHS',
        unit: 'kg',
        stockQuantity: 50,
        images: [
          'https://via.placeholder.com/300x200/FF9800/FFFFFF?text=Hatchery+Feed'
        ],
        mainImage:
            'https://via.placeholder.com/300x200/FF9800/FFFFFF?text=Hatchery+Feed',
        specifications: {'protein': '40%', 'size': '0.3mm'},
        tags: ['hatchery', 'starter', 'feed'],
        isAvailable: true,
        isFeatured: false,
        isOnSale: false,
        rating: 4.8,
        reviewCount: 15,
        brand: 'Cycle Farms',
        countryOfOrigin: 'Ghana',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Sample categories for testing when Firebase is empty
  List<Map<String, dynamic>> _getSampleCategories() {
    return [
      {
        'id': 'sample-cat-1',
        'name': 'Breeders',
        'description': 'Breeders feed for fish farming',
        'image':
            'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Breeders+Feed',
        'icon': 'category',
        'isActive': true,
        'sortOrder': 1,
        'productCount': 3,
      },
    ];
  }
}
