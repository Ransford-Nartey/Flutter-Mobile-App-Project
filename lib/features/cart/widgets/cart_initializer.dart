import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartInitializer extends StatefulWidget {
  final Widget child;

  const CartInitializer({
    super.key,
    required this.child,
  });

  @override
  State<CartInitializer> createState() => _CartInitializerState();
}

class _CartInitializerState extends State<CartInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.initializeCartStream();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return widget.child;
  }
}
