import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cart_utils.dart';
import '../../cart/providers/cart_provider.dart';

import '../../categories/widgets/review_list_widget.dart';
import '../../categories/widgets/review_dialog.dart';
import '../../auth/services/auth_service.dart';
import '../../categories/providers/review_provider.dart';
import '../../categories/services/category_service.dart';
import '../../../core/models/category_model.dart';
import '../providers/customer_product_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  String? _categoryName;
  String? _subcategoryName;
  bool _isLoadingCategories = false;
  Map<String, String> _categoryNameMap = {};
  Map<String, String> _subcategoryNameMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCategoryNames();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh product data when dependencies change (e.g., when returning from review creation)
    _refreshProductData();
  }

  Future<void> _refreshProductData() async {
    try {
      final productProvider =
          Provider.of<CustomerProductProvider>(context, listen: false);
      await productProvider.loadProducts();
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> _loadCategoryNames() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      // Load all categories at once
      final allCategories = await CategoryService.getAllCategories();

      // Create lookup maps
      for (final category in allCategories) {
        _categoryNameMap[category.id] = category.name;

        // If this is a main category, also check its subcategories
        if (category.subcategoryIds.isNotEmpty) {
          for (final subId in category.subcategoryIds) {
            final subcategory = allCategories.firstWhere(
              (cat) => cat.id == subId,
              orElse: () => CategoryModel(
                id: subId,
                name: 'Unknown',
                description: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            _subcategoryNameMap[subId] = subcategory.name;
          }
        }
      }

      // Now resolve the category names for this product
      if (widget.product['category'] != null &&
          widget.product['category'].toString().isNotEmpty) {
        final categoryId = widget.product['category'].toString();
        _categoryName = _categoryNameMap[categoryId];

        if (widget.product['subcategory'] != null &&
            widget.product['subcategory'].toString().isNotEmpty) {
          final subcategoryId = widget.product['subcategory'].toString();
          _subcategoryName = _subcategoryNameMap[subcategoryId];
        }
      }
    } catch (e) {
      // Fallback: try to load categories individually
      await _loadCategoriesIndividually();
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadCategoriesIndividually() async {
    try {
      if (widget.product['category'] != null &&
          widget.product['category'].toString().isNotEmpty) {
        final categoryId = widget.product['category'].toString();

        final category = await CategoryService.getCategoryById(categoryId);
        if (category != null) {
          setState(() {
            _categoryName = category.name;
          });
        }

        if (widget.product['subcategory'] != null &&
            widget.product['subcategory'].toString().isNotEmpty) {
          final subcategoryId = widget.product['subcategory'].toString();

          final subcategory =
              await CategoryService.getCategoryById(subcategoryId);
          if (subcategory != null) {
            setState(() {
              _subcategoryName = subcategory.name;
            });
          }
        }
      }
    } catch (e) {
      // Silently handle errors in fallback method
    }
  }

  String _getDisplayCategoryName() {
    if (_categoryName != null && _categoryName!.isNotEmpty) {
      return _categoryName!;
    }

    // Fallback: show a shortened version of the ID if available
    if (widget.product['category'] != null &&
        widget.product['category'].toString().isNotEmpty) {
      final categoryId = widget.product['category'].toString();
      if (categoryId.length > 8) {
        return '${categoryId.substring(0, 8)}...';
      }
      return categoryId;
    }

    return '';
  }

  String _getDisplaySubcategoryName() {
    if (_subcategoryName != null && _subcategoryName!.isNotEmpty) {
      return _subcategoryName!;
    }

    // Fallback: show a shortened version of the ID if available
    if (widget.product['subcategory'] != null &&
        widget.product['subcategory'].toString().isNotEmpty) {
      final subcategoryId = widget.product['subcategory'].toString();
      if (subcategoryId.length > 8) {
        return '${subcategoryId.substring(0, 8)}...';
      }
      return subcategoryId;
    }

    return '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Image Gallery
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  // TODO: Add to favorites
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to favorites'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  // TODO: Share product
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing product...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),

          // Product Information
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product['name'] ?? 'Product Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (widget.product['rating'] ?? 0.0).toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Category, Subcategory, and Stock
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isLoadingCategories
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor),
                                ),
                              )
                            : Text(
                                _getDisplayCategoryName(),
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                      if (widget.product['subcategory'] != null &&
                          widget.product['subcategory']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isLoadingCategories
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.secondaryColor),
                                  ),
                                )
                              : Text(
                                  _getDisplaySubcategoryName(),
                                  style: TextStyle(
                                    color: AppTheme.secondaryColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.inventory,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.product['stockQuantity'] ?? 0} ${widget.product['unit'] ?? 'kg'} in stock',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Price
                  Row(
                    children: [
                      Text(
                        '₵${(widget.product['price'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.product['originalPrice'] != null)
                        Text(
                          '₵${widget.product['originalPrice'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Brand and Additional Info
                  if (widget.product['brand'] != null &&
                      widget.product['brand'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Brand: ${widget.product['brand']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (widget.product['countryOfOrigin'] != null &&
                            widget.product['countryOfOrigin']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.flag,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Origin: ${widget.product['countryOfOrigin']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),

                  // Quantity Selector
                  Row(
                    children: [
                      Text(
                        'Quantity:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              icon: const Icon(Icons.remove, size: 20),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                            Container(
                              width: 50,
                              alignment: Alignment.center,
                              child: Text(
                                _quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_quantity <
                                    (widget.product['stockQuantity'] ?? 0)) {
                                  setState(() => _quantity++);
                                }
                              },
                              icon: const Icon(Icons.add, size: 20),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<CartProvider>(
                          builder: (context, cart, child) {
                            final buttonState =
                                CartUtils.getAddToCartButtonState(
                                    context, widget.product['id'] ?? '');

                            return ElevatedButton.icon(
                              onPressed: () async {
                                await CartUtils.addToCartWithCheck(
                                  context,
                                  widget.product['id'] ?? '',
                                  widget.product['name'] ?? 'Product',
                                  _getDisplayCategoryName(),
                                  widget.product['price'] ?? 0.0,
                                  widget.product['image'] ?? '',
                                  _quantity,
                                );
                              },
                              icon: Icon(
                                buttonState['icon'],
                              ),
                              label: Text(
                                buttonState['text'],
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonState['backgroundColor'],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showReviewDialog(context),
                          icon: const Icon(Icons.rate_review),
                          label: const Text(
                            'Add Review',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Cart Summary with View Cart Button
                  Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      if (cart.itemCount == 0) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} in cart',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '₵${cart.totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showCartDetails(context),
                                icon: const Icon(Icons.visibility),
                                label: const Text('View Cart'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side:
                                      BorderSide(color: AppTheme.primaryColor),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: AppTheme.primaryColor,
                      tabs: const [
                        Tab(text: 'Description'),
                        Tab(text: 'Specifications'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverToBoxAdapter(
            child: SizedBox(
              height: 400, // Fixed height for tab content
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDescriptionTab(),
                  _buildSpecificationsTab(),
                  _buildReviewsTab(),
                ],
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    // Use real product images from the product data
    final List<String> images = widget.product['images'] != null
        ? List<String>.from(widget.product['images'])
        : [];

    // If no images available, use a placeholder
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey[400],
        ),
      );
    }

    return Stack(
      children: [
        // Main Image
        PageView.builder(
          onPageChanged: (index) {
            setState(() {
              _selectedImageIndex = index;
            });
          },
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                );
              },
            );
          },
        ),

        // Image Indicators
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedImageIndex == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),

        // Gradient Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.product['description'] ??
                'No description available for this product.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.darkColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recommended for: ${_getDisplayCategoryName()} farming operations, hatcheries, and commercial aquaculture facilities.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.darkColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          // Use real product specifications if available
          if (widget.product['specifications'] != null &&
              (widget.product['specifications'] as Map<String, dynamic>)
                  .isNotEmpty) ...[
            ...(widget.product['specifications'] as Map<String, dynamic>)
                .entries
                .map(
                  (entry) => _buildSpecificationItem(
                      entry.key, entry.value.toString()),
                ),
          ] else ...[
            // Show message when no specifications available
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No specifications available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Product specifications have not been added yet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSpecificationItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.darkColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        // Set callback to refresh product data when reviews change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          reviewProvider.setProductDataRefreshCallback(() async {
            // Refresh the product data to show updated rating and review count
            final productProvider =
                Provider.of<CustomerProductProvider>(context, listen: false);
            await productProvider.loadProducts();
            setState(() {});
          });
        });

        return ReviewListWidget(
          productId: widget.product['id'] ?? '',
          showCreateButton: true,
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      _showLoginPrompt(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        productId: widget.product['id'] ?? '',
        onReviewSubmitted: (review) {
          final reviewProvider =
              Provider.of<ReviewProvider>(context, listen: false);
          reviewProvider.createReview(review);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Review submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        },
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
                  content:
                      Text('Please navigate to the login screen to sign in'),
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

  void _showCartDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Consumer<CartProvider>(
          builder: (context, cart, child) {
            if (cart.itemCount == 0) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some products to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Continue Shopping'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Shopping Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cart Items
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items.values.toList()[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.image,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Product Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.category,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '₵${item.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Remove Button
                            IconButton(
                              onPressed: () {
                                cart.removeItem(item.productId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${item.name} removed from cart'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red[400],
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Cart Summary and Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Total
                      Row(
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₵${cart.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Continue Shopping'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: BorderSide(color: AppTheme.primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pushNamed(context, '/checkout');
                              },
                              child: const Text('Checkout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
