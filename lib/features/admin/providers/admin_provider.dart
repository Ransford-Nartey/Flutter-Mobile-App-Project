import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/models/user_model.dart';

class AdminProvider extends ChangeNotifier {
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _error;
  UserModel? _adminUser;
  bool _isInitialized = false;

  // Getters
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get adminUser => _adminUser;
  bool get isInitialized => _isInitialized;

  AdminProvider() {
    print('AdminProvider: Initializing...');
    _initializeProvider();
  }

  // Singleton instance
  static AdminProvider? _instance;
  static AdminProvider get instance {
    _instance ??= AdminProvider();
    return _instance!;
  }

  // Initialize the provider
  void _initializeProvider() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      print('AdminProvider: Already initialized, skipping...');
      return;
    }

    try {
      // Listen to auth state changes to update admin status
      AuthService.authStateChanges.listen((User? user) {
        print('AdminProvider: Auth state changed - User: ${user?.uid}');
        if (user != null) {
          // User is signed in, check admin status
          _checkAdminStatus();
        } else {
          // User is signed out, reset admin status
          _resetAdminStatus();
        }
      });

      // Also check admin status immediately if user is already signed in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentUser = AuthService.currentUser;
        print(
            'AdminProvider: Post frame callback - Current user: ${currentUser?.uid}');
        if (currentUser != null && !_isAdmin) {
          // Only check if we haven't already determined admin status
          _checkAdminStatus();
        }
        _isInitialized = true;
        notifyListeners();
      });
    } catch (e) {
      print('AdminProvider: Error during initialization: $e');
      _setError('Failed to initialize admin provider: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Reset admin status when user signs out
  void _resetAdminStatus() {
    print('AdminProvider: Resetting admin status');
    _isAdmin = false;
    _adminUser = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Check if current user is admin with timeout
  Future<void> _checkAdminStatus() async {
    // Skip if already determined and user is admin
    if (_isAdmin && _adminUser != null) {
      print('AdminProvider: Admin status already determined, skipping check');
      return;
    }

    print('AdminProvider: Checking admin status...');
    _setLoading(true);
    _clearError();

    try {
      // Add timeout to prevent getting stuck
      final result = await _checkAdminStatusWithTimeout();
      if (result != null) {
        _isAdmin = result;
      }
    } catch (e) {
      print('AdminProvider: Error checking admin status: $e');
      _setError('Failed to check admin status: $e');
      _isAdmin = false;
    } finally {
      print('AdminProvider: Admin check complete. Is admin: $_isAdmin');
      _setLoading(false);
    }
  }

  // Check admin status with timeout
  Future<bool?> _checkAdminStatusWithTimeout() async {
    try {
      return await Future.any([
        _performAdminCheck(),
        Future.delayed(const Duration(seconds: 10), () {
          print('AdminProvider: Admin check timed out');
          throw Exception('Admin check timed out');
        }),
      ]);
    } catch (e) {
      if (e.toString().contains('timed out')) {
        print('AdminProvider: Admin check timed out, retrying...');
        // Retry once after timeout
        try {
          return await _performAdminCheck();
        } catch (retryError) {
          print('AdminProvider: Retry failed: $retryError');
          return false;
        }
      }
      rethrow;
    }
  }

  // Perform the actual admin check
  Future<bool> _performAdminCheck() async {
    final currentUser = AuthService.currentUser;
    print('AdminProvider: Current user from service: ${currentUser?.uid}');

    if (currentUser != null) {
      final userData = await AuthService.getUserData(currentUser.uid);
      print('AdminProvider: User data retrieved: ${userData?.userType}');

      if (userData != null && userData.userType == 'admin') {
        print('AdminProvider: User is admin!');
        _adminUser = userData;
        return true;
      } else {
        print(
            'AdminProvider: User is not admin. User type: ${userData?.userType}');
        _adminUser = null;
        return false;
      }
    } else {
      print('AdminProvider: No current user found');
      _adminUser = null;
      return false;
    }
  }

  // Refresh admin status
  Future<void> refreshAdminStatus() async {
    print('AdminProvider: Manually refreshing admin status');
    await _checkAdminStatus();
  }

  // Check admin permission for specific action
  bool hasPermission(String action) {
    if (!_isAdmin || _adminUser == null) return false;

    // Add specific permission logic here based on admin roles
    switch (action) {
      case 'manage_products':
      case 'manage_categories':
      case 'manage_orders':
      case 'manage_users':
      case 'view_analytics':
        return true;
      default:
        return false;
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
