import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/review_model.dart';
import '../providers/review_provider.dart';
import '../../auth/services/auth_service.dart';
import 'review_card_widget.dart';
import 'review_filter_widget.dart';
import 'review_dialog.dart';

class ReviewListWidget extends StatefulWidget {
  final String productId;
  final bool showFilters;
  final bool showCreateButton;

  const ReviewListWidget({
    super.key,
    required this.productId,
    this.showFilters = true,
    this.showCreateButton = true,
  });

  @override
  State<ReviewListWidget> createState() => _ReviewListWidgetState();
}

class _ReviewListWidgetState extends State<ReviewListWidget> {
  @override
  void initState() {
    super.initState();
    // Load reviews when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      reviewProvider.loadProductReviews(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        if (reviewProvider.isLoading && reviewProvider.reviews.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reviewProvider.error != null && reviewProvider.reviews.isEmpty) {
          return _buildErrorWidget(reviewProvider);
        }

        final reviews = reviewProvider.filteredReviews;

        if (reviews.isEmpty) {
          return _buildEmptyState(reviewProvider);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with stats and filters
            _buildHeader(reviewProvider),

            // Filters
            if (widget.showFilters) ...[
              const SizedBox(height: 16),
              ReviewFilterWidget(
                onFilterChanged: (filterType, rating) {
                  reviewProvider.setFilterType(filterType, rating: rating);
                },
                onClearFilters: () {
                  reviewProvider.clearFilters();
                },
                currentFilter: reviewProvider.filterType,
                currentRating: reviewProvider.ratingFilter,
              ),
            ],

            const SizedBox(height: 16),

            // Reviews list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await reviewProvider.refreshReviews();
                },
                child: ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return ReviewCardWidget(
                      review: review,
                      onHelpfulToggled: () {
                        if (review.isHelpful) {
                          reviewProvider.unmarkReviewAsHelpful(review.id);
                        } else {
                          reviewProvider.markReviewAsHelpful(review.id);
                        }
                      },
                      onEdit: AuthService.isLoggedIn && AuthService.currentUserId == review.userId
                          ? () => _showEditReviewDialog(context, reviewProvider, review)
                          : null,
                      onDelete: AuthService.isLoggedIn && AuthService.currentUserId == review.userId
                          ? () => _showDeleteReviewDialog(context, reviewProvider, review)
                          : null,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ReviewProvider reviewProvider) {
    final stats = reviewProvider.reviewStats;
    final totalReviews = stats['totalReviews'] ?? 0;
    final averageRating = stats['averageRating'] ?? 0.0;
    final verifiedPurchases = stats['verifiedPurchases'] ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
                if (widget.showCreateButton && AuthService.isLoggedIn)
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showCreateReviewDialog(context, reviewProvider),
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Write Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  )
                else if (widget.showCreateButton && !AuthService.isLoggedIn)
                  ElevatedButton.icon(
                    onPressed: () => _showLoginPrompt(context),
                    icon: const Icon(Icons.login),
                    label: const Text('Login to Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            if (totalReviews > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // Average rating display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  if (index < averageRating.floor()) {
                                    return Icon(Icons.star,
                                        color: Colors.amber, size: 20);
                                  } else if (index == averageRating.floor() &&
                                      averageRating % 1 >= 0.5) {
                                    return Icon(Icons.star_half,
                                        color: Colors.amber, size: 20);
                                  } else {
                                    return Icon(Icons.star_border,
                                        color: Colors.grey, size: 20);
                                  }
                                }),
                              ),
                              Text(
                                'out of 5',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(width: 32),

                  // Review counts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalReviews reviews',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkColor,
                          ),
                        ),
                        if (verifiedPurchases > 0)
                          Text(
                            '$verifiedPurchases verified purchases',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ReviewProvider reviewProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading reviews',
            style: TextStyle(fontSize: 18, color: Colors.red[300]),
          ),
          const SizedBox(height: 8),
          Text(
            reviewProvider.error!,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              reviewProvider.loadProductReviews(widget.productId);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ReviewProvider reviewProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this product!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (widget.showCreateButton) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateReviewDialog(context, reviewProvider),
              icon: const Icon(Icons.rate_review),
              label: const Text('Write First Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCreateReviewDialog(
      BuildContext context, ReviewProvider reviewProvider) {
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        productId: widget.productId,
        onReviewSubmitted: (review) {
          reviewProvider.createReview(review);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditReviewDialog(
      BuildContext context, ReviewProvider reviewProvider, ReviewModel review) {
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        productId: widget.productId,
        existingReview: review,
        onReviewSubmitted: (updatedReview) {
          reviewProvider.updateReview(review.id, {
            'title': updatedReview.title,
            'comment': updatedReview.comment,
            'rating': updatedReview.rating,
            'images': updatedReview.images,
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDeleteReviewDialog(
      BuildContext context, ReviewProvider reviewProvider, ReviewModel review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text(
            'Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              reviewProvider.deleteReview(review.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
            'You need to be logged in to write reviews. Please sign in to your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to login screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please navigate to the login screen to sign in'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }
}
