import 'api_client.dart';
import 'api_exception.dart';
import 'catalog_service.dart';
import 'location_service.dart';
import 'token_store.dart';
import '../models/api/customer_address.dart';

/// The customer's saved addresses.
///
/// H3 dispatch matches a booking against the coordinates on the address,
/// so creating or editing an address always sends `latitude` and
/// `longitude` together when a position is known.
class AddressService {
  AddressService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static final AddressService instance = AddressService();

  /// Fallback address used when the customer has not saved one yet.
  static const defaultLine1 = 'Andheri West';
  static const defaultLine2 = 'Mumbai';
  static const defaultState = 'Maharashtra';
  static const defaultPincode = '400053';

  final ApiClient _api;

  /// `GET /users/me/addresses` — every address of the current customer.
  Future<List<CustomerAddress>> list() async {
    final data = await _api.get('/users/me/addresses');
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(CustomerAddress.fromJson)
        .toList();
  }

  /// The address a booking is placed against — the default one, or the
  /// first saved address when none is marked as default.
  Future<CustomerAddress?> defaultAddress() async {
    final addresses = await list();
    if (addresses.isEmpty) return null;
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  /// `POST /users/me/addresses` — saves a new address.
  Future<CustomerAddress> create({
    required String line1,
    required String cityId,
    required String state,
    required String pincode,
    String? label,
    String? line2,
    String? landmark,
    String? zoneId,
    double? latitude,
    double? longitude,
    String? contactName,
    String? contactPhone,
    bool isDefault = false,
  }) async {
    final address = CustomerAddress(
      id: '',
      label: label ?? 'HOME',
      line1: line1,
      line2: line2,
      landmark: landmark,
      state: state,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      contactName: contactName,
      contactPhone: contactPhone,
    );
    final body = address.toRequestBody()..['cityId'] = cityId;
    if (zoneId != null && zoneId.isNotEmpty) {
      body['zoneId'] = zoneId;
    }
    final data = await _api.post('/users/me/addresses', body: body);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected address response');
    }
    return CustomerAddress.fromJson(data);
  }

  /// `PATCH /users/me/addresses/{id}` — updates an address.
  Future<CustomerAddress> update(
    String id, {
    String? line1,
    String? line2,
    String? landmark,
    String? label,
    String? cityId,
    String? zoneId,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? contactName,
    String? contactPhone,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{
      if (line1 != null && line1.trim().isNotEmpty) 'line1': line1.trim(),
      if (line2 != null) 'line2': line2.trim(),
      if (landmark != null) 'landmark': landmark.trim(),
      'label': ?label,
      if (cityId != null && cityId.isNotEmpty) 'cityId': cityId,
      if (zoneId != null && zoneId.isNotEmpty) 'zoneId': zoneId,
      if (state != null && state.trim().isNotEmpty) 'state': state.trim(),
      if (pincode != null && pincode.trim().isNotEmpty) 'pincode': pincode.trim(),
      if (latitude != null && longitude != null) ...{
        'latitude': latitude,
        'longitude': longitude,
      },
      if (contactName != null) 'contactName': contactName.trim(),
      if (contactPhone != null) 'contactPhone': contactPhone.trim(),
      'isDefault': ?isDefault,
    };
    final data = await _api.patch('/users/me/addresses/$id', body: body);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected address response');
    }
    return CustomerAddress.fromJson(data);
  }

  /// `POST /users/me/addresses/{id}/default` — makes this the address
  /// bookings are placed against.
  Future<CustomerAddress> setDefault(String id) async {
    final data = await _api.post('/users/me/addresses/$id/default');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected address response');
    }
    return CustomerAddress.fromJson(data);
  }

  /// `DELETE /users/me/addresses/{id}`.
  Future<void> delete(String id) async {
    await _api.delete('/users/me/addresses/$id');
  }

  /// The address a booking is placed against, with a position attached.
  ///
  /// H3 dispatch drops a booking into the hexagon that contains the
  /// address, so the address needs coordinates. When the saved address
  /// has none, the current device position is fetched once and saved onto
  /// it. Failures are non-fatal — the booking still goes through, it is
  /// just opened to all vendors.
  Future<CustomerAddress?> addressForBooking() async {
    var address = await defaultAddress();
    address ??= await createDefaultAddress();
    if (address == null || address.hasLocation) {
      return address;
    }

    try {
      final position = await LocationService.instance
          .currentPosition()
          .timeout(const Duration(seconds: 12));
      return await update(
        address.id,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // No position available — the booking is still valid, it just is
      // not matched against nearby vendors.
      return address;
    }
  }

  /// Creates the fallback default address, using the customer's city.
  Future<CustomerAddress?> createDefaultAddress() async {
    final cityId = await defaultCityId();
    if (cityId == null || cityId.isEmpty) {
      return null;
    }
    return create(
      line1: defaultLine1,
      line2: defaultLine2,
      cityId: cityId,
      state: defaultState,
      pincode: defaultPincode,
      label: 'HOME',
      isDefault: true,
    );
  }

  /// The customer's city — from the session, else the first known city.
  Future<String?> defaultCityId() async {
    final userCityId = TokenStore.instance.user?.cityId;
    if (userCityId != null && userCityId.isNotEmpty) {
      return userCityId;
    }
    final cities = await CatalogService.instance.getCities();
    for (final city in cities) {
      if (city.name.toLowerCase().contains('mumbai')) {
        return city.id;
      }
    }
    return cities.isNotEmpty ? cities.first.id : null;
  }
}
