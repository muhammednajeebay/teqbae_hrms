import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';

/// Possible event types a employee can produce in a single working day.
enum AttendanceEventType {
  /// Employee is arriving at the office and starting their shift.
  checkIn,

  /// Employee is leaving the office and ending their shift.
  checkOut,
}

/// Lifecycle of a local attendance event as it travels through the outbox.
enum AttendanceEventStatus {
  /// The event is saved locally and is waiting to be sent to the server.
  pending,

  /// The event was successfully acknowledged by the server.
  synced,

  /// The server (or the local rule engine) permanently rejected this event
  /// (e.g. duplicate check-in, wrong order). It will not be retried.
  rejected,
}

/// Whether the employee has checked in, checked out, or done neither today.
enum TodayAttendanceStatus {
  /// No check-in event exists for today yet.
  notCheckedIn,

  /// A check-in exists but no check-out yet — the employee is currently at work.
  checkedIn,

  /// Both a check-in and a check-out exist — the working day is complete.
  checkedOut,
}

// ── OfficeConfig ─────────────────────────────────────────────────────────────

/// GPS coordinates and geofence radius of the company office.
///
/// Used by [GeofenceRule] to decide whether the employee is close enough to
/// check in or out.
class OfficeConfig extends Equatable {
  const OfficeConfig({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  /// Latitude of the office centre point in decimal degrees.
  final double latitude;

  /// Longitude of the office centre point in decimal degrees.
  final double longitude;

  /// How many metres away from the centre point are still considered "at the office".
  final double radiusMeters;

  @override
  List<Object> get props => [latitude, longitude, radiusMeters];
}

// ── AttendanceEvent ───────────────────────────────────────────────────────────

/// A single check-in or check-out action created on the device.
///
/// Events are written to the local outbox immediately (status = [AttendanceEventStatus.pending])
/// and later sent to the server by [SyncService]. The [clientEventId] is a UUID
/// generated once when the user taps and never changes, even on retry — this is
/// how the server detects and silently ignores duplicate submissions.
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

  /// Auto-incremented primary key assigned by the local database.
  /// Used to maintain the strict ordering of events during sync.
  final int? sequence;

  /// UUID (v4) generated on the device when the user taps. Immutable for the
  /// lifetime of this event — used for server-side idempotency.
  final String clientEventId;

  /// Whether this is a check-in or check-out action.
  final AttendanceEventType type;

  /// The UTC moment the user tapped the button.
  final DateTime occurredAt;

  /// The company-local calendar date (format: `yyyy-MM-dd`) computed from
  /// [occurredAt] using the company timezone. This is the "day of work" this
  /// event belongs to.
  final String companyDate;

  /// GPS latitude at the time of the action (decimal degrees).
  final double latitude;

  /// GPS longitude at the time of the action (decimal degrees).
  final double longitude;

  /// GPS horizontal accuracy in metres. `null` if the device did not report it.
  final double? accuracy;

  /// `true` if the location came from a simulated preset in the Debug Panel
  /// rather than real device GPS.
  final bool isMockedLocation;

  /// Current lifecycle state of this event in the outbox.
  final AttendanceEventStatus status;

  /// How many times this event has been attempted by the sync engine.
  /// Incremented on every sync attempt (success or failure).
  final int attempts;

  /// The error message from the last failed sync attempt, or `null` if no
  /// error has occurred yet or the last attempt succeeded.
  final String? lastError;

  @override
  List<Object?> get props => [
        sequence,
        clientEventId,
        type,
        occurredAt,
        companyDate,
        latitude,
        longitude,
        accuracy,
        isMockedLocation,
        status,
        attempts,
        lastError,
      ];
}

// ── AttendanceRecord ──────────────────────────────────────────────────────────

/// A fully synced attendance day as returned by the server.
///
/// Unlike [AttendanceEvent] (which is a device-side outbox entry), an
/// [AttendanceRecord] represents a confirmed record on the server for a
/// single calendar day.
class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.companyDate,
    this.checkInAt,
    this.checkOutAt,
  });

  /// The company-local calendar date this record belongs to (`yyyy-MM-dd`).
  final String companyDate;

  /// UTC timestamp when the employee checked in. `null` for days with no
  /// check-in record.
  final DateTime? checkInAt;

  /// UTC timestamp when the employee checked out. `null` if the employee
  /// has not yet checked out.
  final DateTime? checkOutAt;

  @override
  List<Object?> get props => [companyDate, checkInAt, checkOutAt];
}

// ── AttendanceRules ───────────────────────────────────────────────────────────

/// Pure domain rules that decide whether a check-in or check-out action is
/// allowed, based on existing records and local outbox events.
///
/// This class contains **no Flutter, Drift, or Dio code**. It only reads from
/// the data passed in, making it easy to test without any infrastructure.
class AttendanceRules {
  const AttendanceRules();

  /// Returns [Success] if the employee is allowed to check in today,
  /// or a [FailureResult] with a [RuleFailure] if they are not.
  ///
  /// A check-in is blocked if any check-in already exists for [companyDate]
  /// in either the synced [records] or the local pending [events].
  Result<void> canCheckIn({
    required Iterable<AttendanceRecord> records,
    required Iterable<AttendanceEvent> events,
    required String companyDate,
  }) {
    final hasCheckIn = _hasType(records, events, companyDate, AttendanceEventType.checkIn);
    return hasCheckIn
        ? const FailureResult(RuleFailure('You already checked in today.'))
        : const Success(null);
  }

  /// Returns [Success] if the employee is allowed to check out today,
  /// or a [FailureResult] with a [RuleFailure] if they are not.
  ///
  /// A check-out requires a prior check-in. A second check-out on the same
  /// day is also blocked.
  Result<void> canCheckOut({
    required Iterable<AttendanceRecord> records,
    required Iterable<AttendanceEvent> events,
    required String companyDate,
  }) {
    final hasCheckIn = _hasType(records, events, companyDate, AttendanceEventType.checkIn);
    final hasCheckOut = _hasType(records, events, companyDate, AttendanceEventType.checkOut);
    if (!hasCheckIn) return const FailureResult(RuleFailure('You need to check in first.'));
    if (hasCheckOut) return const FailureResult(RuleFailure('You already checked out today.'));
    return const Success(null);
  }

  /// Derives the employee's current status for today by scanning both the
  /// synced server records and the local pending/synced events.
  ///
  /// Returns:
  /// - [TodayAttendanceStatus.checkedOut] if a check-out exists for today.
  /// - [TodayAttendanceStatus.checkedIn] if a check-in exists but no check-out.
  /// - [TodayAttendanceStatus.notCheckedIn] if no attendance activity today.
  TodayAttendanceStatus deriveTodayStatus({
    required Iterable<AttendanceRecord> records,
    required Iterable<AttendanceEvent> events,
    required String companyDate,
  }) {
    if (_hasType(records, events, companyDate, AttendanceEventType.checkOut)) {
      return TodayAttendanceStatus.checkedOut;
    }
    if (_hasType(records, events, companyDate, AttendanceEventType.checkIn)) {
      return TodayAttendanceStatus.checkedIn;
    }
    return TodayAttendanceStatus.notCheckedIn;
  }

  /// Returns `true` if an event of [type] exists for [companyDate] in either
  /// the server [records] or the local [events] (excluding rejected events).
  bool _hasType(
    Iterable<AttendanceRecord> records,
    Iterable<AttendanceEvent> events,
    String companyDate,
    AttendanceEventType type,
  ) {
    final recordsHaveType = records
        .where((record) => record.companyDate == companyDate)
        .any((record) => type == AttendanceEventType.checkIn
            ? record.checkInAt != null
            : record.checkOutAt != null);
    final eventsHaveType = events
        .where((event) =>
            event.companyDate == companyDate &&
            event.status != AttendanceEventStatus.rejected)
        .any((event) => event.type == type);
    return recordsHaveType || eventsHaveType;
  }
}
