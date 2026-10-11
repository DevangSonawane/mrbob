/// Service category from `GET /categories`.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    this.tier,
    this.basePrice,
    this.image,
  });

  final String id;
  final String name;
  final String? tier;
  final int? basePrice;
  final String? image;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      tier: json['tier']?.toString(),
      basePrice: _parsePrice(json['basePrice']),
      image: json['image']?.toString(),
    );
  }

  static int? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return num.tryParse(value.toString())?.toInt();
  }

  @override
  String toString() => name;
}
