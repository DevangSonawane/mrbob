/// Payment record from `POST /payments/bookings/{bookingId}/order`
/// (Razorpay order creation) and `GET /payments/{id}`.
///
/// The Razorpay flow returns an order id + amount; the exact
/// field names are not in the OpenAPI spec, so parsing is
/// lenient (`orderId`/`order_id`/`razorpay_order_id`).
class Payment {
  const Payment({
    required this.id,
    this.bookingId,
    this.amount,
    this.currency,
    this.status,
    this.orderId,
    this.createdAt,
  });

  final String id;
  final String? bookingId;
  final num? amount;
  final String? currency;
  final String? status;
  final String? orderId;
  final DateTime? createdAt;

  factory Payment.fromJson(Map<String, dynamic> json) {
    String? orderId;
    for (final key in const [
      'orderId',
      'order_id',
      'razorpay_order_id',
      'razorpayOrderId',
    ]) {
      if (json[key] is String) {
        orderId = json[key] as String;
        break;
      }
    }

    DateTime? createdAt;
    final createdJson = json['createdAt'];
    if (createdJson != null) {
      try {
        createdAt = DateTime.parse(createdJson.toString());
      } catch (_) {
        createdAt = null;
      }
    }

    return Payment(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      bookingId: json['bookingId']?.toString(),
      amount: (json['amount'] ?? json['totalAmount']) as num?,
      currency: json['currency']?.toString(),
      status: json['status']?.toString(),
      orderId: orderId,
      createdAt: createdAt,
    );
  }
}
