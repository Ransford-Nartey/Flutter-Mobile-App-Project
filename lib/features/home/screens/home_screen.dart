import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cart_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/widgets/cart_summary.dart';
import '../../../core/providers/notification_provider.dart';
import 'product_details_screen.dart';
import 'category_products_screen.dart';
import 'profile_edit_screen.dart';
import 'security_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../providers/customer_product_provider.dart';
import '../../../core/models/product_model.dart';
import '../../categories/services/category_service.dart';
import '../../../core/models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Consumer<CartProvider>(
              builder: (context, cart, child) {
                return Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
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
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const _DashboardTab();
      case 1:
        return const _CategoriesTab();
      case 2:
        return _CartTab();
      case 3:
        return const _OrdersTab();
      case 4:
        return const _ProfileTab();
      default:
        return const _DashboardTab();
    }
  }
}

// Dashboard Tab
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Preload all data when the tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = context.read<CustomerProductProvider>();
      try {
        // Use the preload method for better loading sequence
        await productProvider.preloadData();
      } catch (e) {
        print('Error initializing dashboard: $e');
      }
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
        title: const Text('Cycle Farms'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Notification Icon
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
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
                          '${notificationProvider.unreadCount}',
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
          const SizedBox(width: 8),
          // Cart Icon
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      // Navigate to cart screen
                      Navigator.pushNamed(context, '/cart');
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
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          return Column(
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Welcome Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.displayName ?? user?.email ?? 'User',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search and Filters Section
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          context
                              .read<CustomerProductProvider>()
                              .setSearchQuery(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for feed products...',
                          prefixIcon: Icon(Icons.search, color: AppTheme.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: AppTheme.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<CustomerProductProvider>()
                                        .setSearchQuery('');
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

                    // Selected Category Indicator
                    Consumer<CustomerProductProvider>(
                      builder: (context, productProvider, child) {
                        if (productProvider.selectedCategory == 'All') {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Browsing: ${productProvider.selectedCategory}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  productProvider.clearFilters();
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Categories Filter
                    Consumer<CustomerProductProvider>(
                      builder: (context, productProvider, child) {
                        final categories = productProvider.availableCategories;

                        return SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected =
                                  category == productProvider.selectedCategory;

                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < categories.length - 1 ? 12 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    productProvider.setCategoryFilter(category);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
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
                                      category,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.darkColor,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final filteredProducts = productProvider.filteredProducts;

                    print(
                        'Dashboard - Total products: ${productProvider.products.length}');
                    print(
                        'Dashboard - Filtered products: ${filteredProducts.length}');

                    // Only show empty state if we have products loaded but none match the filters
                    if (filteredProducts.isEmpty &&
                        productProvider.products.isNotEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildProductsGrid(filteredProducts);
                  },
                ),
              ),
            ],
          );
        },
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
            'Please wait while we fetch the latest products',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 24),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Try adjusting your search or category filter',
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

  Widget _buildProductsGrid(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8, // Adjusted aspect ratio to prevent overflow
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          onTap: () {
            // Get the category name from the provider
            final productProvider =
                Provider.of<CustomerProductProvider>(context, listen: false);
            final categoryData = productProvider.categories.firstWhere(
              (cat) =>
                  cat['id'] == product.category ||
                  cat['name'] == product.category,
              orElse: () => {'name': product.category},
            );
            final categoryName = categoryData['name'] ?? product.category;

            // Create a modified product map with the category name
            final productData =
                Map<String, dynamic>.from(product.toFirestore());
            productData['category'] = categoryName;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                  product: productData,
                ),
              ),
            );
          },
          onAddToCart: () async {
            // Get the category name from the provider
            final productProvider =
                Provider.of<CustomerProductProvider>(context, listen: false);
            final categoryData = productProvider.categories.firstWhere(
              (cat) =>
                  cat['id'] == product.category ||
                  cat['name'] == product.category,
              orElse: () => {'name': product.category},
            );
            final categoryName = categoryData['name'] ?? product.category;

            await CartUtils.addToCartWithCheck(
              context,
              product.id,
              product.name,
              categoryName,
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

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
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
              flex: 1, // 50% of the card (1 out of 2 total flex)
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
                        fontSize: 13, // Slightly smaller font
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2), // Reduced spacing

                    // Category - Hidden to avoid showing IDs
                    const SizedBox.shrink(),

                    const Spacer(),

                    // Price and Rating Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.formattedPrice,
                            style: TextStyle(
                              fontSize: 15, // Slightly smaller font
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 12, // Smaller icon
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                fontSize: 11, // Smaller font
                                color: AppTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6), // Reduced spacing

                    // Add to Cart Button
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        final buttonState = CartUtils.getAddToCartButtonState(context, product.id);
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 32, // Fixed height to prevent overflow
                          child: ElevatedButton(
                            onPressed: product.inStock ? onAddToCart : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: product.inStock
                                  ? buttonState['backgroundColor']
                                  : Colors.grey[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4), // Reduced padding
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(6), // Smaller radius
                              ),
                            ),
                            child: Text(
                              product.inStock ? buttonState['text'] : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 11, // Smaller font
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

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Categories Tab
class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab();

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  @override
  void initState() {
    super.initState();
    // Load categories when the tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = context.read<CustomerProductProvider>();
      await productProvider.loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final productProvider = context.read<CustomerProductProvider>();
              await productProvider.loadCategories();
              await productProvider.loadProducts();
            },
          ),
        ],
      ),
      body: Consumer<CustomerProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return _buildLoadingState();
          }

          if (productProvider.error != null) {
            return _buildErrorState(productProvider);
          }

          // Use categories from the provider
          final categories = productProvider.categories;

          if (categories.isEmpty) {
            return _buildEmptyState();
          }

          return _buildCategoriesGrid(categories, productProvider);
        },
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
            'Loading categories...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please wait while we fetch the latest categories',
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
            'Error loading categories',
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
              productProvider.loadCategories();
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
            Icons.category_outlined,
            size: 80,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 24),
          Text(
            'No categories available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Categories will appear here once they are added',
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

  Widget _buildCategoriesGrid(List<Map<String, dynamic>> categories,
      CustomerProductProvider productProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9, // Increased aspect ratio to prevent overflow
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          onTap: () {
            // Navigate to dedicated category products screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryProductsScreen(
                  categoryName: category['name'],
                  categoryId: category['id'],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Category Card Widget
class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(category['name'] ?? '');
    final productCount = _getProductCount(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Category Image
            Expanded(
              flex: 3, // Reduced flex to give more space to info
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: category['image'] != null &&
                        category['image'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          category['image'].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildCategoryIcon(categoryColor);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    categoryColor),
                              ),
                            );
                          },
                        ),
                      )
                    : _buildCategoryIcon(categoryColor),
              ),
            ),

            // Category Info
            Expanded(
              flex: 4, // Increased flex to use more space
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center, // Center content
                  children: [
                    // Category Name
                    Text(
                      category['name'] ?? 'Unknown Category',
                      style: const TextStyle(
                        fontSize: 14, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6), // Reduced spacing

                    // Product Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, // Reduced padding
                        vertical: 4, // Reduced padding
                      ),
                      decoration: BoxDecoration(
                        color: productCount > 0
                            ? categoryColor.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: productCount > 0
                              ? categoryColor.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        productCount > 0
                            ? '$productCount ${productCount == 1 ? 'product' : 'products'}'
                            : 'No products',
                        style: TextStyle(
                          fontSize: 10, // Reduced font size
                          fontWeight: FontWeight.w600,
                          color: productCount > 0 ? categoryColor : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6), // Reduced spacing

                    // Description - Only show if there's space
                    if (category['description'] != null &&
                        category['description'].toString().isNotEmpty)
                      Flexible(
                        child: Text(
                          category['description'].toString(),
                          style: TextStyle(
                            fontSize: 10, // Reduced font size
                            color: AppTheme.grey,
                            height: 1.1, // Reduced line height
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1, // Reduced to 1 line
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildCategoryIcon(Color categoryColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: categoryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.category,
          size: 48,
          color: categoryColor,
        ),
      ),
    );
  }

  int _getProductCount(Map<String, dynamic> category) {
    // Try to get product count from different possible fields
    if (category['productCount'] != null) {
      final count = category['productCount'];
      if (count is int) return count;
      if (count is String) return int.tryParse(count) ?? 0;
    }

    // If no product count, try to calculate from products list
    if (category['products'] != null && category['products'] is List) {
      return (category['products'] as List).length;
    }

    return 0;
  }

  Color _getCategoryColor(String categoryName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.pink,
      Colors.cyan,
      Colors.lime,
      Colors.deepPurple,
    ];

    final index = categoryName.hashCode % colors.length;
    return colors[index];
  }
}

// Cart Tab
class _CartTab extends StatefulWidget {
  const _CartTab();

  @override
  State<_CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<_CartTab> {
  String? _categoryName;
  String? _subcategoryName;
  bool _isLoadingCategories = false;
  Map<String, String> _categoryNameMap = {};
  Map<String, String> _subcategoryNameMap = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryNames();
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
    } catch (e) {
      // Silently handle errors
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  String _getDisplayCategoryName(String categoryId) {
    if (_categoryNameMap.containsKey(categoryId)) {
      return _categoryNameMap[categoryId]!;
    }

    // Fallback: show a shortened version of the ID if available
    if (categoryId.isNotEmpty) {
      if (categoryId.length > 8) {
        return 'Category ${categoryId.substring(0, 8)}...';
      }
      return 'Category $categoryId';
    }

    return 'Category';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.itemCount > 0) {
                return TextButton(
                  onPressed: () => _showClearCartDialog(context),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.itemCount == 0) {
            return _buildEmptyCart();
          }
          return _buildCartContent(context, cart);
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppTheme.grey,
          ),
          const SizedBox(height: 24),
          Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add products to your cart to get started',
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

  Widget _buildCartContent(BuildContext context, CartProvider cart) {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items.values.toList()[index];
              return _CartItemCard(
                item: item,
                getCategoryName: _getDisplayCategoryName,
              );
            },
          ),
        ),

        // Cart Summary and Checkout
        CartSummary(
          showCheckoutButton: true,
          onCheckoutPressed: () => Navigator.pushNamed(context, '/checkout'),
        ),
      ],
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to clear all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<CartProvider>(context, listen: false).clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// Cart Item Card Widget
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final String Function(String) getCategoryName;

  const _CartItemCard({
    required this.item,
    required this.getCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.image.isNotEmpty
                  ? Image.network(
                      item.image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.inventory,
                            size: 32,
                            color: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.inventory,
                        size: 32,
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 16),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  getCategoryName(item.category),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₵${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Column(
            children: [
              // Remove Button
              IconButton(
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false)
                      .removeItem(item.productId);
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),

              const SizedBox(height: 8),

              // Quantity Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false)
                          .decrementQuantity(item.productId);
                    },
                    icon: const Icon(Icons.remove, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      item.quantity.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false)
                          .incrementQuantity(item.productId);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Total Price
              Text(
                '₵${item.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Orders Tab
class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const OrdersScreen();
  }
}

// Profile Tab
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Profile Options
                _ProfileOption(
                  icon: Icons.home,
                  title: 'Home',
                  subtitle: 'Go to main dashboard',
                  onTap: () {
                    // Navigate to home tab by finding the HomeScreen and switching tabs
                    final homeScreen =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    if (homeScreen != null) {
                      homeScreen.setState(() {
                        homeScreen._currentIndex =
                            0; // Switch to home tab (index 0)
                      });
                    }
                  },
                ),
                _ProfileOption(
                  icon: Icons.shopping_bag,
                  title: 'My Orders',
                  subtitle: 'View and track your orders',
                  onTap: () {
                    // Navigate to orders tab by finding the HomeScreen and switching tabs
                    final homeScreen =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    if (homeScreen != null) {
                      homeScreen.setState(() {
                        homeScreen._currentIndex =
                            3; // Switch to orders tab (index 3)
                      });
                    }
                  },
                ),
                _ProfileOption(
                  icon: Icons.category,
                  title: 'Categories',
                  subtitle: 'Browse product categories',
                  onTap: () {
                    // Navigate to categories tab by finding the HomeScreen and switching tabs
                    final homeScreen =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    if (homeScreen != null) {
                      homeScreen.setState(() {
                        homeScreen._currentIndex =
                            1; // Switch to categories tab (index 1)
                      });
                    }
                  },
                ),
                _ProfileOption(
                  icon: Icons.shopping_cart,
                  title: 'Cart',
                  subtitle: 'View your shopping cart',
                  onTap: () {
                    // Navigate to cart tab by finding the HomeScreen and switching tabs
                    final homeScreen =
                        context.findAncestorStateOfType<_HomeScreenState>();
                    if (homeScreen != null) {
                      homeScreen.setState(() {
                        homeScreen._currentIndex =
                            2; // Switch to cart tab (index 2)
                      });
                    }
                  },
                ),
                _ProfileOption(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditScreen(),
                      ),
                    );
                  },
                ),

                _ProfileOption(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  onTap: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
                _ProfileOption(
                  icon: Icons.security,
                  title: 'Security',
                  subtitle: 'Change password and security settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecurityScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _ProfileOption(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  onTap: () => _showSignOutDialog(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// Profile Option Widget
class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.grey,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
