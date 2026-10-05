import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Thin HTTP wrapper for the Home Services Platform API.
///
/// - Sends `Authorization: Bearer <token>` when a session exists.
/// - Unwraps the backend's `{ "success": bool, "data": ... }`
///   envelope and returns `data` directly.
/// - Throws [ApiException] with the backend's `message` on failure.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    dynamic body,
  }) async {
    final uri = Uri.parse(ApiConfig.effectiveBaseUrl + path).replace(
      queryParameters: query,
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = TokenStore.instance.accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final encoded = body == null ? null : jsonEncode(body);

    late http.Response response;
    switch (method) {
      case 'GET':
        response = await _http.get(uri, headers: headers);
      case 'POST':
        response = await _http.post(uri, headers: headers, body: encoded);
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
        return decoded['data'];
      }
      return decoded;
    }
    final message = decoded is Map<String, dynamic> &&
            decoded['message'] is String
        ? decoded['message'] as String
        : 'Request failed ($status)';
    throw ApiException(
      message,
      statusCode: status,
      code: decoded is Map<String, dynamic>
          ? decoded['code'] as String?
          : null,
    );
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    return _unwrap(await _send('GET', path, query: query));
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    return _unwrap(await _send('POST', path, body: body));
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    return _unwrap(await _send('PATCH', path, body: body));
  }

  Future<dynamic> delete(String path) async {
    return _unwrap(await _send('DELETE', path));
  }
}
