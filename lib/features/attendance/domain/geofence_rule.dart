import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/geo/distance_calculator.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

/// Checks whether the employee's GPS coordinates are within the allowed radius
/// of the office before permitting a check-in or check-out.
///
/// The rule is a pure domain object — it has no knowledge of the Flutter
/// framework, the database, or the HTTP client.
class GeofenceRule {
  /// Creates a [GeofenceRule] that uses [_distanceCalculator] to measure
  /// distances. Inject [DistanceCalculator] in production and a mock in tests.
  const GeofenceRule(this._distanceCalculator);

  final DistanceCalculator _distanceCalculator;

  /// Checks whether the point ([latitude], [longitude]) falls inside the
  /// geofence defined by [office].
  ///
  /// Returns [Success] with the actual distance in metres if the employee is
  /// within [OfficeConfig.radiusMeters] of the office centre.
  ///
  /// Returns a [FailureResult] with a [RuleFailure] message that includes the
  /// exact distance if the employee is too far away.
  Result<double> validate({
    required OfficeConfig office,
    required double latitude,
    required double longitude,
  }) {
    final distance = _distanceCalculator.metersBetween(
      latitude,
      longitude,
      office.latitude,
      office.longitude,
    );
    if (distance > office.radiusMeters) {
      return FailureResult(
        RuleFailure(
          'You are ${distance.round()} m away. '
          'You must be within ${office.radiusMeters.round()} m of the office.',
        ),
      );
    }
    return Success(distance);
  }
}
