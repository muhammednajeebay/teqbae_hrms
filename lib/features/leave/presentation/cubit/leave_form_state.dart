import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

enum LeaveFormStatus { initial, submitting, success, failure }

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

  final LeaveType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String reason;
  final LeaveFormStatus status;
  final String? startDateError;
  final String? endDateError;
  final String? reasonError;
  final String? generalError;
  final bool isOffline;

  int get daysRequested {
    if (startDate == null || endDate == null) return 0;
    if (endDate!.isBefore(startDate!)) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }

  bool get isValid =>
      startDate != null &&
      endDate != null &&
      reason.trim().length >= 10 &&
      startDateError == null &&
      endDateError == null &&
      reasonError == null;

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
