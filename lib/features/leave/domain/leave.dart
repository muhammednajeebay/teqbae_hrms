import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';

/// Leave request approval status as reported by the server.
enum LeaveStatus {
  /// The request has been submitted but not yet reviewed.
  pending,

  /// HR approved the leave request.
  approved,

  /// HR or the system rejected the leave request.
  rejected,
}

/// Type of leave being requested.
enum LeaveType {
  /// General discretionary leave (e.g. personal errands, vacation).
  casual,

  /// Leave taken due to illness or medical reasons.
  sick,
}

// ── LeaveRequest ──────────────────────────────────────────────────────────────

/// A single leave request submitted by the employee.
class LeaveRequest extends Equatable {
  const LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });

  /// Unique ID assigned by the server.
  final String id;

  /// Whether this is a casual or sick leave.
  final LeaveType type;

  /// The first day of the requested leave period (UTC, date portion only).
  final DateTime startDate;

  /// The last day of the requested leave period (UTC, date portion only).
  final DateTime endDate;

  /// Employee's explanation for requesting leave (minimum 10 characters).
  final String reason;

  /// Current approval status.
  final LeaveStatus status;

  @override
  List<Object?> get props => [id, type, startDate, endDate, reason, status];
}

// ── LeaveBalance ──────────────────────────────────────────────────────────────

/// The employee's current leave balance as reported by the server.
class LeaveBalance extends Equatable {
  const LeaveBalance({
    required this.availableDays,
    required this.updatedAt,
  });

  /// Number of leave days the employee can still use.
  final int availableDays;

  /// UTC timestamp of when the server last updated this balance.
  final DateTime updatedAt;

  @override
  List<Object?> get props => [availableDays, updatedAt];
}

// ── LeaveValidator ────────────────────────────────────────────────────────────

/// Pure domain validator for leave requests.
///
/// Contains all five client-side leave rules. The server must enforce the same
/// rules independently — the client checks are for immediate user feedback only.
///
/// Rules enforced:
/// 1. Start date must not be in the past.
/// 2. End date must not be before start date.
/// 3. Reason must be at least 10 characters long.
/// 4. Requested duration must not exceed the available leave balance.
/// 5. The requested dates must not overlap any existing non-rejected leave.
class LeaveValidator {
  const LeaveValidator();

  /// Validates a leave request and returns [Success] if all rules pass, or a
  /// [FailureResult] with a [ValidationFailure] for the first rule that fails.
  ///
  /// [ValidationFailure.field] identifies which form field should display the
  /// error:
  /// - `'startDate'` — start date problems (past, overlapping).
  /// - `'endDate'` — end date problems (before start, exceeds balance).
  /// - `'reason'` — reason too short.
  Result<void> validate({
    required DateTime today,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required int availableDays,
    required Iterable<LeaveRequest> existingRequests,
  }) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    // Rule 1: Cannot start in the past.
    if (start.isBefore(_dateOnly(today))) {
      return const FailureResult(
          ValidationFailure('Start date cannot be before today.', field: 'startDate'));
    }

    // Rule 2: End date must be on or after start date.
    if (end.isBefore(start)) {
      return const FailureResult(
          ValidationFailure('End date cannot be before start date.', field: 'endDate'));
    }

    // Rule 3: Reason must be meaningful (at least 10 characters).
    if (reason.trim().length < 10) {
      return const FailureResult(
          ValidationFailure('Reason must contain at least 10 characters.', field: 'reason'));
    }

    // Rule 4: Duration must not exceed the available balance.
    if (end.difference(start).inDays + 1 > availableDays) {
      return const FailureResult(ValidationFailure(
          'Requested days exceed your available leave balance.', field: 'endDate'));
    }

    // Rule 5: No date overlap with any pending or approved leave request.
    final overlaps = existingRequests
        .where((request) => request.status != LeaveStatus.rejected)
        .any((request) =>
            !start.isAfter(_dateOnly(request.endDate)) &&
            !end.isBefore(_dateOnly(request.startDate)));
    if (overlaps) {
      return const FailureResult(ValidationFailure(
          'These dates overlap an existing leave request.', field: 'startDate'));
    }

    return const Success(null);
  }

  /// Strips the time portion from a [DateTime] so comparisons only look at
  /// the calendar date.
  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
