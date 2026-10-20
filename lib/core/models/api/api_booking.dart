import 'package:flutter/material.dart';

import 'service_category.dart';

/// Booking lifecycle on the backend.
///
/// `POST /bookings` creates with status PENDING; the customer
/// may transition a booking through MATCHING → ASSIGNED →
/// IN_PROGRESS → COMPLETED, or CANCELLED.
enum ApiBookingStatus {
  awaitingPayment('AWAITING_PAYMENT'),
  pending('PENDING'),
  matching('MATCHING'),
  assigned('ASSIGNED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const ApiBookingStatus(this.value);

  final String value;

  static ApiBookingStatus fromString(String? value) =>
      ApiBookingStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => ApiBookingStatus.pending,
      );
}

/// Booking as returned by `GET /customer/bookings`,
/// `GET /customer/bookings/{id}` and `POST /bookings`.
///
/// Response fields beyond id/status/address/scheduledAt are not
/// in the OpenAPI spec, so the parser is defensive: unknown
/// keys are preserved in [raw] for debugging.
class ApiBooking {
  const ApiBooking({
    required this.id,
    required this.categoryId,
    required this.address,
    required this.status,
    this.category,
    this.scheduledAt,
    this.createdAt,
    this.customerId,
    this.professionalId,
    this.totalAmount,
    this.paymentStatus,
    this.paymentMode,
    this.customerRating,
    this.customerRatingComment,
    this.raw = const {},
  });

  final String id;
  final String categoryId;
  final String address;
  final ApiBookingStatus status;
  final ServiceCategory? category;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final String? customerId;
  final String? professionalId;
  final num? totalAmount;
  final String? paymentStatus;
  final String? paymentMode;

  /// The customer's current vendor rating, when the booking response
  /// includes `ratings.byCustomer`.
  final int? customerRating;
  final String? customerRatingComment;
  final Map<String, dynamic> raw;

  bool get isActive =>
      status == ApiBookingStatus.awaitingPayment ||
      status == ApiBookingStatus.pending ||
      status == ApiBookingStatus.matching ||
      status == ApiBookingStatus.assigned ||
      status == ApiBookingStatus.inProgress;

  DateTime? get dateTime => scheduledAt ?? createdAt;

  /// A payment section is optional on booking payloads. Use this to avoid
  /// presenting a payment action for bookings that have no payment data.
  bool get hasPaymentDetails =>
      paymentStatus != null || raw['payment'] is Map<String, dynamic>;

  factory ApiBooking.fromJson(Map<String, dynamic> json) {
    ServiceCategory? category;
    final categoryJson = json['category'] ?? json['service'];
    if (categoryJson is Map<String, dynamic>) {
      category = ServiceCategory.fromJson(categoryJson);
    }

    return ApiBooking(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      categoryId:
          (json['categoryId'] ??
                  _stringFromMap(json['category'], 'id') ??
                  _stringFromMap(json['service'], 'id') ??
                  '')
              .toString(),
      address: _addressLine(json['address']),
      status: ApiBookingStatus.fromString(json['status']?.toString()),
      category: category,
      scheduledAt: _parseDateTime(json['scheduledAt']),
      createdAt: _parseDateTime(json['createdAt']),
      customerId: json['customerId']?.toString(),
      professionalId: json['professionalId']?.toString(),
      totalAmount: _parseNumber(
        json['totalAmount'] ??
            json['amount'] ??
            json['price'] ??
            _valueFromMap(json['payment'], 'amount'),
      ),
      paymentStatus:
          json['paymentStatus']?.toString() ??
          _stringFromMap(json['payment'], 'status'),
      paymentMode:
          json['paymentMode']?.toString() ??
          _stringFromMap(json['payment'], 'mode'),
      customerRating: _ratingFromMap(json['ratings'], 'byCustomer'),
      customerRatingComment: _stringFromNestedMap(
        json['ratings'],
        'byCustomer',
        'comment',
      ),
      raw: json,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static dynamic _valueFromMap(dynamic value, String key) {
    if (value is Map<String, dynamic>) return value[key];
    return null;
  }

  static String? _stringFromMap(dynamic value, String key) {
    final raw = _valueFromMap(value, key);
    return raw?.toString();
  }

  static int? _ratingFromMap(dynamic value, String key) {
    final rating = _valueFromMap(value, key);
    if (rating is! Map<String, dynamic>) return null;
    final rawRating = rating['rating'];
    if (rawRating is num) return rawRating.toInt();
    return int.tryParse(rawRating?.toString() ?? '');
  }

  static String? _stringFromNestedMap(dynamic value, String key, String field) {
    final nested = _valueFromMap(value, key);
    return _stringFromMap(nested, field);
  }

  static num? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  static String _addressLine(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final line = value['line']?.toString();
      if (line != null && line.isNotEmpty) return line;
    }
    return value.toString();
  }
}

/// Normalizes a paginated-or-plain list response into a list of
/// bookings. The backend documents "Paginated list" for several
/// GET endpoints; the envelope may be a bare list or a map with
/// an `items`/`bookings`/`data` array.
List<ApiBooking> parseBookingList(dynamic data) {
  final list = _extractList(data);
  return list
      .whereType<Map<String, dynamic>>()
      .map(ApiBooking.fromJson)
      .toList();
}

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    for (final key in const ['items', 'bookings', 'data', 'results']) {
      final value = data[key];
      if (value is List) return value;
      if (value is Map<String, dynamic>) {
        final nested = _extractList(value);
        if (nested.isNotEmpty) return nested;
      }
    }
  }
  return const [];
}

/// Local display model used by the existing UI. The API model
/// above is the source of truth; this adapter feeds the
/// pre-existing `Booking` widgets until they migrate.
///
/// Not part of the API contract — UI-only shim.
class BookingDisplay {
  const BookingDisplay({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.price,
    required this.duration,
    required this.mode,
    required this.slot,
    required this.payment,
    required this.total,
    required this.statusLabel,
    required this.isCompleted,
    required this.isCancelled,
    required this.address,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int price;
  final String duration;
  final String mode;
  final String slot;
  final String payment;
  final int total;
  final String statusLabel;
  final bool isCompleted;
  final bool isCancelled;
  final String address;
}
