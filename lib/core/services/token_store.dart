import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/api/app_user.dart';

/// Persists the JWT pair + cached user profile across
/// app restarts.
///
/// Singleton (zero-package state, per the app's
/// conventions). [ApiClient] reads [accessToken] from
/// here on every request, so services never handle
/// headers themselves.
class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const _accessKey = 'mrbob_access_token';
  static const _refreshKey = 'mrbob_refresh_token';
  static const _userKey = 'mrbob_user_json';

  SharedPreferences? _prefs;

  String? accessToken;
  String? refreshToken;
  AppUser? user;

  bool get hasSession => accessToken != null;

  /// Restores the persisted session. Called once from `main()`.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    accessToken = _prefs!.getString(_accessKey);
    refreshToken = _prefs!.getString(_refreshKey);
    final userJson = _prefs!.getString(_userKey);
    if (userJson != null) {
      try {
        user = AppUser.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
      } catch (_) {
        // Corrupted cache — treat as signed out.
        await clear();
      }
    }
  }

  Future<void> save(String access, String refresh, {AppUser? user}) async {
    accessToken = access;
    refreshToken = refresh;
    if (user != null) {
      this.user = user;
    }
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    if (this.user != null) {
      await prefs.setString(_userKey, jsonEncode(this.user!.toJson()));
    }
  }

  Future<void> updateUser(AppUser newUser) async {
    user = newUser;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_userKey, jsonEncode(newUser.toJson()));
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    user = null;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }
}
