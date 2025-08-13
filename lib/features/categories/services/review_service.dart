import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/review_model.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'reviews';

  // Get reviews for a specific product
  static Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get product reviews: $e');
    }
  }

  // Get reviews by user
  static Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reviews: $e');
    }
  }

  // Get reviews by rating
  static Future<List<ReviewModel>> getReviewsByRating(
      String productId, double rating) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .where('rating', isEqualTo: rating)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reviews by rating: $e');
    }
  }

  // Get verified purchase reviews
  static Future<List<ReviewModel>> getVerifiedPurchaseReviews(
      String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .where('isVerifiedPurchase', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get verified purchase reviews: $e');
    }
  }

  // Create a new review
  static Future<String> createReview(ReviewModel review) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(review.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  // Update an existing review
  static Future<void> updateReview(
      String reviewId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(reviewId).update(data);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review (soft delete by setting isActive to false)
  static Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Mark review as helpful
  static Future<void> markReviewAsHelpful(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'helpfulCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark review as helpful: $e');
    }
  }

  // Unmark review as helpful
  static Future<void> unmarkReviewAsHelpful(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).update({
        'helpfulCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unmark review as helpful: $e');
    }
  }

  // Get review statistics for a product
  static Future<Map<String, dynamic>> getProductReviewStats(
      String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .where('isActive', isEqualTo: true)
          .get();

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();

      if (reviews.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          'verifiedPurchases': 0,
        };
      }

      final totalReviews = reviews.length;
      final averageRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews;

      final ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final review in reviews) {
        final rating = review.rating.round();
        if (rating >= 1 && rating <= 5) {
          ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
        }
      }

      final verifiedPurchases =
          reviews.where((r) => r.isVerifiedPurchase).length;

      return {
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
        'verifiedPurchases': verifiedPurchases,
      };
    } catch (e) {
      throw Exception('Failed to get review statistics: $e');
    }
  }

  // Check if user has already reviewed a product
  static Future<bool> hasUserReviewedProduct(
      String userId, String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if user has reviewed product: $e');
    }
  }

  // Get user's existing review for a product
  static Future<ReviewModel?> getUserProductReview(
      String userId, String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ReviewModel.fromFirestore(
            snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user product review: $e');
    }
  }
}
