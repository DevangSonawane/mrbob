import 'api_client.dart';
import 'api_exception.dart';
import '../models/api/api_booking.dart';

/// Bookings module — the customer's own bookings.
///
/// Customer-visible operations only: create, list, get by id
/// and status transitions. Assignment/dispatch endpoints are
/// admin/ops and intentionally absent.
class BookingService {
  BookingService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static final BookingService instance = BookingService();

  final ApiClient _api;

  /// `POST /bookings` — create a booking (status PENDING).
  ///
  /// [categoryId] must reference an active category from
  /// `GET /categories`. [scheduledAt], [description] and
  /// [paymentMode] are required by the current booking API.
  Future<ApiBooking> create({
    required String categoryId,
    required DateTime scheduledAt,
    required String description,
    required String paymentMode,
    String? addressId,
  }) async {
    final data = await _api.post(
      '/bookings',
      body: {
        'categoryId': categoryId,
        'scheduledAt': _toIsoDateTimeWithOffset(scheduledAt),
        'description': description,
        'paymentMode': paymentMode,
        if (addressId != null && addressId.isNotEmpty) 'addressId': addressId,
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected booking response');
    }
    return ApiBooking.fromJson(data);
  }

  String _toIsoDateTimeWithOffset(DateTime value) {
    final local = value.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final absoluteOffset = offset.abs();
    final hours = absoluteOffset.inHours.toString().padLeft(2, '0');
    final minutes = (absoluteOffset.inMinutes % 60).toString().padLeft(2, '0');
    return '${local.toIso8601String()}$sign$hours:$minutes';
  }

  /// `GET /customer/bookings` — bookings visible to the current customer.
  Future<List<ApiBooking>> list() async {
    final data = await _api.get('/customer/bookings');
    return parseBookingList(data);
  }

  /// `GET /customer/bookings/{id}` — a single booking owned by the
  /// current customer.
  Future<ApiBooking> getById(String id) async {
    final data = await _api.get('/customer/bookings/$id');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected booking response');
    }
    return ApiBooking.fromJson(data);
  }

  /// `POST /customer/bookings/{id}/rating` — rate (or update the rating
  /// of) the vendor for a completed booking.
  ///
  /// The API accepts ratings from 1 through 5 only. A non-completed booking
  /// is rejected by the server with 409; its `actions.canRate` flag indicates
  /// whether the action is currently available.
  Future<ApiBooking> rateVendor({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 5');
    }
    final data = await _api.post(
      '/customer/bookings/$bookingId/rating',
      body: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected booking response');
    }
    return ApiBooking.fromJson(data);
  }

  /// `PATCH /bookings/{id}/status` — transition a booking's
  /// status. Customers typically cancel (CANCELLED); completion
  /// is normally driven by the professional.
  Future<ApiBooking> updateStatus(String id, ApiBookingStatus status) async {
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
