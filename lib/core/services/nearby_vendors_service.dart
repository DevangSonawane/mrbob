import 'api_client.dart';
import '../models/api/nearby_vendors.dart';

/// Vendors available around an address.
///
/// `GET /customer/nearby-vendors` counts approved vendors that are online
/// within ~5 km and that offer the requested service. Without a position
/// the server cannot match anything, so the address coordinates are
/// required for a meaningful answer.
class NearbyVendorsService {
  NearbyVendorsService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static final NearbyVendorsService instance = NearbyVendorsService();

  final ApiClient _api;

  /// Vendors near [latitude] / [longitude] that offer [categoryId].
  Future<NearbyVendors> nearby({
    double? latitude,
    double? longitude,
    String? categoryId,
  }) async {
    final data = await _api.get(
      '/customer/nearby-vendors',
      query: <String, String>{
        if (latitude != null) 'latitude': '$latitude',
        if (longitude != null) 'longitude': '$longitude',
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
      },
    );
    if (data is! Map<String, dynamic>) {
      return const NearbyVendors();
    }
    return NearbyVendors.fromJson(data);
  }
}
