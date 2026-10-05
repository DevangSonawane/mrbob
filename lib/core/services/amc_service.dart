import 'api_client.dart';
import 'api_exception.dart';
import '../models/api/amc_subscription.dart';

/// AMC (annual maintenance contract) module — customer's own
/// subscriptions.
class AmcService {
  AmcService._();

  static final AmcService instance = AmcService._();

  final _api = ApiClient.instance;

  /// `POST /amc` — create an AMC subscription.
  ///
  /// The OpenAPI spec defines no request body for this endpoint,
  /// so an optional [planId] is sent when known and the body is
  /// otherwise empty.
  Future<AmcSubscription> create({String? planId}) async {
    final data = await _api.post(
      '/amc',
      body: planId == null ? const {} : {'planId': planId},
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected AMC response');
    }
    return AmcSubscription.fromJson(data);
  }

  /// `GET /amc` — the customer's own subscriptions, optionally
  /// filtered by status (ACTIVE / EXPIRED / CANCELLED).
  Future<List<AmcSubscription>> list({String? status}) async {
    final data = await _api.get(
      '/amc',
      query: status == null ? null : {'status': status},
    );
    return parseAmcList(data);
  }

  /// `GET /amc/{id}` — a single subscription.
  Future<AmcSubscription> getById(String id) async {
    final data = await _api.get('/amc/$id');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected AMC response');
    }
    return AmcSubscription.fromJson(data);
  }

  /// `POST /amc/{id}/cancel` — cancel a subscription.
  Future<AmcSubscription> cancel(String id) async {
    final data = await _api.post('/amc/$id/cancel');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected AMC response');
    }
    return AmcSubscription.fromJson(data);
  }
}
