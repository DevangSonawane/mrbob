import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';

/// The device position is unavailable.
class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Device position access.
///
/// H3 dispatch needs the customer's coordinates on the saved address, and
/// the "vendors nearby" estimate needs them at booking time. Location is
/// only requested when the customer actually uses one of those flows.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  /// The current device position.
  ///
  /// Requests the permission prompt when the permission is not granted
  /// yet. Throws [LocationException] with a user-facing message when
  /// location services are off, the permission was refused, or the
  /// platform denied the fix.
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Turn on location services to use your current location.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is blocked. Enable it from Settings.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission is needed to pin your address.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      throw const LocationException(
        'Could not read your location. Try again in a moment.',
      );
    }
  }

  /// Opens the OS location settings so the customer can enable
  /// location services.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens the app settings so the customer can grant the permission.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
