/// A WGS-84 coordinate pair.
///
/// Used for the address pin, the device position and the
/// "vendors nearby" query. Coordinates are rounded to 6 decimals
/// (~11 cm) before they are sent to the backend.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  double get roundedLatitude => _round(latitude);
  double get roundedLongitude => _round(longitude);

  static double _round(double value) =>
      double.parse(value.toStringAsFixed(6));

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => '$roundedLatitude, $roundedLongitude';
}
