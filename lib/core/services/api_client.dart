import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Thin HTTP wrapper for the Home Services Platform API.
///
/// - Sends `Authorization: Bearer <token>` when a session exists.
/// - Unwraps the backend's `{ "success": bool, "data": ... }`
///   envelope and returns `data` directly. Paginated list endpoints
///   return top-level `items`/`meta`, so those envelopes are preserved.
/// - Throws [ApiException] with the backend's `message` on failure.
class ApiClient {
  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  static final ApiClient instance = ApiClient();

  final http.Client _http;
  Future<void>? _refreshInProgress;

  bool _requiresAuth(String path) =>
      path != '/auth/refresh' &&
      path != '/auth/logout' &&
      path != '/auth/login' &&
      path != '/auth/signup' &&
      !path.startsWith('/customer-onboarding/otp/');

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    dynamic body,
  }) async {
    if (_requiresAuth(path)) {
      await _refreshIfExpiring();
    }
    return _sendRaw(method, path, query: query, body: body);
  }

  Future<http.Response> _sendRaw(
    String method,
    String path, {
    Map<String, String>? query,
    dynamic body,
  }) async {
    final uri = Uri.parse(
      ApiConfig.effectiveBaseUrl + path,
    ).replace(queryParameters: query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = TokenStore.instance.accessToken;
    if (_requiresAuth(path) && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final encoded = body == null ? null : jsonEncode(body);

    late http.Response response;
    switch (method) {
      case 'GET':
        response = await _http.get(uri, headers: headers);
      case 'POST':
        response = await _http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        response = await _http.put(uri, headers: headers, body: encoded);
      case 'PATCH':
        response = await _http.patch(uri, headers: headers, body: encoded);
      case 'DELETE':
        response = await _http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported method $method');
    }
    return response;
  }

  /// Decodes the backend envelope. Returns `data` (may be null,
  /// a Map, or a List depending on the endpoint).
  dynamic _unwrap(http.Response response) {
    final status = response.statusCode;
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }
    if (status >= 200 && status < 300) {
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data')) {
          return decoded['data'];
        }
        if (decoded.containsKey('items')) {
          return decoded;
        }
      }
      return decoded;
    }
    final message = decoded is Map<String, dynamic>
        ? _errorMessage(decoded, status)
        : 'Request failed ($status)';
    throw ApiException(message, statusCode: status, code: _errorCode(decoded));
  }

  String? _errorCode(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final details = decoded['details'];
    return (details is Map<String, dynamic> ? details['code'] : decoded['code'])
        ?.toString();
  }

  Future<void> _refreshIfExpiring() async {
    final expiresAt = TokenStore.instance.accessTokenExpiresAt;
    if (expiresAt == null ||
        expiresAt.difference(DateTime.now()) >= const Duration(seconds: 60)) {
      return;
    }
    await _refreshOnce();
  }

  Future<void> _refreshOnce() {
    return _refreshInProgress ??= _performRefresh().whenComplete(
      () => _refreshInProgress = null,
    );
  }

  Future<void> _performRefresh() async {
    final refreshToken = TokenStore.instance.refreshToken;
    if (refreshToken == null) {
      await TokenStore.instance.clear();
      throw const ApiException('Please sign in again', statusCode: 401);
    }
    final response = await _sendRaw(
      'POST',
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    if (response.statusCode == 401) {
      await TokenStore.instance.clear();
    }
    final data = _unwrap(response);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected refresh response');
    }
    final access = data['accessToken']?.toString();
    final refresh = data['refreshToken']?.toString() ?? refreshToken;
    final expiresIn = (data['accessTokenExpiresIn'] as num?)?.toInt() ?? 900;
    if (access == null || access.isEmpty) {
      throw const ApiException('Unexpected refresh response');
    }
    await TokenStore.instance.save(
      access,
      refresh,
      accessExpiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    dynamic body,
  }) async {
    try {
      return _unwrap(await _send(method, path, query: query, body: body));
    } on ApiException catch (error) {
      if (_requiresAuth(path) &&
          error.statusCode == 401 &&
          error.code == 'TOKEN_EXPIRED') {
        await _refreshOnce();
        return _unwrap(await _sendRaw(method, path, query: query, body: body));
      }
      if (error.statusCode == 401 &&
          (error.code == 'TOKEN_INVALID' || error.code == 'SESSION_EXPIRED')) {
        await TokenStore.instance.clear();
      }
      rethrow;
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    return _request('GET', path, query: query);
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    return _request('POST', path, body: body);
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    return _request('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    return _request('PATCH', path, body: body);
  }

  Future<dynamic> delete(String path) async {
    return _request('DELETE', path);
  }

  /// Fetches authenticated binary content, such as a customer invoice PDF.
  Future<List<int>> getBytes(String path) async {
    try {
      final response = await _send('GET', path);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _unwrap(response);
      }
      return response.bodyBytes;
    } on ApiException catch (error) {
      if (_requiresAuth(path) &&
          error.statusCode == 401 &&
          error.code == 'TOKEN_EXPIRED') {
        await _refreshOnce();
        final response = await _sendRaw('GET', path);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          _unwrap(response);
        }
        return response.bodyBytes;
      }
      if (error.statusCode == 401 &&
          (error.code == 'TOKEN_INVALID' || error.code == 'SESSION_EXPIRED')) {
        await TokenStore.instance.clear();
      }
      rethrow;
    }
  }

  String _errorMessage(Map<String, dynamic> decoded, int status) {
    final message = decoded['message'] is String
        ? decoded['message'] as String
        : 'Request failed ($status)';
    final details = decoded['details'];
    if (details is! Map<String, dynamic>) {
      return message;
    }
    final fieldErrors = details['fieldErrors'];
    if (fieldErrors is! Map<String, dynamic>) {
      return message;
    }
    final parts = <String>[];
    for (final entry in fieldErrors.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        parts.add('${entry.key}: ${value.first}');
      } else if (value is String && value.isNotEmpty) {
        parts.add('${entry.key}: $value');
      }
    }
    return parts.isEmpty ? message : '$message — ${parts.join(', ')}';
  }
}
