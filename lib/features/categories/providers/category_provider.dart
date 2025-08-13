import 'package:flutter/foundation.dart';
import '../../../core/models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<CategoryModel> _mainCategories = [];
  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _featuredCategories = [];
  Map<String, List<CategoryModel>> _subcategories = {};
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<CategoryModel> get mainCategories => [..._mainCategories];
  List<CategoryModel> get allCategories => [..._allCategories];
  List<CategoryModel> get featuredCategories => [..._featuredCategories];
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Get subcategories for a specific parent
  List<CategoryModel> getSubcategories(String parentCategoryId) {
    return _subcategories[parentCategoryId] ?? [];
  }

  // Get filtered categories based on search query
  List<CategoryModel> get filteredCategories {
    if (_searchQuery.isEmpty) {
      return _allCategories;
    }
    return _allCategories
        .where((category) => category.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // Load main categories
  Future<void> loadMainCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _mainCategories = await CategoryService.getMainCategories();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load main categories: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all categories
  Future<void> loadAllCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _allCategories = await CategoryService.getAllCategories();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load all categories: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load featured categories
  Future<void> loadFeaturedCategories() async {
    try {
      _featuredCategories = await CategoryService.getFeaturedCategories();
      notifyListeners();
    } catch (e) {
      // Don't set error for featured categories as it's not critical
      print('Failed to load featured categories: $e');
    }
  }

  // Load subcategories for a specific parent
  Future<void> loadSubcategories(String parentCategoryId) async {
    try {
      final subcategories = await CategoryService.getSubcategories(parentCategoryId);
      _subcategories[parentCategoryId] = subcategories;
      notifyListeners();
    } catch (e) {
      print('Failed to load subcategories: $e');
    }
  }

  // Search categories
  Future<void> searchCategories(String query) async {
    try {
      _searchQuery = query;
      if (query.isEmpty) {
        // If search is empty, load all categories
        await loadAllCategories();
      } else {
        // Perform search
        _isLoading = true;
        notifyListeners();

        _allCategories = await CategoryService.searchCategories(query);
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to search categories: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    loadAllCategories();
  }

  // Create new category
  Future<String?> createCategory(CategoryModel category) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final categoryId = await CategoryService.createCategory(category);
      
      // Add to local lists
      if (category.isMainCategory) {
        _mainCategories.add(category.copyWith(id: categoryId));
        _allCategories.add(category.copyWith(id: categoryId));
      } else {
        _allCategories.add(category.copyWith(id: categoryId));
        // Add to subcategories if parent exists
        if (category.parentCategoryId != null) {
          if (_subcategories[category.parentCategoryId!] != null) {
            _subcategories[category.parentCategoryId!]!.add(category.copyWith(id: categoryId));
          }
        }
      }

      notifyListeners();
      return categoryId;
    } catch (e) {
      _error = 'Failed to create category: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update category
  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    try {
      await CategoryService.updateCategory(categoryId, data);
      
      // Update local lists
      _updateLocalCategory(categoryId, data);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update category: $e';
      notifyListeners();
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await CategoryService.deleteCategory(categoryId);
      
      // Remove from local lists
      _removeLocalCategory(categoryId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
    }
  }

  // Update product count for a category
  Future<void> updateProductCount(String categoryId, int newCount) async {
    try {
      await CategoryService.updateProductCount(categoryId, newCount);
      
      // Update local category
      _updateLocalCategory(categoryId, {'productCount': newCount});
      notifyListeners();
    } catch (e) {
      print('Failed to update product count: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data (for logout)
  void clearData() {
    _mainCategories.clear();
    _allCategories.clear();
    _featuredCategories.clear();
    _subcategories.clear();
    _error = null;
    _searchQuery = '';
    notifyListeners();
  }

  // Helper method to update local category
  void _updateLocalCategory(String categoryId, Map<String, dynamic> data) {
    // Update in main categories
    final mainIndex = _mainCategories.indexWhere((cat) => cat.id == categoryId);
    if (mainIndex != -1) {
      _mainCategories[mainIndex] = _mainCategories[mainIndex].copyWith(
        name: data['name'] ?? _mainCategories[mainIndex].name,
        description: data['description'] ?? _mainCategories[mainIndex].description,
        image: data['image'] ?? _mainCategories[mainIndex].image,
        icon: data['icon'] ?? _mainCategories[mainIndex].icon,
        productCount: data['productCount'] ?? _mainCategories[mainIndex].productCount,
        isActive: data['isActive'] ?? _mainCategories[mainIndex].isActive,
        sortOrder: data['sortOrder'] ?? _mainCategories[mainIndex].sortOrder,
      );
    }

    // Update in all categories
    final allIndex = _allCategories.indexWhere((cat) => cat.id == categoryId);
    if (allIndex != -1) {
      _allCategories[allIndex] = _allCategories[allIndex].copyWith(
        name: data['name'] ?? _allCategories[allIndex].name,
        description: data['description'] ?? _allCategories[allIndex].description,
        image: data['image'] ?? _allCategories[allIndex].image,
        icon: data['icon'] ?? _allCategories[allIndex].icon,
        productCount: data['productCount'] ?? _allCategories[allIndex].productCount,
        isActive: data['isActive'] ?? _allCategories[allIndex].isActive,
        sortOrder: data['sortOrder'] ?? _allCategories[allIndex].sortOrder,
      );
    }

    // Update in subcategories
    for (final entry in _subcategories.entries) {
      final subIndex = entry.value.indexWhere((cat) => cat.id == categoryId);
      if (subIndex != -1) {
        entry.value[subIndex] = entry.value[subIndex].copyWith(
          name: data['name'] ?? entry.value[subIndex].name,
          description: data['description'] ?? entry.value[subIndex].description,
          image: data['image'] ?? entry.value[subIndex].image,
          icon: data['icon'] ?? entry.value[subIndex].icon,
          productCount: data['productCount'] ?? entry.value[subIndex].productCount,
          isActive: data['isActive'] ?? entry.value[subIndex].isActive,
          sortOrder: data['sortOrder'] ?? entry.value[subIndex].sortOrder,
        );
      }
    }
  }

  // Helper method to remove local category
  void _removeLocalCategory(String categoryId) {
    _mainCategories.removeWhere((cat) => cat.id == categoryId);
    _allCategories.removeWhere((cat) => cat.id == categoryId);
    _featuredCategories.removeWhere((cat) => cat.id == categoryId);
    
    for (final entry in _subcategories.entries) {
      entry.value.removeWhere((cat) => cat.id == categoryId);
    }
  }
}
