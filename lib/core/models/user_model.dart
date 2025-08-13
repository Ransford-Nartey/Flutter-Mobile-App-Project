import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String userType; // 'admin', 'customer'
  final String? farmName;
  final String? farmLocation;
  final String? farmSize;
  final List<String> farmTypes; // ['tilapia', 'catfish', 'hatchery']
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.userType,
    this.farmName,
    this.farmLocation,
    this.farmSize,
    required this.farmTypes,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.preferences,
  });

  // Create from Firebase Auth User
  factory UserModel.fromFirebaseUser(Map<String, dynamic> data, String uid) {
    return UserModel(
      id: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImage: data['profileImage'],
      userType: data['userType'] ?? 'customer',
      farmName: data['farmName'],
      farmLocation: data['farmLocation'],
      farmSize: data['farmSize'],
      farmTypes: List<String>.from(data['farmTypes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      preferences: data['preferences'],
    );
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      id: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImage: data['profileImage'],
      userType: data['userType'] ?? 'customer',
      farmName: data['farmName'],
      farmLocation: data['farmLocation'],
      farmSize: data['farmSize'],
      farmTypes: List<String>.from(data['farmTypes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      preferences: data['preferences'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'userType': userType,
      'farmName': farmName,
      'farmLocation': farmLocation,
      'farmSize': farmSize,
      'farmTypes': farmTypes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'preferences': preferences,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? userType,
    String? farmName,
    String? farmLocation,
    String? farmSize,
    List<String>? farmTypes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      farmName: farmName ?? this.farmName,
      farmLocation: farmLocation ?? this.farmLocation,
      farmSize: farmSize ?? this.farmSize,
      farmTypes: farmTypes ?? this.farmTypes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, userType: $userType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// User type constants
class UserTypes {
  static const String admin = 'admin';
  static const String customer = 'customer';

  static List<String> get allTypes => [admin, customer];

  static String getDisplayName(String userType) {
    switch (userType) {
      case admin:
        return 'Administrator';
      case customer:
        return 'Customer';
      default:
        return 'Unknown';
    }
  }

  static bool isValid(String userType) {
    return allTypes.contains(userType);
  }
}
