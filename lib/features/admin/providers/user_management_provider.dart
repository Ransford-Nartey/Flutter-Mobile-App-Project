import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';

class UserManagementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedUserType = 'All';
  String _sortBy = 'createdAt';
  bool _sortAscending = false;

  // Getters
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedUserType => _selectedUserType;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Filtered and sorted users
  List<UserModel> get filteredUsers {
    List<UserModel> filtered = _users;

    // Filter by user type
    if (_selectedUserType != 'All') {
      filtered =
          filtered.where((user) => user.userType == _selectedUserType).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((user) =>
              user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.phone.contains(_searchQuery) ||
              (user.farmName
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    // Sort users
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'email':
          comparison = a.email.compareTo(b.email);
          break;
        case 'userType':
          comparison = a.userType.compareTo(b.userType);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // Load all users
  Future<void> loadUsers() async {
    _setLoading(true);
    _clearError();

    try {
      final querySnapshot = await _firestore.collection('users').get();
      _users = querySnapshot.docs.map((doc) {
        return UserModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      _setError('Failed to load users: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestore.collection('users').doc(userId).update(updates);

      // Update local user
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        final updatedUser = _users[index].copyWith(
          name: updates['name'] ?? _users[index].name,
          phone: updates['phone'] ?? _users[index].phone,
          farmName: updates['farmName'] ?? _users[index].farmName,
          farmLocation: updates['farmLocation'] ?? _users[index].farmLocation,
          farmSize: updates['farmSize'] ?? _users[index].farmSize,
          farmTypes: updates['farmTypes'] ?? _users[index].farmTypes,
          isActive: updates['isActive'] ?? _users[index].isActive,
          updatedAt: DateTime.now(),
        );
        _users[index] = updatedUser;
      }

      return true;
    } catch (e) {
      _setError('Failed to update user profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle user active status
  Future<bool> toggleUserStatus(String userId) async {
    try {
      final user = _users.firstWhere((u) => u.id == userId);
      final newStatus = !user.isActive;

      await _firestore.collection('users').doc(userId).update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          isActive: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to toggle user status: $e');
      return false;
    }
  }

  // Change user type
  Future<bool> changeUserType(String userId, String newUserType) async {
    _setLoading(true);
    _clearError();

    try {
      if (!['admin', 'customer'].contains(newUserType)) {
        _setError('Invalid user type');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'userType': newUserType,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          userType: newUserType,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to change user type: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete user (soft delete by deactivating)
  Future<bool> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to deactivate user: $e');
      return false;
    }
  }

  // Get user by ID
  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get user statistics
  Map<String, int> getUserStats() {
    final totalUsers = _users.length;
    final activeUsers = _users.where((u) => u.isActive).length;
    final adminUsers = _users.where((u) => u.userType == 'admin').length;
    final customerUsers = _users.where((u) => u.userType == 'customer').length;
    final deactivatedUsers = totalUsers - activeUsers;

    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'adminUsers': adminUsers,
      'customerUsers': customerUsers,
      'deactivatedUsers': deactivatedUsers,
    };
  }

  // Get recent users
  List<UserModel> getRecentUsers({int limit = 10}) {
    final sortedUsers = List<UserModel>.from(_users);
    sortedUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedUsers.take(limit).toList();
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setUserTypeFilter(String userType) {
    _selectedUserType = userType;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = true;
    }
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedUserType = 'All';
    _sortBy = 'createdAt';
    _sortAscending = false;
    notifyListeners();
  }

  // Get available user types for filter
  List<String> get availableUserTypes {
    final userTypes = _users.map((u) => u.userType).toSet().toList();
    userTypes.sort();
    return ['All', ...userTypes];
  }

  // Check if email exists
  bool emailExists(String email, {String? excludeId}) {
    return _users.any((user) =>
        user.email.toLowerCase() == email.toLowerCase() &&
        user.id != excludeId);
  }

  // Get users by farm type
  List<UserModel> getUsersByFarmType(String farmType) {
    return _users
        .where((user) => user.farmTypes.contains(farmType) && user.isActive)
        .toList();
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
}
