/// Service category from `GET /categories`.
///
/// The client's local catalog (`services_data.dart`) carries the
/// rich display data (icons, prices, durations, questions); this
/// model is the backend's authoritative id + name, used when
/// creating bookings (`POST /bookings` requires `categoryId`).
class ServiceCategory {
  const ServiceCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  @override
  String toString() => name;
}
