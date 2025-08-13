import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/models/user_model.dart';

class AdminProvider extends ChangeNotifier {
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _error;
  UserModel? _adminUser;

  // Getters
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get adminUser => _adminUser;

  AdminProvider() {
    _checkAdminStatus();
  }

  // Check if current user is admin
  Future<void> _checkAdminStatus() async {
    _setLoading(true);

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        final userData = await AuthService.getUserData(currentUser.uid);
        if (userData != null && userData.userType == 'admin') {
          _isAdmin = true;
          _adminUser = userData;
        } else {
          _isAdmin = false;
          _adminUser = null;
        }
      } else {
        _isAdmin = false;
        _adminUser = null;
      }
    } catch (e) {
      _setError('Failed to check admin status: $e');
      _isAdmin = false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh admin status
  Future<void> refreshAdminStatus() async {
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
