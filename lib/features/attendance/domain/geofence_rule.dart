import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/geo/distance_calculator.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

class GeofenceRule {
  const GeofenceRule(this._distanceCalculator);

  final DistanceCalculator _distanceCalculator;

  Result<double> validate({required OfficeConfig office, required double latitude, required double longitude}) {
    final distance = _distanceCalculator.metersBetween(latitude, longitude, office.latitude, office.longitude);
    if (distance > office.radiusMeters) return FailureResult(RuleFailure('You are ${distance.round()} m away. You must be within ${office.radiusMeters.round()} m of the office.'));
    return Success(distance);
  }
}
