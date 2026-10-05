/// Professional profile from `GET /professionals/{id}`.
///
/// Field names beyond id/name are not in the OpenAPI spec, so
/// parsing is defensive (rating, categories, city, zone…).
class Professional {
  const Professional({
    required this.id,
    required this.name,
    this.rating,
    this.categories = const [],
    this.cityId,
    this.zoneId,
    this.phone,
    this.verified,
  });

  final String id;
  final String name;
  final double? rating;
  final List<String> categories;
  final String? cityId;
  final String? zoneId;
  final String? phone;
  final bool? verified;

  factory Professional.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'];
    final categoriesRaw = json['categories'];
    final categories = <String>[];
    if (categoriesRaw is List) {
      for (final item in categoriesRaw) {
        if (item is String) {
          categories.add(item);
        } else if (item is Map<String, dynamic>) {
          final name = item['name'];
          if (name is String) categories.add(name);
        }
      }
    }

    return Professional(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['businessName'] ?? '').toString(),
      rating: rating is num ? rating.toDouble() : null,
      categories: categories,
      cityId: json['cityId']?.toString(),
      zoneId: json['zoneId']?.toString(),
      phone: json['phone']?.toString(),
      verified: json['verified'] as bool?,
    );
  }
}
