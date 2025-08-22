import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cart_utils.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/customer_product_provider.dart';
import '../../../core/models/product_model.dart';
import 'product_details_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;
  final String? categoryId;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    this.categoryId,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load products for this category when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = context.read<CustomerProductProvider>();
      await productProvider.loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final productProvider = context.read<CustomerProductProvider>();
              await productProvider.loadProducts();
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      // Navigate to cart tab
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      // You can add logic here to switch to cart tab if needed
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search in ${widget.categoryName}...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppTheme.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.categoryName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer<CustomerProductProvider>(
                  builder: (context, productProvider, child) {
                    final categoryProducts =
                        productProvider.products.where((product) {
                      bool matchesCategory = false;

                      if (widget.categoryId != null) {
                        matchesCategory = product.category == widget.categoryId;
                      }

                      if (!matchesCategory) {
                        matchesCategory = product.category.toLowerCase() ==
                            widget.categoryName.toLowerCase();
                      }

                      if (!matchesCategory) {
                        final providerCategory =
                            productProvider.categories.firstWhere(
                          (cat) =>
                              cat['id'] == product.category ||
                              cat['name'] == product.category,
                          orElse: () => <String, dynamic>{},
                        );
                        if (providerCategory.isNotEmpty) {
                          matchesCategory = providerCategory['name']
                                  ?.toString()
                                  .toLowerCase() ==
                              widget.categoryName.toLowerCase();
                        }
                      }

                      return matchesCategory;
                    }).toList();

                    return Text(
                      '${categoryProducts.length} products available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: Consumer<CustomerProductProvider>(
              builder: (context, productProvider, child) {
                // Show loading state if still loading or if data hasn't been initialized yet
                if (productProvider.isLoading ||
                    !productProvider.isInitialized) {
                  return _buildLoadingState();
                }

                if (productProvider.error != null) {
                  return _buildErrorState(productProvider);
                }

                // Filter products by category and search query
                final categoryProducts =
                    productProvider.products.where((product) {
                  // Check if product belongs to this category
                  bool matchesCategory = false;

                  if (widget.categoryId != null) {
                    // Try to match by category ID first
                    matchesCategory = product.category == widget.categoryId;
                  }

                  // If no match by ID, try to match by category name
                  if (!matchesCategory) {
                    matchesCategory = product.category.toLowerCase() ==
                        widget.categoryName.toLowerCase();
                  }

                  // Also check if the product category matches any category in the provider
                  if (!matchesCategory) {
                    final providerCategory =
                        productProvider.categories.firstWhere(
                      (cat) =>
                          cat['id'] == product.category ||
                          cat['name'] == product.category,
                      orElse: () => <String, dynamic>{},
                    );
                    if (providerCategory.isNotEmpty) {
                      matchesCategory =
                          providerCategory['name']?.toString().toLowerCase() ==
                              widget.categoryName.toLowerCase();
                    }
                  }

                  // Check if product matches search query
                  final matchesSearch = _searchQuery.isEmpty ||
                      product.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      (product.description
                              ?.toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ??
                          false);

                  return matchesCategory && matchesSearch;
                }).toList();

                // Debug information
                print('CategoryProductsScreen Debug:');
                print('  Category Name: ${widget.categoryName}');
                print('  Category ID: ${widget.categoryId}');
                print('  Total Products: ${productProvider.products.length}');
                print('  Filtered Products: ${categoryProducts.length}');
                print(
                    '  Available Categories: ${productProvider.categories.map((c) => '${c['id']}:${c['name']}').toList()}');

                // Only show empty state if we have products loaded but none match the category/search filters
                if (categoryProducts.isEmpty &&
                    productProvider.products.isNotEmpty) {
                  return _buildEmptyState();
                }

                return _buildProductsGrid(categoryProducts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading products...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please wait while we fetch products in ${widget.categoryName}',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CustomerProductProvider productProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 24),
          Text(
            'Error loading products',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            productProvider.error!,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              productProvider.loadProducts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off
                : Icons.category_outlined,
            size: 80,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No products found'
                : 'No products in this category',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Products will appear here once they are added to this category',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final productProvider = context.read<CustomerProductProvider>();
              await productProvider.loadProducts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Refresh Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          onTap: () {
            // Navigate to product details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                  product: product.toFirestore(),
                ),
              ),
            );
          },
          onAddToCart: () async {
            await CartUtils.addToCartWithCheck(
              context,
              product.id,
              product.name,
              widget.categoryName,
              product.price,
              product.mainImage ??
                  (product.images.isNotEmpty ? product.images.first : ''),
              1, // Default quantity for quick add
            );
          },
        );
      },
    );
  }
}

// Product Card Widget
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: (product.mainImage != null || product.images.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          product.mainImage ??
                              (product.images.isNotEmpty
                                  ? product.images.first
                                  : ''),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.inventory,
                                size: 40,
                                color: AppTheme.primaryColor.withOpacity(0.5),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.inventory,
                          size: 40,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
              ),
            ),

            // Product Info
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    const Spacer(),

                    // Price and Rating Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.formattedPrice,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Add to Cart Button
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        final buttonState = CartUtils.getAddToCartButtonState(context, product.id);
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: product.inStock ? onAddToCart : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: product.inStock
                                  ? buttonState['backgroundColor']
                                  : Colors.grey[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              product.inStock ? buttonState['text'] : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
