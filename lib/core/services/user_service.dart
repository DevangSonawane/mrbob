import 'api_client.dart';
import 'api_exception.dart';
import 'token_store.dart';
import '../models/api/app_user.dart';
import '../models/api/professional.dart';

/// Users module — the customer's own profile.
///
/// Customer-facing profile operations live under `/customer/profile`.
class UserService {
  UserService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static final UserService instance = UserService();

  final ApiClient _api;

  /// `GET /customer/profile` — fetch the current customer's profile.
  Future<AppUser> getProfile() async {
    final data = await _api.get('/customer/profile');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected profile response');
    }
    final user = AppUser.fromJson(data);
    await TokenStore.instance.updateUser(user);
    return user;
  }

  /// `PATCH /customer/profile` — update the current customer's profile.
  Future<AppUser> updateMe({
    String? name,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    final data = await _api.patch('/customer/profile', body: body);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected user response');
    }
    final user = AppUser.fromJson(data);
    await TokenStore.instance.updateUser(user);
    return user;
  }

  /// `DELETE /customer/profile` — permanently delete the current
  /// customer account and clear the local session.
  Future<void> deleteAccount() async {
    await _api.delete('/customer/profile');
    await TokenStore.instance.clear();
  }
}

/// Professionals module — read-only customer surface.
///
/// `GET /professionals/{id}` lets a customer view a
/// professional's profile (used alongside their reviews).
/// Registration, KYC status and listing are professional/ops
/// flows and intentionally absent.
class ProfessionalService {
  ProfessionalService._();

  static final ProfessionalService instance = ProfessionalService._();

  final _api = ApiClient.instance;

  /// `GET /professionals/{id}` — a professional by id.
  Future<Professional> getById(String id) async {
    final data = await _api.get('/professionals/$id');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected professional response');
    }
    return Professional.fromJson(data);
  }
}
