import 'api_client.dart';
import 'api_exception.dart';
import '../models/api/api_booking.dart';

/// Bookings module — the customer's own bookings.
///
/// Customer-visible operations only: create, list, get by id
/// and status transitions. Assignment/dispatch endpoints are
/// admin/ops and intentionally absent.
class BookingService {
  BookingService._();

  static final BookingService instance = BookingService._();

  final _api = ApiClient.instance;

  /// `POST /bookings` — create a booking (status PENDING).
  ///
  /// [categoryId] must reference an active category
  /// (`GET /categories`); [address] is the service address.
  /// [scheduledAt] is optional — omit for instant bookings.
  Future<ApiBooking> create({
    required String categoryId,
    required String address,
    DateTime? scheduledAt,
  }) async {
    final data = await _api.post(
      '/bookings',
      body: {
        'categoryId': categoryId,
        'address': address,
        if (scheduledAt != null)
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected booking response');
    }
    return ApiBooking.fromJson(data);
  }

  /// `GET /bookings` — bookings visible to the current user.
  Future<List<ApiBooking>> list() async {
    final data = await _api.get('/bookings');
    return parseBookingList(data);
  }

  /// `GET /bookings/{id}` — a single booking (customer on the
  /// booking, or admin).
  Future<ApiBooking> getById(String id) async {
    final data = await _api.get('/bookings/$id');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected booking response');
    }
    return ApiBooking.fromJson(data);
  }

  /// `PATCH /bookings/{id}/status` — transition a booking's
  /// status. Customers typically cancel (CANCELLED); completion
  /// is normally driven by the professional.
  Future<ApiBooking> updateStatus(
    String id,
    ApiBookingStatus status,
  ) async {
    final data = await _api.patch(
      '/bookings/$id/status',
      body: {'status': status.value},
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected booking response');
    }
    return ApiBooking.fromJson(data);
  }
}
