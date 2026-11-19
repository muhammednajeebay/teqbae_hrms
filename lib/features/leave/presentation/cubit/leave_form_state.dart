import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

/// Represents the different submission phases of the leave form.
enum LeaveFormStatus {
  /// The form has not been submitted yet — fields are editable.
  initial,

  /// The form has passed validation and the HTTP request is in flight.
  submitting,

  /// The server accepted the request. The UI should navigate back.
  success,

  /// The server rejected the request (e.g. HTTP 422). The UI should show the
  /// error message from the server in [LeaveFormState.generalError].
  failure,
}

/// The immutable state of the leave application form.
///
/// Each field has a corresponding optional error string. When the error is
/// non-null, the UI should display it directly beneath that field.
class LeaveFormState extends Equatable {
  const LeaveFormState({
    this.type = LeaveType.casual,
    this.startDate,
    this.endDate,
    this.reason = '',
    this.status = LeaveFormStatus.initial,
    this.startDateError,
    this.endDateError,
    this.reasonError,
    this.generalError,
    this.isOffline = false,
  });

  /// Selected leave type (casual or sick).
  final LeaveType type;

  /// Selected start date. `null` before the user picks a date.
  final DateTime? startDate;

  /// Selected end date. `null` before the user picks a date.
  final DateTime? endDate;

  /// Text entered in the reason field.
  final String reason;

  /// Current form submission phase.
  final LeaveFormStatus status;

  /// Validation error for the start-date field, or `null` if valid.
  final String? startDateError;

  /// Validation error for the end-date field, or `null` if valid.
  final String? endDateError;

  /// Validation error for the reason field, or `null` if valid.
  final String? reasonError;

  /// A general error not tied to a specific field (e.g. server rejection, offline
  /// message). Displayed at the top or bottom of the form.
  final String? generalError;

  /// `true` if the device is offline when the user tries to submit.
  final bool isOffline;

  // ── Computed properties ───────────────────────────────────────────────────

  /// The number of calendar days covered by the selected date range.
  ///
  /// Returns `0` if either date is not set or if the end is before the start.
  int get daysRequested {
    if (startDate == null || endDate == null) return 0;
    if (endDate!.isBefore(startDate!)) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }

  /// `true` when the form looks valid enough to enable the Submit button.
  ///
  /// This is a quick client-side pre-check only. The cubit runs the full
  /// [LeaveValidator] before actually submitting to give detailed per-field
  /// feedback.
  bool get isValid =>
      startDate != null &&
      endDate != null &&
      reason.trim().length >= 10 &&
      startDateError == null &&
      endDateError == null &&
      reasonError == null;

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// Returns a copy of this state with any supplied fields replaced.
  ///
  /// Pass [clearErrors] = `true` to set all error strings to `null` at once
  /// (used right before submitting to show a clean form while the request is
  /// in flight).
  LeaveFormState copyWith({
    LeaveType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    LeaveFormStatus? status,
    String? startDateError,
    String? endDateError,
    String? reasonError,
    String? generalError,
    bool? isOffline,
    bool clearErrors = false,
  }) {
    return LeaveFormState(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      startDateError: clearErrors ? null : (startDateError ?? this.startDateError),
      endDateError: clearErrors ? null : (endDateError ?? this.endDateError),
      reasonError: clearErrors ? null : (reasonError ?? this.reasonError),
      generalError: clearErrors ? null : (generalError ?? this.generalError),
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [
        type,
        startDate,
        endDate,
        reason,
        status,
        startDateError,
        endDateError,
        reasonError,
        generalError,
        isOffline,
      ];
}
