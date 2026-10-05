/// Review from `POST /reviews` (customer rates a completed
/// booking) and `GET /reviews/professional/{professionalId}`.
class Review {
  const Review({
    required this.id,
    required this.rating,
    this.comment,
    this.bookingId,
    this.professionalId,
    this.customerName,
    this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final String? bookingId;
  final String? professionalId;
  final String? customerName;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final createdJson = json['createdAt'];
    if (createdJson != null) {
      try {
        createdAt = DateTime.parse(createdJson.toString());
      } catch (_) {
        createdAt = null;
      }
    }

    return Review(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      rating: (json['rating'] ?? 0) is num
          ? (json['rating'] as num).toInt()
          : int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      comment: json['comment']?.toString(),
      bookingId: json['bookingId']?.toString(),
      professionalId: json['professionalId']?.toString(),
      customerName:
          json['customer']?['name']?.toString() ?? json['customerName']?.toString(),
      createdAt: createdAt,
    );
  }
}

/// Normalizes paginated-or-plain list responses for reviews.
List<Review> parseReviewList(dynamic data) {
  final list = _extractList(data);
  return list
      .whereType<Map<String, dynamic>>()
      .map(Review.fromJson)
      .toList();
}

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    for (final key in const ['items', 'reviews', 'data', 'results']) {
      final value = data[key];
      if (value is List) return value;
    }
  }
  return const [];
}
