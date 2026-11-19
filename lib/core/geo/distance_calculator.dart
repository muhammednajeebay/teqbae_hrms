import 'dart:math' as math;

class DistanceCalculator {
  const DistanceCalculator();

  double metersBetween(double latitudeA, double longitudeA, double latitudeB, double longitudeB) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(latitudeB - latitudeA);
    final longitudeDelta = _radians(longitudeB - longitudeA);
    final haversine = math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(_radians(latitudeA)) * math.cos(_radians(latitudeB)) * math.sin(longitudeDelta / 2) * math.sin(longitudeDelta / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
