/// Error thrown by every service in `core/services`.
///
/// Carries the HTTP status code (when the server answered) and the
/// backend's `message` field, so UI can surface real failures
/// ("Email already registered", 409) instead of generic text.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() =>
      statusCode == null ? message : 'ApiException($statusCode): $message';
}
