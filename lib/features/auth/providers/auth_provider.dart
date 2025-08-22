import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../../../core/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Listen to auth state changes
    AuthService.authStateChanges.listen((User? user) {
      _user = user;
      print('AuthProvider: Auth state changed - User: ${user?.uid}');
      notifyListeners();
    });
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('AuthProvider: Attempting sign in for email: $email');
      await AuthService.signInWithEmailAndPassword(email, password);

      // Get the current user after sign in
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        print('AuthProvider: Sign in successful for user: ${currentUser.uid}');
        // Force a small delay to ensure Firebase is fully initialized
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _setLoading(false);
      return true;
    } catch (e) {
      print('AuthProvider: Sign in failed: $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign up
  Future<bool> signUp(
      String email, String password, String name, String phone) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.createUserWithEmailAndPassword(email, password);
      // Create user profile after successful signup
      final user = AuthService.currentUser;
      if (user != null) {
        final userModel = UserModel(
          id: user.uid,
          name: name,
          email: email,
          phone: phone,
          userType: 'customer',
          farmTypes: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await AuthService.createUserProfile(user.uid, userModel);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await AuthService.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({String? displayName}) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔍 AuthProvider: Starting profile update...');
      print('🔍 AuthProvider: Display name: $displayName');
      
      // Update Firebase Auth profile
      final user = AuthService.currentUser;
      if (user != null) {
        print('🔍 AuthProvider: Current user: ${user.uid}');
        
        if (displayName != null) {
          print('🔍 AuthProvider: Updating display name to: $displayName');
          await user.updateDisplayName(displayName);
          print('🔍 AuthProvider: Display name updated successfully');
        }
        
        print('🔍 AuthProvider: Profile update completed successfully');
      } else {
        print('❌ AuthProvider: No current user found');
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ AuthProvider: Error updating profile: $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔍 AuthProvider: Starting password change...');
      
      final user = AuthService.currentUser;
      if (user != null) {
        print('🔍 AuthProvider: Current user: ${user.uid}');
        
        // Re-authenticate user before changing password
        print('🔍 AuthProvider: Re-authenticating user...');
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        print('🔍 AuthProvider: User re-authenticated successfully');
        
        // Change password
        print('🔍 AuthProvider: Changing password...');
        await user.updatePassword(newPassword);
        print('🔍 AuthProvider: Password changed successfully');
        
        return true;
      } else {
        print('❌ AuthProvider: No current user found');
        return false;
      }
    } catch (e) {
      print('❌ AuthProvider: Error changing password: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
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

  // Clear error manually (useful for UI)
  void clearError() {
    _clearError();
  }
}
