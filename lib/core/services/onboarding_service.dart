import 'api_client.dart';
import 'token_store.dart';
import '../models/api/app_user.dart';

/// Onboarding module: completes the customer profile after the
/// account exists (first OTP login or email signup).
class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();

  final _api = ApiClient.instance;

  /// `GET /onboarding/status` — the current user's onboarding
  /// status. The response shape is not in the OpenAPI spec; the
  /// parser accepts both a bare user object and a
  /// `{ isOnboarded: bool, user: {...} }` wrapper.
  Future<OnboardingStatus> getStatus() async {
    final data = await _api.get('/onboarding/status');
    if (data is! Map<String, dynamic>) {
      return const OnboardingStatus(isOnboarded: false);
    }

    final isOnboarded = data['isOnboarded'] == true ||
        (data['user'] is Map<String, dynamic> &&
            (data['user'] as Map<String, dynamic>)['isOnboarded'] == true);

    AppUser? user;
    final userJson = data['user'];
    if (userJson is Map<String, dynamic>) {
      user = AppUser.fromJson(userJson);
    }

    return OnboardingStatus(isOnboarded: isOnboarded, user: user);
  }

  /// `POST /onboarding/customer` — complete onboarding as a
  /// customer. Only `cityId` is required by the backend;
  /// name/phone/address are optional profile details.
  Future<AppUser> completeCustomerOnboarding({
    required String cityId,
    String? name,
    String? phone,
    String? address,
  }) async {
    final data = await _api.post(
      '/onboarding/customer',
      body: {
        'cityId': cityId,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
      },
    );

    AppUser user;
    if (data is Map<String, dynamic>) {
      // The endpoint returns the updated user (isOnboarded now
      // true) — either bare or nested under `user`.
      final userJson =
          data['user'] is Map<String, dynamic> ? data['user'] : data;
      user = AppUser.fromJson(userJson as Map<String, dynamic>);
    } else {
      user = TokenStore.instance.user ?? const AppUser(id: '', name: '');
    }
    await TokenStore.instance.updateUser(user);
    return user;
  }
}

class OnboardingStatus {
  const OnboardingStatus({required this.isOnboarded, this.user});

  final bool isOnboarded;
  final AppUser? user;
}
