import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ReviewSummaryWidget extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool showCount;
  final bool showStars;
  final double starSize;
  final TextStyle? ratingStyle;
  final TextStyle? countStyle;

  const ReviewSummaryWidget({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.showCount = true,
    this.showStars = true,
    this.starSize = 16,
    this.ratingStyle,
    this.countStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showStars) ...[
          // Star rating
          Row(
            children: List.generate(5, (index) {
              if (index < rating.floor()) {
                return Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: starSize,
                );
              } else if (index == rating.floor() && rating % 1 >= 0.5) {
                return Icon(
                  Icons.star_half,
                  color: Colors.amber,
                  size: starSize,
                );
              } else {
                return Icon(
                  Icons.star_border,
                  color: Colors.grey[400],
                  size: starSize,
                );
              }
            }),
          ),
          const SizedBox(width: 4),
        ],

        // Rating number
        Text(
          rating.toStringAsFixed(1),
          style: ratingStyle ??
              TextStyle(
                fontSize: starSize * 0.75,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkColor,
              ),
        ),

        // Review count
        if (showCount && reviewCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: countStyle ??
                TextStyle(
                  fontSize: starSize * 0.6,
                  color: Colors.grey[600],
                ),
          ),
        ],
      ],
    );
  }
}

// Compact version for small spaces
class CompactReviewSummaryWidget extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const CompactReviewSummaryWidget({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: 14,
        ),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkColor,
          ),
        ),
        if (reviewCount > 0) ...[
          const SizedBox(width: 2),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
