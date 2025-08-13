import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userImage;
  final double rating;
  final String title;
  final String comment;
  final List<String>? images;
  final bool isVerifiedPurchase;
  final bool isHelpful;
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.rating,
    required this.title,
    required this.comment,
    this.images,
    this.isVerifiedPurchase = false,
    this.isHelpful = false,
    this.helpfulCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Create from Firestore document
  factory ReviewModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userImage: data['userImage'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      title: data['title'] ?? '',
      comment: data['comment'] ?? '',
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
      isHelpful: data['isHelpful'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'isVerifiedPurchase': isVerifiedPurchase,
      'isHelpful': isHelpful,
      'helpfulCount': helpfulCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  // Create a copy with updated fields
  ReviewModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userImage,
    double? rating,
    String? title,
    String? comment,
    List<String>? images,
    bool? isVerifiedPurchase,
    bool? isHelpful,
    int? helpfulCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      isHelpful: isHelpful ?? this.isHelpful,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get formatted rating
  String get formattedRating {
    return rating.toStringAsFixed(1);
  }

  // Get star rating display
  String get starRating {
    final fullStars = rating.floor();
    final hasHalfStar = rating % 1 >= 0.5;

    String stars = '★' * fullStars;
    if (hasHalfStar) stars += '☆';
    stars += '☆' * (5 - fullStars - (hasHalfStar ? 1 : 0));

    return stars;
  }

  // Check if review has images
  bool get hasImages => images != null && images!.isNotEmpty;

  // Get time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Check if review is recent (within 7 days)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays <= 7;
  }

  @override
  String toString() {
    return 'ReviewModel(id: $id, productId: $productId, rating: $rating, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
