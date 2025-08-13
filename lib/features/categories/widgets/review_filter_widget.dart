import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ReviewFilterWidget extends StatelessWidget {
  final Function(String, double?) onFilterChanged;
  final VoidCallback onClearFilters;
  final String currentFilter;
  final double? currentRating;

  const ReviewFilterWidget({
    super.key,
    required this.onFilterChanged,
    required this.onClearFilters,
    required this.currentFilter,
    this.currentRating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filter Reviews',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkColor,
                  ),
                ),
                const Spacer(),
                if (currentFilter != 'all' || currentRating != null)
                  TextButton(
                    onPressed: onClearFilters,
                    child: Text(
                      'Clear',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Filter type buttons
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(
                  label: 'All',
                  value: 'all',
                  isSelected: currentFilter == 'all',
                  onTap: () => onFilterChanged('all', null),
                ),
                _buildFilterChip(
                  label: 'Verified',
                  value: 'verified',
                  isSelected: currentFilter == 'verified',
                  onTap: () => onFilterChanged('verified', null),
                ),
                _buildFilterChip(
                  label: '5 Stars',
                  value: 'rating',
                  isSelected: currentFilter == 'rating' && currentRating == 5,
                  onTap: () => onFilterChanged('rating', 5),
                ),
                _buildFilterChip(
                  label: '4 Stars',
                  value: 'rating',
                  isSelected: currentFilter == 'rating' && currentRating == 4,
                  onTap: () => onFilterChanged('rating', 4),
                ),
                _buildFilterChip(
                  label: '3 Stars',
                  value: 'rating',
                  isSelected: currentFilter == 'rating' && currentRating == 3,
                  onTap: () => onFilterChanged('rating', 3),
                ),
                _buildFilterChip(
                  label: '2 Stars',
                  value: 'rating',
                  isSelected: currentFilter == 'rating' && currentRating == 2,
                  onTap: () => onFilterChanged('rating', 2),
                ),
                _buildFilterChip(
                  label: '1 Star',
                  value: 'rating',
                  isSelected: currentFilter == 'rating' && currentRating == 1,
                  onTap: () => onFilterChanged('rating', 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor 
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected 
                ? Colors.white
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
