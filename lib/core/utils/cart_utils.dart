import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../features/cart/providers/cart_provider.dart';

class CartUtils {
  /// Shows a dialog when an item is already in the cart
  /// Returns true if the user wants to add more, false otherwise
  static Future<bool> showItemAlreadyInCartDialog(
    BuildContext context,
    String productId,
    String productName,
    int currentQuantity,
    int newQuantity,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Item Already in Cart'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$productName is already in your cart.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current quantity: $currentQuantity kg',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'What would you like to do?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, false);
              Navigator.pushNamed(context, '/cart');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
            ),
            child: const Text('View Cart'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add More'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Checks if an item is in the cart and shows appropriate dialog
  /// Returns true if item was added/updated, false otherwise
  static Future<bool> addToCartWithCheck(
    BuildContext context,
    String productId,
    String productName,
    String category,
    double price,
    String image,
    int quantity,
  ) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Check if item is already in cart
    if (cartProvider.isInCart(productId)) {
      final currentQuantity = cartProvider.getItemQuantity(productId);
      
      // Show dialog asking user what to do
      final shouldAddMore = await showItemAlreadyInCartDialog(
        context,
        productId,
        productName,
        currentQuantity,
        quantity,
      );
      
      if (shouldAddMore) {
        // Update quantity by adding the selected quantity
        cartProvider.updateQuantity(productId, currentQuantity + quantity);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cart updated: $productName quantity increased to ${currentQuantity + quantity} kg',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return true;
      } else {
        return false;
      }
    } else {
      // Add new item to cart
      cartProvider.addItem(
        productId: productId,
        name: productName,
        category: category,
        price: price,
        image: image,
        quantity: quantity,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${quantity}x $productName added to cart'),
          duration: const Duration(seconds: 2),
        ),
      );
      return true;
    }
  }

  /// Gets the appropriate button text and icon for add to cart button
  static Map<String, dynamic> getAddToCartButtonState(
    BuildContext context,
    String productId,
  ) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isInCart = cartProvider.isInCart(productId);
    
    return {
      'text': isInCart ? 'Item in Cart' : 'Add to Cart',
      'icon': isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
      'backgroundColor': isInCart ? Colors.orange : AppTheme.primaryColor,
      'isInCart': isInCart,
    };
  }
}
