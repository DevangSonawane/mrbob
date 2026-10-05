/// Customer/user account as returned by `/auth/me`, `/auth/*`
/// and `/onboarding/*`.
///
/// The backend wraps every response in `{success, data}`; the
/// user object itself uses `id` (or `_id`) plus an `isOnboarded`
/// flag (the onboarding endpoints flip it to true).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.role,
    this.isOnboarded = false,
    this.cityId,
    this.address,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? role;
  final bool isOnboarded;
  final String? cityId;
  final String? address;

  bool get isCustomer => role == null || role == 'CUSTOMER';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      isOnboarded: json['isOnboarded'] == true,
      cityId: json['cityId']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'isOnboarded': isOnboarded,
        'cityId': cityId,
        'address': address,
      };
}

/// Auth response: `{ user, accessToken, refreshToken }`.
///
/// Field names are matched leniently (`access_token`, `token`)
/// because the OpenAPI spec only documents "Returns access +
/// refresh tokens" without a response schema.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AppUser user;
  final String accessToken;
  final String refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    String pickToken(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return '';
    }

    final userJson = json['user'];
    final user = userJson is Map<String, dynamic>
        ? AppUser.fromJson(userJson)
        : const AppUser(id: '', name: '');

    return AuthSession(
      user: user,
      accessToken: pickToken(['accessToken', 'access_token', 'token']),
      refreshToken:
          pickToken(['refreshToken', 'refresh_token', 'refresh']),
    );
  }
}
