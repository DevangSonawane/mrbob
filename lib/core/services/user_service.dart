import 'api_client.dart';
import 'api_exception.dart';
import '../models/api/app_user.dart';
import '../models/api/professional.dart';

/// Users module — the customer's own profile.
///
/// Only `PATCH /users/me` is customer-facing. The list/get/
/// activate endpoints are admin-only and intentionally absent.
class UserService {
  UserService._();

  static final UserService instance = UserService._();

  final _api = ApiClient.instance;

  /// `PATCH /users/me` — update the current user's profile.
  Future<AppUser> updateMe({
    String? name,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    final data = await _api.patch('/users/me', body: body);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected user response');
    }
    final user = AppUser.fromJson(data);
    return user;
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
