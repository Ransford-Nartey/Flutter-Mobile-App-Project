import 'package:flutter/foundation.dart';
import '../../../core/models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  List<ReviewModel> _reviews = [];
  Map<String, dynamic> _reviewStats = {};
  bool _isLoading = false;
  String? _error;
  String _currentProductId = '';
  String _currentUserId = '';

  // Callback to refresh product data when reviews change
  VoidCallback? _onProductDataChanged;

  // Getters
  List<ReviewModel> get reviews => [..._reviews];
  Map<String, dynamic> get reviewStats => Map.from(_reviewStats);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentProductId => _currentProductId;
  String get currentUserId => _currentUserId;

  // Get all reviews (no filtering)
  List<ReviewModel> get filteredReviews => _reviews;

  // Set callback to refresh product data
  void setProductDataRefreshCallback(VoidCallback callback) {
    _onProductDataChanged = callback;
  }

  // Get average rating
  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.map((r) => r.rating).reduce((a, b) => a + b);
    return total / _reviews.length;
  }

  // Get total reviews count
  int get totalReviews => _reviews.length;

  // Get verified purchase count
  int get verifiedPurchaseCount {
    return _reviews.where((r) => r.isVerifiedPurchase).length;
  }

  // Load reviews for a specific product
  Future<void> loadProductReviews(String productId) async {
    try {
      print('ReviewProvider: Loading reviews for product: $productId');
      _isLoading = true;
      _error = null;
      _currentProductId = productId;
      _reviews.clear();
      notifyListeners();

      _reviews = await ReviewService.getProductReviews(productId);
      print('ReviewProvider: Loaded ${_reviews.length} reviews');

      // Load review statistics
      await _loadReviewStats(productId);

      notifyListeners();
    } catch (e) {
      print('ReviewProvider: Error loading reviews: $e');
      _error = 'Failed to load reviews: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load reviews by user
  Future<void> loadUserReviews(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      _currentUserId = userId;
      _reviews.clear();
      notifyListeners();

      _reviews = await ReviewService.getUserReviews(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user reviews: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load review statistics
  Future<void> _loadReviewStats(String productId) async {
    try {
      _reviewStats = await ReviewService.getProductReviewStats(productId);
    } catch (e) {
      print('Failed to load review stats: $e');
    }
  }

  // Create a new review
  Future<String?> createReview(ReviewModel review) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final reviewId = await ReviewService.createReview(review);

      // Add to local list
      _reviews.insert(0, review.copyWith(id: reviewId));

      // Reload review stats and refresh reviews
      if (_currentProductId.isNotEmpty) {
        await _loadReviewStats(_currentProductId);
        await loadProductReviews(_currentProductId); // Refresh the reviews list
      }

      notifyListeners();

      // Notify product data to refresh
      _onProductDataChanged?.call();

      return reviewId;
    } catch (e) {
      _error = 'Failed to create review: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing review
  Future<void> updateReview(String reviewId, Map<String, dynamic> data) async {
    try {
      await ReviewService.updateReview(reviewId, data);

      // Update local review
      final index = _reviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        _reviews[index] = _reviews[index].copyWith(
          title: data['title'] ?? _reviews[index].title,
          comment: data['comment'] ?? _reviews[index].comment,
          rating: data['rating'] ?? _reviews[index].rating,
          images: data['images'] ?? _reviews[index].images,
          updatedAt: DateTime.now(),
        );
      }

      // Reload review stats and refresh reviews
      if (_currentProductId.isNotEmpty) {
        await _loadReviewStats(_currentProductId);
        await loadProductReviews(_currentProductId); // Refresh the reviews list
      }

      notifyListeners();

      // Notify product data to refresh
      _onProductDataChanged?.call();
    } catch (e) {
      _error = 'Failed to update review: $e';
      notifyListeners();
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await ReviewService.deleteReview(reviewId);

      // Remove from local list
      _reviews.removeWhere((r) => r.id == reviewId);

      // Reload review stats and refresh reviews
      if (_currentProductId.isNotEmpty) {
        await _loadReviewStats(_currentProductId);
        await loadProductReviews(_currentProductId); // Refresh the reviews list
      }

      notifyListeners();

      // Notify product data to refresh
      _onProductDataChanged?.call();
    } catch (e) {
      _error = 'Failed to delete review: $e';
      notifyListeners();
    }
  }

  // Mark review as helpful
  Future<void> markReviewAsHelpful(String reviewId) async {
    try {
      await ReviewService.markReviewAsHelpful(reviewId);

      // Update local review
      final index = _reviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        _reviews[index] = _reviews[index].copyWith(
          helpfulCount: _reviews[index].helpfulCount + 1,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark review as helpful: $e';
      notifyListeners();
    }
  }

  // Unmark review as helpful
  Future<void> unmarkReviewAsHelpful(String reviewId) async {
    try {
      await ReviewService.unmarkReviewAsHelpful(reviewId);

      // Update local review
      final index = _reviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        _reviews[index] = _reviews[index].copyWith(
          helpfulCount: (_reviews[index].helpfulCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to unmark review as helpful: $e';
      notifyListeners();
    }
  }

  // Check if user has already reviewed a product
  Future<bool> hasUserReviewedProduct(String userId, String productId) async {
    try {
      return await ReviewService.hasUserReviewedProduct(userId, productId);
    } catch (e) {
      _error = 'Failed to check review status: $e';
      notifyListeners();
      return false;
    }
  }

  // Get user's existing review for a product
  Future<ReviewModel?> getUserProductReview(
      String userId, String productId) async {
    try {
      return await ReviewService.getUserProductReview(userId, productId);
    } catch (e) {
      _error = 'Failed to get user review: $e';
      notifyListeners();
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data (for logout or product change)
  void clearData() {
    _reviews.clear();
    _reviewStats.clear();
    _error = null;
    _currentProductId = '';
    _currentUserId = '';
    notifyListeners();
  }

  // Refresh reviews
  Future<void> refreshReviews() async {
    if (_currentProductId.isNotEmpty) {
      await loadProductReviews(_currentProductId);
    } else if (_currentUserId.isNotEmpty) {
      await loadUserReviews(_currentUserId);
    }
  }
}
