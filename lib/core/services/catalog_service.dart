import '../models/api/zone_models.dart';
import '../models/api/service_category.dart';
import 'api_client.dart';

/// Catalog endpoints: cities, zones and service categories.
///
/// All three are public (no bearer token required) — the
/// customer needs them before/while signing up.
class CatalogService {
  CatalogService._();

  static final CatalogService instance = CatalogService._();

  final _api = ApiClient.instance;

  /// `GET /zones/cities` — list active cities.
  Future<List<City>> getCities() async {
    final data = await _api.get('/zones/cities');
    final list = data is List ? data : const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(City.fromJson)
        .toList();
  }

  /// `GET /zones` — list active zones, optionally filtered by city.
  Future<List<Zone>> getZones({String? cityId}) async {
    final data = await _api.get(
      '/zones',
      query: cityId == null ? null : {'cityId': cityId},
    );
    final list = data is List ? data : const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Zone.fromJson)
        .toList();
  }

  /// `GET /categories` — list active service categories.
  Future<List<ServiceCategory>> getCategories() async {
    final data = await _api.get('/categories');
    final list = data is List ? data : const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ServiceCategory.fromJson)
        .toList();
  }
}
