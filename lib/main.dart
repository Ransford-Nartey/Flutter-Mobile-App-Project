import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/widgets/auth_wrapper.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/cart/widgets/cart_initializer.dart';
import 'features/orders/orders.dart';
import 'features/categories/categories.dart';
import 'features/admin/admin.dart';
import 'features/admin/screens/user_management_screen.dart';
import 'features/admin/screens/admin_creation_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CycleFarmsApp());
}

class CycleFarmsApp extends StatelessWidget {
  const CycleFarmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ProductManagementProvider()),
        ChangeNotifierProvider(create: (_) => CategoryManagementProvider()),
        ChangeNotifierProvider(create: (_) => OrderManagementProvider()),
        ChangeNotifierProvider(create: (_) => UserManagementProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: CartInitializer(
        child: MaterialApp(
          title: 'Cycle Farms',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const AuthWrapper(),
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/checkout': (context) => const CheckoutScreen(),
            '/orders': (context) => const OrdersScreen(),
            '/categories': (context) => const CategoryListScreen(),
            '/admin': (context) => const AdminDashboardScreen(),
            '/admin/products': (context) => const ProductManagementScreen(),
            '/admin/categories': (context) => const CategoryManagementScreen(),
            '/admin/orders': (context) => const OrderManagementScreen(),
            '/admin/customers': (context) => const UserManagementScreen(),
            '/admin/create': (context) => const AdminCreationScreen(),
          },
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
