/// Backend base URL for the Home Services Platform API.
///
/// The OpenAPI spec's server entry is `http://localhost:4000/api/v1`
/// (local dev). The deployed instance is the Render URL below.
class ApiConfig {
  ApiConfig._();

  static const baseUrl =
      'https://home-services-backend-7cyx.onrender.com/api/v1';

  /// Flip to true to point at a locally running backend.
  static const useLocalhost = false;

  static String get effectiveBaseUrl =>
      useLocalhost ? 'http://localhost:4000/api/v1' : baseUrl;
}
