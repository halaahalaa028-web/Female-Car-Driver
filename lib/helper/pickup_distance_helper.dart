import 'package:geolocator/geolocator.dart';

/// Pure helpers for the "captain -> customer pickup" distance shown on the
/// ride request card.
class PickupDistanceHelper {
  /// Backend sends GeoJSON order: [longitude, latitude].
  /// Returns null when the coordinates are missing or invalid.
  static ({double lat, double lng})? parseGeoJson(List<double>? coordinates) {
    if (coordinates == null || coordinates.length < 2) return null;
    final lng = coordinates[0];
    final lat = coordinates[1];
    if (lat.isNaN || lng.isNaN || lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    // 0,0 means "no location yet" (default Position in LocationController).
    if (lat == 0 && lng == 0) return null;
    return (lat: lat, lng: lng);
  }

  /// Straight-line distance in kilometres between two points.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Formats a distance such as "6.48 Km".
  static String format(double km) => '${km.toStringAsFixed(2)} Km';
}
