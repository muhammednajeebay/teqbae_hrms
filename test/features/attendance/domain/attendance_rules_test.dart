import 'package:flutter_test/flutter_test.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/geofence_rule.dart';
import 'package:teqbae_hrms/core/geo/distance_calculator.dart';

void main() {
  const rules = AttendanceRules();
  const date = '2026-11-19';

  test('check-out without check-in is rejected', () {
    final result = rules.canCheckOut(records: const [], events: const [], companyDate: date);
    expect(result, isA<FailureResult<void>>());
  });

  test('second check-in on the same day is rejected', () {
    final result = rules.canCheckIn(records: const [], events: [event(AttendanceEventType.checkIn)], companyDate: date);
    expect(result, isA<FailureResult<void>>());
  });

  test('rejected local events do not change today status', () {
    final status = rules.deriveTodayStatus(records: const [], events: [event(AttendanceEventType.checkIn, status: AttendanceEventStatus.rejected)], companyDate: date);
    expect(status, TodayAttendanceStatus.notCheckedIn);
  });

  test('geofence accepts office location and rejects a distant location', () {
    const rule = GeofenceRule(DistanceCalculator());
    const office = OfficeConfig(latitude: 9.9312, longitude: 76.2673, radiusMeters: 200);
    expect(rule.validate(office: office, latitude: 9.9312, longitude: 76.2673), isA<Success<double>>());
    expect(rule.validate(office: office, latitude: 9.9412, longitude: 76.2673), isA<FailureResult<double>>());
  });
}

AttendanceEvent event(AttendanceEventType type, {AttendanceEventStatus status = AttendanceEventStatus.pending}) {
  return AttendanceEvent(clientEventId: type.name, type: type, occurredAt: DateTime.utc(2026, 11, 19, 9), companyDate: '2026-11-19', latitude: 9.9312, longitude: 76.2673, status: status);
}
