import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api/app_user.dart';

/// Persists the customer session in Keychain / Android EncryptedSharedPreferences.
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
  static const _accessExpiresAtKey = 'mrbob_access_expires_at';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? accessToken;
  String? refreshToken;
  DateTime? accessTokenExpiresAt;
  AppUser? user;
  bool _initialized = false;

  bool get hasSession => accessToken != null;

  /// Restores the persisted session. Called once from `main()`.
  Future<void> init() async {
    _initialized = true;
    accessToken = await _storage.read(key: _accessKey);
    refreshToken = await _storage.read(key: _refreshKey);
    final expiry = await _storage.read(key: _accessExpiresAtKey);
    accessTokenExpiresAt = expiry == null ? null : DateTime.tryParse(expiry);
    var userJson = await _storage.read(key: _userKey);
    // One-time migration keeps existing customer sessions usable while moving
    // their credentials out of plain preferences.
    if (accessToken == null && refreshToken == null) {
      final legacy = await SharedPreferences.getInstance();
      accessToken = legacy.getString(_accessKey);
      refreshToken = legacy.getString(_refreshKey);
      userJson = legacy.getString(_userKey);
      if (accessToken != null && refreshToken != null) {
        await _storage.write(key: _accessKey, value: accessToken);
        await _storage.write(key: _refreshKey, value: refreshToken);
        if (userJson != null) {
          await _storage.write(key: _userKey, value: userJson);
        }
        await legacy.remove(_accessKey);
        await legacy.remove(_refreshKey);
        await legacy.remove(_userKey);
      }
    }
    if (userJson != null) {
      try {
        user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        // Corrupted cache — treat as signed out.
        await clear();
      }
    }
  }

  Future<void> save(
    String access,
    String refresh, {
    required DateTime accessExpiresAt,
    AppUser? user,
  }) async {
    accessToken = access;
    refreshToken = refresh;
    accessTokenExpiresAt = accessExpiresAt;
    if (user != null) {
      this.user = user;
    }
    if (!_initialized) return;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    await _storage.write(
      key: _accessExpiresAtKey,
      value: accessExpiresAt.toUtc().toIso8601String(),
    );
    if (this.user != null) {
      await _storage.write(
        key: _userKey,
        value: jsonEncode(this.user!.toJson()),
      );
    }
  }

  Future<void> updateUser(AppUser newUser) async {
    user = newUser;
    if (!_initialized) return;
    await _storage.write(key: _userKey, value: jsonEncode(newUser.toJson()));
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    accessTokenExpiresAt = null;
    user = null;
    if (!_initialized) return;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _accessExpiresAtKey);
    await _storage.delete(key: _userKey);
  }
}
