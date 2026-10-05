/// AMC (annual maintenance contract) subscription.
///
/// `GET /amc` lists the customer's own subscriptions and accepts
/// a `status` filter (ACTIVE / EXPIRED / CANCELLED).
class AmcSubscription {
  const AmcSubscription({
    required this.id,
    required this.status,
    this.planName,
    this.startDate,
    this.endDate,
    this.amount,
    this.createdAt,
  });

  final String id;
  final String status;
  final String? planName;
  final DateTime? startDate;
  final DateTime? endDate;
  final num? amount;
  final DateTime? createdAt;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory AmcSubscription.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return AmcSubscription(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      planName: (json['planName'] ?? json['plan']?['name'] ?? json['name'])
          ?.toString(),
      startDate: parse(json['startDate']),
      endDate: parse(json['endDate']),
      amount: (json['amount'] ?? json['price']) as num?,
      createdAt: parse(json['createdAt']),
    );
  }
}

/// Normalizes paginated-or-plain list responses for AMC.
List<AmcSubscription> parseAmcList(dynamic data) {
  final list = _extractList(data);
  return list
      .whereType<Map<String, dynamic>>()
      .map(AmcSubscription.fromJson)
      .toList();
}

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    for (final key in const ['items', 'subscriptions', 'data', 'results']) {
      final value = data[key];
      if (value is List) return value;
    }
  }
  return const [];
}
