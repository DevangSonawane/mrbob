import 'address_service.dart';
import 'api_client.dart';
import 'token_store.dart';
import '../models/api/app_user.dart';
import '../models/api/customer_address.dart';

/// Customer onboarding module.
class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();
  static const defaultClientAddress = 'Andheri West, Mumbai, Maharashtra';
  static const defaultAddressLine1 = AddressService.defaultLine1;
  static const defaultAddressLine2 = AddressService.defaultLine2;
  static const defaultAddressState = AddressService.defaultState;
  static const defaultAddressPincode = AddressService.defaultPincode;

  final _api = ApiClient.instance;

  /// `GET /customer-onboarding` — the current customer's
  /// onboarding state.
  Future<OnboardingStatus> getStatus() async {
    final data = await _api.get('/customer-onboarding');
    if (data is! Map<String, dynamic>) {
      return const OnboardingStatus(isOnboarded: false);
    }

    final isOnboarded =
        data['isOnboarded'] == true ||
        (data['flow'] is Map<String, dynamic> &&
            (data['flow'] as Map<String, dynamic>)['isComplete'] == true) ||
        (data['user'] is Map<String, dynamic> &&
            (data['user'] as Map<String, dynamic>)['isOnboarded'] == true);

    AppUser? user;
    final userJson = data['user'];
    if (userJson is Map<String, dynamic>) {
      user = AppUser.fromJson(userJson);
    }

    return OnboardingStatus(isOnboarded: isOnboarded, user: user);
  }

  /// Completes customer onboarding using the documented flow:
  /// `PUT /customer-onboarding/profile`, then
  /// `PUT /customer-onboarding/address`.
  ///
  /// [latitude] / [longitude] come from the map pin the customer placed.
  /// They are what H3 dispatch matches on, so an onboarding address
  /// without them falls straight through to "open to all vendors".
  Future<AppUser> completeCustomerOnboarding({
    required String cityId,
    String? name,
    String? phone,
    String? gender,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final profileBody = {
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (gender != null && gender.trim().isNotEmpty)
        'gender': _normalizeGender(gender),
    };
    if (profileBody.isNotEmpty) {
      await _api.put('/customer-onboarding/profile', body: profileBody);
    }

    final line1 = address?.trim().isNotEmpty == true
        ? address!.trim()
        : defaultClientAddress;
    final data = await _api.put(
      '/customer-onboarding/address',
      body: {
        'cityId': cityId,
        'label': 'HOME',
        'isDefault': true,
        'line1': line1,
        'line2': defaultAddressLine2,
        'state': defaultAddressState,
        'pincode': defaultAddressPincode,
        if (latitude != null && longitude != null) ...{
          'latitude': latitude,
          'longitude': longitude,
        },
        if (phone != null && phone.trim().isNotEmpty)
          'contactPhone': phone.trim(),
      },
    );

    final user = _parseUser(data);
    await TokenStore.instance.updateUser(user);
    return user;
  }

  /// Ensures the current customer has a saved default address and
  /// returns its id for `POST /bookings`.
  ///
  /// The address is resolved through [AddressService.addressForBooking],
  /// so it carries a position when the device can provide one.
  Future<String?> ensureDefaultAddress() async {
    final address = await AddressService.instance.addressForBooking();
    final id = address?.id ?? '';
    return id.isEmpty ? null : id;
  }

  /// The saved addresses of the current customer.
  Future<List<CustomerAddress>> listAddresses() =>
      AddressService.instance.list();

  /// The city the customer's addresses belong to.
  Future<String?> defaultCityId() => AddressService.instance.defaultCityId();

  AppUser _parseUser(dynamic data) {
    if (data is Map<String, dynamic>) {
      final userJson = data['user'] is Map<String, dynamic>
          ? data['user']
          : data;
      return AppUser.fromJson(userJson as Map<String, dynamic>);
    }
    return TokenStore.instance.user ?? const AppUser(id: '', name: '');
  }

  String _normalizeGender(String value) {
    return switch (value.trim().toLowerCase()) {
      'male' => 'MALE',
      'female' => 'FEMALE',
      _ => 'OTHER',
    };
  }
}

class OnboardingStatus {
  const OnboardingStatus({required this.isOnboarded, this.user});

  final bool isOnboarded;
  final AppUser? user;
}
