import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final String authMethod; // 'password', 'google', 'facebook'

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.authMethod,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
        'authMethod': authMethod,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        photoUrl: json['photoUrl'],
        createdAt: DateTime.parse(json['createdAt']),
        authMethod: json['authMethod'],
      );
}

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Check if this is first launch
  Future<bool> isFirstLaunch() async {
    final hasUser = await hasUserProfile();
    return !hasUser;
  }

  // Check if user profile exists
  Future<bool> hasUserProfile() async {
    final userJson = _prefs?.getString('user_profile');
    return userJson != null && userJson.isNotEmpty;
  }

  // Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs?.setString('user_profile', jsonEncode(profile.toJson()));
  }

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    final userJson = _prefs?.getString('user_profile');
    if (userJson == null || userJson.isEmpty) return null;
    return UserProfile.fromJson(jsonDecode(userJson));
  }

  // Save password (hashed)
  Future<void> savePassword(String email, String password) async {
    // In production, use proper hashing like bcrypt
    await _secureStorage.write(key: 'password_$email', value: password);
  }

  // Verify password
  Future<bool> verifyPassword(String email, String password) async {
    final savedPassword = await _secureStorage.read(key: 'password_$email');
    return savedPassword == password;
  }

  // Delete user profile
  Future<void> deleteUserProfile() async {
    final profile = await getUserProfile();
    if (profile != null) {
      await _secureStorage.delete(key: 'password_${profile.email}');
    }
    await _prefs?.remove('user_profile');
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    final profile = await getUserProfile();
    if (profile == null) return;

    final updatedProfile = UserProfile(
      id: profile.id,
      name: name ?? profile.name,
      email: email ?? profile.email,
      photoUrl: photoUrl ?? profile.photoUrl,
      createdAt: profile.createdAt,
      authMethod: profile.authMethod,
    );

    await saveUserProfile(updatedProfile);
  }
}
