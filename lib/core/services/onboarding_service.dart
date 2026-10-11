import 'api_client.dart';
import 'catalog_service.dart';
import 'token_store.dart';
import '../models/api/app_user.dart';

/// Customer onboarding module.
class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();
  static const defaultClientAddress = 'Andheri West, Mumbai, Maharashtra';
  static const defaultAddressLine1 = 'Andheri West';
  static const defaultAddressLine2 = 'Mumbai';
  static const defaultAddressState = 'Maharashtra';
  static const defaultAddressPincode = '400053';

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
  Future<AppUser> completeCustomerOnboarding({
    required String cityId,
    String? name,
    String? phone,
    String? gender,
    String? address,
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
        if (phone != null && phone.trim().isNotEmpty)
          'contactPhone': phone.trim(),
      },
    );

    final user = _parseUser(data);
    await TokenStore.instance.updateUser(user);
    return user;
  }

  /// Ensures the current customer has a saved default address
  /// and returns its id for `POST /bookings`.
  Future<String?> ensureDefaultAddress() async {
    final existing = await _listAddresses();
    final defaultAddress = existing.cast<Map<String, dynamic>?>().firstWhere(
      (address) => address?['isDefault'] == true,
      orElse: () => existing.isNotEmpty ? existing.first : null,
    );
    final defaultId = defaultAddress?['id'] ?? defaultAddress?['_id'];
    if (defaultId != null && defaultId.toString().isNotEmpty) {
      return defaultId.toString();
    }

    final cityId = await _defaultCityId();
    if (cityId == null || cityId.isEmpty) {
      return null;
    }

    final created = await _api.post(
      '/users/me/addresses',
      body: {
        'label': 'HOME',
        'line1': defaultAddressLine1,
        'line2': defaultAddressLine2,
        'cityId': cityId,
        'state': defaultAddressState,
        'pincode': defaultAddressPincode,
        'isDefault': true,
      },
    );
    if (created is Map<String, dynamic>) {
      final id = created['id'] ?? created['_id'];
      return id?.toString();
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _listAddresses() async {
    final data = await _api.get('/users/me/addresses');
    final list = data is List ? data : const <dynamic>[];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<String?> _defaultCityId() async {
    final userCityId = TokenStore.instance.user?.cityId;
    if (userCityId != null && userCityId.isNotEmpty) {
      return userCityId;
    }
    final cities = await CatalogService.instance.getCities();
    for (final city in cities) {
      final normalized = city.name.toLowerCase();
      if (normalized.contains('mumbai')) {
        return city.id;
      }
    }
    return cities.isNotEmpty ? cities.first.id : null;
  }

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
