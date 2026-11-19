import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';

enum AttendanceEventType { checkIn, checkOut }

enum AttendanceEventStatus { pending, synced, rejected }

enum TodayAttendanceStatus { notCheckedIn, checkedIn, checkedOut }

class OfficeConfig extends Equatable {
  const OfficeConfig({required this.latitude, required this.longitude, required this.radiusMeters});

  final double latitude;
  final double longitude;
  final double radiusMeters;

  @override
  List<Object> get props => [latitude, longitude, radiusMeters];
}

class AttendanceEvent extends Equatable {
  const AttendanceEvent({
    required this.clientEventId,
    required this.type,
    required this.occurredAt,
    required this.companyDate,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.sequence,
    this.accuracy,
    this.isMockedLocation = false,
    this.attempts = 0,
    this.lastError,
  });

  final int? sequence;
  final String clientEventId;
  final AttendanceEventType type;
  final DateTime occurredAt;
  final String companyDate;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final bool isMockedLocation;
  final AttendanceEventStatus status;
  final int attempts;
  final String? lastError;

  @override
  List<Object?> get props => [sequence, clientEventId, type, occurredAt, companyDate, latitude, longitude, accuracy, isMockedLocation, status, attempts, lastError];
}

class AttendanceRecord extends Equatable {
  const AttendanceRecord({required this.companyDate, this.checkInAt, this.checkOutAt});

  final String companyDate;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

  @override
  List<Object?> get props => [companyDate, checkInAt, checkOutAt];
}

class AttendanceRules {
  const AttendanceRules();

  Result<void> canCheckIn({required Iterable<AttendanceRecord> records, required Iterable<AttendanceEvent> events, required String companyDate}) {
    final hasCheckIn = _hasType(records, events, companyDate, AttendanceEventType.checkIn);
    return hasCheckIn ? const FailureResult(RuleFailure('You already checked in today.')) : const Success(null);
  }

  Result<void> canCheckOut({required Iterable<AttendanceRecord> records, required Iterable<AttendanceEvent> events, required String companyDate}) {
    final hasCheckIn = _hasType(records, events, companyDate, AttendanceEventType.checkIn);
    final hasCheckOut = _hasType(records, events, companyDate, AttendanceEventType.checkOut);
    if (!hasCheckIn) return const FailureResult(RuleFailure('You need to check in first.'));
    if (hasCheckOut) return const FailureResult(RuleFailure('You already checked out today.'));
    return const Success(null);
  }

  TodayAttendanceStatus deriveTodayStatus({required Iterable<AttendanceRecord> records, required Iterable<AttendanceEvent> events, required String companyDate}) {
    if (_hasType(records, events, companyDate, AttendanceEventType.checkOut)) return TodayAttendanceStatus.checkedOut;
    if (_hasType(records, events, companyDate, AttendanceEventType.checkIn)) return TodayAttendanceStatus.checkedIn;
    return TodayAttendanceStatus.notCheckedIn;
  }

  bool _hasType(Iterable<AttendanceRecord> records, Iterable<AttendanceEvent> events, String companyDate, AttendanceEventType type) {
    final recordsHaveType = records.where((record) => record.companyDate == companyDate).any((record) => type == AttendanceEventType.checkIn ? record.checkInAt != null : record.checkOutAt != null);
    final eventsHaveType = events.where((event) => event.companyDate == companyDate && event.status != AttendanceEventStatus.rejected).any((event) => event.type == type);
    return recordsHaveType || eventsHaveType;
  }
}
