import '../models/api/customer_dispute.dart';
import 'api_client.dart';
import 'api_exception.dart';

class DisputeService {
  DisputeService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  static final DisputeService instance = DisputeService();
  final ApiClient _api;

  Future<List<DisputeCategory>> categories() async {
    final data = await _api.get('/customer/disputes/categories');
    if (data is! List)
      throw const ApiException('Unexpected dispute categories response');
    return data
        .whereType<Map<String, dynamic>>()
        .map(DisputeCategory.fromJson)
        .toList();
  }

  Future<CustomerDispute> create({
    required String type,
    required String category,
    required String subject,
    required String description,
    String? bookingId,
  }) => _bookingFrom(
    _api.post(
      '/customer/disputes',
      body: {
        'type': type,
        'category': category,
        'subject': subject.trim(),
        'description': description.trim(),
        if (bookingId != null && bookingId.trim().isNotEmpty)
          'bookingId': bookingId.trim(),
      },
    ),
  );

  Future<List<CustomerDispute>> list({
    String? status,
    String? type,
    String? bookingId,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _api.get(
      '/customer/disputes',
      query: {
        'page': '$page',
        'limit': '$limit',
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
    if (data is! Map<String, dynamic>)
      throw const ApiException('Unexpected disputes response');
    return (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CustomerDispute.fromJson)
        .toList();
  }

  Future<CustomerDispute> get(String id) =>
      _bookingFrom(_api.get('/customer/disputes/$id'));
  Future<CustomerDispute> reply(String id, String message) => _bookingFrom(
    _api.post(
      '/customer/disputes/$id/messages',
      body: {'message': message.trim()},
    ),
  );
  Future<CustomerDispute> close(String id) =>
      _bookingFrom(_api.post('/customer/disputes/$id/close'));

  Future<CustomerDispute> _bookingFrom(Future<dynamic> source) async {
    final data = await source;
    if (data is! Map<String, dynamic>)
      throw const ApiException('Unexpected dispute response');
    return CustomerDispute.fromJson(data);
  }
}
