import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/product_model.dart';
import '../../../core/utils/cart_utils.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/review_list_widget.dart';
import '../widgets/review_summary_widget.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String? categoryId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.categoryId,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProductModel? _product;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load product details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadProductById(widget.productId);
    });
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
          Provider.of<ProductProvider>(context, listen: false);
      await productProvider.loadProductById(widget.productId);
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Specifications'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          // Show loading state while initially loading or if product is null and still loading
          if (productProvider.isLoading ||
              productProvider.currentProduct == null) {
            return _buildLoadingState();
          }

          if (productProvider.error != null) {
            return _buildErrorWidget(productProvider);
          }

          _product = productProvider.currentProduct;

          return Column(
            children: [
              // Product header with image and basic info
              _buildProductHeader(),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(),
                    _buildSpecificationsTab(),
                    _buildReviewsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductHeader() {
    if (_product == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          if (_product!.images.isNotEmpty)
            Center(
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _product!.mainImage ?? _product!.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image, size: 64, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Product name and rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _product!.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ReviewSummaryWidget(
                    rating: _product!.rating,
                    reviewCount: _product!.reviewCount,
                    starSize: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_product!.reviewCount} reviews',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Price and stock
          Row(
            children: [
              Text(
                _product!.formattedPrice,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/${_product!.unit}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _product!.inStock
                      ? AppTheme.successColor.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _product!.inStock ? AppTheme.successColor : Colors.red,
                  ),
                ),
                child: Text(
                  _product!.stockStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        _product!.inStock ? AppTheme.successColor : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    if (_product == null) return const SizedBox.shrink();

                    final buttonState = CartUtils.getAddToCartButtonState(
                        context, _product!.id);

                    return ElevatedButton.icon(
                      onPressed: _product!.inStock ? () => _addToCart() : null,
                      icon: Icon(buttonState['icon']),
                      label: Text(buttonState['text']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonState['backgroundColor'],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _addToWishlist(),
                icon: const Icon(Icons.favorite_border),
                label: const Text('Wishlist'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    if (_product == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          _buildSection(
            title: 'Description',
            icon: Icons.description,
            content: Text(
              _product!.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Product Information (only show fields that have data)
          _buildSection(
            title: 'Product Information',
            icon: Icons.info,
            content: Column(
              children: [
                if (_product!.brand.isNotEmpty)
                  _buildInfoRow('Brand', _product!.brand),
                if (_product!.countryOfOrigin != null &&
                    _product!.countryOfOrigin!.isNotEmpty)
                  _buildInfoRow(
                      'Country of Origin', _product!.countryOfOrigin!),
                _buildInfoRow('Stock Quantity',
                    '${_product!.stockQuantity} ${_product!.unit}'),
              ],
            ),
          ),

          // Category and Subcategory Badges
          if (_product!.category.isNotEmpty ||
              _product!.subcategory.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection(
              title: 'Categories',
              icon: Icons.category,
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_product!.category.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _product!.category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_product!.subcategory.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.deepOrange,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _product!.subcategory,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Tags (only show if tags exist)
          if (_product!.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection(
              title: 'Tags',
              icon: Icons.tag,
              content: Wrap(
                spacing: 8,
                children: _product!.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppTheme.primaryColor),
                        ))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    if (_product == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product specifications (only show if specifications exist)
          if (_product!.specifications.isNotEmpty) ...[
            _buildSection(
              title: 'Product Specifications',
              icon: Icons.list_alt,
              content: Column(
                children: _product!.specifications.entries
                    .map((entry) =>
                        _buildInfoRow(entry.key, entry.value.toString()))
                    .toList(),
              ),
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
          ],

          const SizedBox(height: 24),

          // Certifications (only show if certifications exist)
          if (_product!.certifications != null &&
              _product!.certifications!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection(
              title: 'Certifications',
              icon: Icons.verified,
              content: Column(
                children: _product!.certifications!
                    .map((cert) => Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: AppTheme.successColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              cert,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ],
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
                Provider.of<ProductProvider>(context, listen: false);
            await productProvider.loadProductById(widget.productId);
            setState(() {});
          });
        });

        return ReviewListWidget(
          productId: widget.productId,
          showCreateButton: true,
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ProductProvider productProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading product',
            style: TextStyle(fontSize: 18, color: Colors.red[300]),
          ),
          const SizedBox(height: 8),
          Text(
            productProvider.error!,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              productProvider.loadProductById(widget.productId);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading product details...',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.darkColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we fetch the product information',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Product not found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'The product you are looking for could not be found.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final productProvider =
                    Provider.of<ProductProvider>(context, listen: false);
                productProvider.loadProductById(widget.productId);
              },
              child: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart() async {
    if (_product != null) {
      await CartUtils.addToCartWithCheck(
        context,
        _product!.id,
        _product!.name,
        _product!.category,
        _product!.price,
        _product!.mainImage ??
            (_product!.images.isNotEmpty ? _product!.images.first : ''),
        1, // Default quantity
      );
    }
  }

  void _addToWishlist() {
    // TODO: Implement add to wishlist functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product!.name} added to wishlist'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
