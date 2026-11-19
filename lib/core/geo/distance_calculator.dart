import 'dart:math' as math;

/// Calculates the straight-line distance between two GPS coordinates.
///
/// Uses the **Haversine formula**, which gives the shortest distance over the
/// surface of a sphere (the Earth). This is accurate enough for geofence checks
/// at the distances used in this app (< 500 m).
class DistanceCalculator {
  const DistanceCalculator();

  /// Returns the distance in **metres** between point A and point B.
  ///
  /// All coordinates must be in **decimal degrees** (e.g. `12.9716` for latitude
  /// and `77.5946` for longitude — the standard format used by GPS devices and
  /// the `geolocator` package).
  ///
  /// Example:
  /// ```dart
  /// const calc = DistanceCalculator();
  /// final metres = calc.metersBetween(12.9716, 77.5946, 12.9750, 77.5946);
  /// ```
  double metersBetween(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(latitudeB - latitudeA);
    final longitudeDelta = _radians(longitudeB - longitudeA);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
            math.cos(_radians(latitudeA)) *
                math.cos(_radians(latitudeB)) *
                math.sin(longitudeDelta / 2) *
                math.sin(longitudeDelta / 2);
    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  /// Converts [degrees] to radians.
  ///
  /// This is a private helper because the Haversine formula works in radians,
  /// but all public GPS coordinates are in degrees.
  double _radians(double degrees) => degrees * math.pi / 180;
}
