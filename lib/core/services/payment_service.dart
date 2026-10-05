import 'api_client.dart';
import 'api_exception.dart';
import '../models/api/payment.dart';

/// Payments module — Razorpay-backed.
///
/// Customer-facing operations: create an order for a booking
/// (the client then hands the order id to the Razorpay SDK) and
/// fetch a payment's status. The webhook endpoint is
/// server-to-server and not part of the client surface.
class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  /// `POST /payments/bookings/{bookingId}/order` — create a
  /// Razorpay order for a booking.
  Future<Payment> createOrder(String bookingId) async {
    final data = await _api.post(
      '/payments/bookings/$bookingId/order',
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected payment response');
    }
    return Payment.fromJson(data);
  }

  /// `GET /payments/{id}` — get a payment by id.
  Future<Payment> getById(String id) async {
    final data = await _api.get('/payments/$id');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected payment response');
    }
    return Payment.fromJson(data);
  }
}
