import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isGoogleAuth;
  final DateTime joinedDate;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isGoogleAuth,
    required this.joinedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'isGoogleAuth': isGoogleAuth,
        'joinedDate': joinedDate.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? 'guest',
        name: json['name'] ?? 'Player',
        email: json['email'] ?? 'guest@arrowpuzzle.com',
        avatarUrl: json['avatarUrl'] ?? '',
        isGoogleAuth: json['isGoogleAuth'] ?? false,
        joinedDate: json['joinedDate'] != null
            ? DateTime.parse(json['joinedDate'])
            : DateTime.now(),
      );
}

class AuthService {
  static const String _keyUser = 'arrow_puzzle_user_profile';
  UserProfile? currentUser;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyUser);
      if (raw != null) {
        currentUser = UserProfile.fromJson(jsonDecode(raw));
      }
    } catch (e) {
      // Fallback
    }
  }

  Future<void> signInWithGoogle({String? customEmail, String? customName}) async {
    final name = customName ?? 'Shahrukh Ahmad';
    final email = customEmail ?? 'srkamd@gmail.com';
    currentUser = UserProfile(
      id: 'usr_g_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      avatarUrl: 'https://github.com/srkamd.png',
      isGoogleAuth: true,
      joinedDate: DateTime.now(),
    );
    await _save();
  }

  Future<void> signInWithEmail(String email, String name) async {
    currentUser = UserProfile(
      id: 'usr_e_${DateTime.now().millisecondsSinceEpoch}',
      name: name.isNotEmpty ? name : email.split('@').first,
      email: email,
      avatarUrl: '',
      isGoogleAuth: false,
      joinedDate: DateTime.now(),
    );
    await _save();
  }

  Future<void> signOut() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  Future<void> _save() async {
    if (currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(currentUser!.toJson()));
    } catch (e) {
      // Ignore
    }
  }
}
