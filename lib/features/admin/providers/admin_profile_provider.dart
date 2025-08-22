import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/image_service.dart';
import 'dart:io';

class AdminProfileProvider extends ChangeNotifier {
  final ImageService _imageService = ImageService();

  UserModel? _adminProfile;
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;
  bool _isUpdating = false;

  // Getters
  UserModel? get adminProfile => _adminProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedImage => _selectedImage;
  bool get isUpdating => _isUpdating;
  bool get isProfileReady => _adminProfile != null && !_isLoading;

  AdminProfileProvider() {
    // Delay loading to ensure Firebase Auth is initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadAdminProfile();
    });
  }

  // Load admin profile data
  Future<void> _loadAdminProfile() async {
    _setLoading(true);
    _clearError();

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        final userData = await AuthService.getUserData(currentUser.uid);
        if (userData != null && userData.userType == 'admin') {
          _adminProfile = userData;
        } else {
          _setError('User is not an admin');
        }
      } else {
        _setError('No user logged in');
      }
    } catch (e) {
      _setError('Failed to load admin profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh admin profile
  Future<void> refreshProfile() async {
    await _loadAdminProfile();
  }

  // Update admin profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    List<String>? farmTypes,
    String? bio,
    String? location,
    String? companyName,
    String? website,
    String? socialMedia,
    String? department,
    String? role,
  }) async {
    if (_adminProfile == null) return false;

    _setUpdating(true);
    _clearError();

    try {
      // Prepare update data
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (farmTypes != null) updateData['farmTypes'] = farmTypes;
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;
      if (companyName != null) updateData['companyName'] = companyName;
      if (website != null) updateData['website'] = website;
      if (socialMedia != null) updateData['socialMedia'] = socialMedia;
      if (department != null) updateData['department'] = department;
      if (role != null) updateData['role'] = role;

      // Update profile image if selected
      if (_selectedImage != null) {
        final fileName = _imageService
            .generateFileName(_selectedImage!.path.split('/').last);
        final imageUrl = await _imageService.uploadImage(
            _selectedImage!, 'admin_profiles', fileName);
        updateData['profileImage'] = imageUrl;

        // Delete old image if exists
        if (_adminProfile!.profileImage != null &&
            _adminProfile!.profileImage!.isNotEmpty) {
          try {
            await _imageService.deleteImage(_adminProfile!.profileImage!);
          } catch (e) {
            print('Warning: Failed to delete old profile image: $e');
          }
        }
      }

      // Update in Firestore
      await AuthService.updateUserProfile(_adminProfile!.id, updateData);

      // Update local profile
      _adminProfile = _adminProfile!.copyWith(
        name: name ?? _adminProfile!.name,
        email: email ?? _adminProfile!.email,
        phone: phone ?? _adminProfile!.phone,
        farmTypes: farmTypes ?? _adminProfile!.farmTypes,
        bio: bio ?? _adminProfile!.bio,
        location: location ?? _adminProfile!.location,
        companyName: companyName ?? _adminProfile!.companyName,
        website: website ?? _adminProfile!.website,
        socialMedia: socialMedia ?? _adminProfile!.socialMedia,
        department: department ?? _adminProfile!.department,
        role: role ?? _adminProfile!.role,
        profileImage: updateData['profileImage'] ?? _adminProfile!.profileImage,
        updatedAt: DateTime.now(),
      );

      // Clear selected image
      _selectedImage = null;

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Change password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    _setUpdating(true);
    _clearError();

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        // Re-authenticate user before changing password
        final credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: currentPassword,
        );
        await currentUser.reauthenticateWithCredential(credential);

        // Change password
        await currentUser.updatePassword(newPassword);

        return true;
      } else {
        _setError('No user logged in');
        return false;
      }
    } catch (e) {
      _setError('Failed to change password: $e');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Update email
  Future<bool> updateEmail(String newEmail, String password) async {
    _setUpdating(true);
    _clearError();

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        // Re-authenticate user before changing email
        final credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: password,
        );
        await currentUser.reauthenticateWithCredential(credential);

        // Update email - use the correct method
        await currentUser.verifyBeforeUpdateEmail(newEmail);

        // Update in Firestore
        await AuthService.updateUserProfile(_adminProfile!.id, {
          'email': newEmail,
          'updatedAt': DateTime.now(),
        });

        // Update local profile
        _adminProfile = _adminProfile!.copyWith(
          email: newEmail,
          updatedAt: DateTime.now(),
        );

        notifyListeners();
        return true;
      } else {
        _setError('No user logged in');
        return false;
      }
    } catch (e) {
      _setError('Failed to update email: $e');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Select profile image
  void selectImage(File image) {
    _selectedImage = image;
    notifyListeners();
  }

  // Remove selected image
  void removeSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // Get profile statistics
  Map<String, dynamic> getProfileStats() {
    if (_adminProfile == null) return {};

    return {
      'totalProducts': 0, // This would come from product provider
      'totalOrders': 0, // This would come from order provider
      'totalUsers': 0, // This would come from user provider
      'memberSince': _adminProfile!.createdAt,
      'lastActive': _adminProfile!.updatedAt,
    };
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUpdating(bool updating) {
    _isUpdating = updating;
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
