import '../geo_point.dart';

/// Vendors around an address, from `GET /customer/nearby-vendors`.
///
/// The server counts approved vendors that are online within ~5 km and
/// that offer the requested service. Exact vendor positions are never
/// returned — only per-hexagon counts.
class NearbyVendors {
  const NearbyVendors({
    this.vendorsNearby = 0,
    this.nearestKm,
    this.etaMinutes,
    this.radiusKm,
    this.areas = const [],
  });

  /// How many vendors are online around the address.
  final int vendorsNearby;

  /// Distance to the closest vendor, in km.
  final double? nearestKm;

  /// Rough arrival time of the closest vendor, in minutes.
  final int? etaMinutes;

  /// Radius the server searched, in km.
  final double? radiusKm;

  /// Optional per-hexagon breakdown, for drawing shaded areas on a map.
  final List<NearbyVendorArea> areas;

  bool get hasVendors => vendorsNearby > 0;

  /// '12 min' style arrival estimate.
  String? get etaLabel {
    final minutes = etaMinutes;
    if (minutes == null || minutes <= 0) return null;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours hr' : '$hours hr $rest min';
  }

  /// '0.8 km away' style distance label.
  String? get distanceLabel {
    final km = nearestKm;
    if (km == null) return null;
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(1)} km away';
  }

  factory NearbyVendors.fromJson(Map<String, dynamic> json) {
    final areasJson = json['areas'];
    final areas = areasJson is List
        ? areasJson
              .whereType<Map<String, dynamic>>()
              .map(NearbyVendorArea.fromJson)
              .toList()
        : const <NearbyVendorArea>[];
    return NearbyVendors(
      vendorsNearby: (json['vendorsNearby'] as num?)?.toInt() ?? 0,
      nearestKm: _toDouble(json['nearestKm']),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      radiusKm: _toDouble(json['radiusKm']),
      areas: areas,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// One H3 hexagon in the `areas` breakdown.
class NearbyVendorArea {
  const NearbyVendorArea({
    required this.cell,
    this.center,
    this.boundary = const [],
    this.vendors = 0,
  });

  final String cell;
  final GeoPoint? center;
  final List<GeoPoint> boundary;
  final int vendors;

  factory NearbyVendorArea.fromJson(Map<String, dynamic> json) {
    final centerJson = json['center'];
    final boundaryJson = json['boundary'];
    return NearbyVendorArea(
      cell: (json['cell'] ?? '').toString(),
      center: centerJson is List && centerJson.length >= 2
          ? GeoPoint(
              latitude: _toDouble(centerJson[0]) ?? 0,
              longitude: _toDouble(centerJson[1]) ?? 0,
            )
          : null,
      boundary: boundaryJson is List
          ? boundaryJson
                .whereType<List>()
                .where((point) => point.length >= 2)
                .map(
                  (point) => GeoPoint(
                    latitude: _toDouble(point[0]) ?? 0,
                    longitude: _toDouble(point[1]) ?? 0,
                  ),
                )
                .toList()
          : const <GeoPoint>[],
      vendors: (json['vendors'] as num?)?.toInt() ?? 0,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
