import 'api_client.dart';
import 'api_exception.dart';
import 'token_store.dart';
import '../models/api/app_user.dart';

/// Auth module: phone-OTP, email/password signup + login,
/// token refresh and the current-user profile.
///
/// Every method that returns an [AuthSession] also persists the
/// token pair (and user) via [TokenStore], so the rest of the
/// app can rely on [TokenStore.instance.hasSession].
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;

  /// `POST /customer-onboarding/otp/request` — request a
  /// customer-login OTP for a phone number.
  Future<void> requestOtp(String phone) async {
    await _api.post('/customer-onboarding/otp/request', body: {'phone': phone});
  }

  /// `POST /customer-onboarding/otp/verify` — verify the OTP
  /// and sign the customer in. Creates the customer on first use.
  Future<AuthSession> verifyOtp(String phone, String op, {String? name}) async {
    final data = await _api.post(
      '/customer-onboarding/otp/verify',
      body: {
        'phone': phone,
        'otp': op,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );
    final session = _sessionFrom(data);
    await TokenStore.instance.save(
      session.accessToken,
      session.refreshToken,
      user: session.user,
    );
    return session;
  }

  /// `POST /auth/signup` — email + password signup. Always
  /// creates a CUSTOMER account (the backend has no public
  /// admin/professional signup).
  Future<AuthSession> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _api.post(
      '/auth/signup',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    final session = _sessionFrom(data);
    await TokenStore.instance.save(
      session.accessToken,
      session.refreshToken,
      user: session.user,
    );
    return session;
  }

  /// `POST /auth/login` — email + password login.
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    final session = _sessionFrom(data);
    await TokenStore.instance.save(
      session.accessToken,
      session.refreshToken,
      user: session.user,
    );
    return session;
  }

  /// `POST /auth/refresh` — exchange a refresh token for a new
  /// pair. Returns null when no refresh token is stored.
  Future<AuthSession?> refresh() async {
    final stored = TokenStore.instance.refreshToken;
    if (stored == null) return null;
    final data = await _api.post(
      '/auth/refresh',
      body: {'refreshToken': stored},
    );
    final session = _sessionFrom(data);
    await TokenStore.instance.save(
      session.accessToken,
      session.refreshToken,
      user: session.user,
    );
    return session;
  }

  /// `GET /auth/me` — the currently authenticated user.
  Future<AppUser> me() async {
    final data = await _api.get('/auth/me');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected profile response');
    }
    final user = AppUser.fromJson(data);
    await TokenStore.instance.updateUser(user);
    return user;
  }

  /// Clears the persisted session (demo sign-out).
  Future<void> signOut() async {
    await TokenStore.instance.clear();
  }

  AuthSession _sessionFrom(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected auth response');
    }
    return AuthSession.fromJson(data);
  }
}
