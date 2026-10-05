/// Active city from `GET /zones/cities`.
class City {
  const City({required this.id, required this.name});

  final String id;
  final String name;

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  @override
  String toString() => name;
}

/// Active service zone from `GET /zones` (optionally by city).
class Zone {
  const Zone({required this.id, required this.name, this.cityId});

  final String id;
  final String name;
  final String? cityId;

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      cityId: json['cityId']?.toString(),
    );
  }

  @override
  String toString() => name;
}
