import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';

enum LeaveStatus { pending, approved, rejected }
enum LeaveType { casual, sick }

class LeaveRequest extends Equatable {
  const LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });

  final String id;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;

  @override
  List<Object?> get props => [id, type, startDate, endDate, reason, status];
}

class LeaveBalance extends Equatable {
  const LeaveBalance({
    required this.availableDays,
    required this.updatedAt,
  });

  final int availableDays;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [availableDays, updatedAt];
}

class LeaveValidator {
  const LeaveValidator();

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
    if (start.isBefore(_dateOnly(today))) {
      return const FailureResult(ValidationFailure('Start date cannot be before today.', field: 'startDate'));
    }
    if (end.isBefore(start)) {
      return const FailureResult(ValidationFailure('End date cannot be before start date.', field: 'endDate'));
    }
    if (reason.trim().length < 10) {
      return const FailureResult(ValidationFailure('Reason must contain at least 10 characters.', field: 'reason'));
    }
    if (end.difference(start).inDays + 1 > availableDays) {
      return const FailureResult(ValidationFailure('Requested days exceed your available leave balance.', field: 'endDate'));
    }
    final overlaps = existingRequests.where((request) => request.status != LeaveStatus.rejected).any(
          (request) => !start.isAfter(_dateOnly(request.endDate)) && !end.isBefore(_dateOnly(request.startDate)),
        );
    if (overlaps) {
      return const FailureResult(ValidationFailure('These dates overlap an existing leave request.', field: 'startDate'));
    }
    return const Success(null);
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
}
