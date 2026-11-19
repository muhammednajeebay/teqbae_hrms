import 'package:flutter_test/flutter_test.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

void main() {
  const validator = LeaveValidator();
  final today = DateTime(2026, 11, 19);

  test('start date before today is rejected', () {
    final result = validator.validate(
      today: today,
      startDate: DateTime(2026, 11, 18),
      endDate: DateTime(2026, 11, 20),
      reason: 'Doctor appointment consultation',
      availableDays: 12,
      existingRequests: const [],
    );
    expect(result, isA<FailureResult<void>>());
  });

  test('end date before start date is rejected', () {
    final result = validator.validate(
      today: today,
      startDate: DateTime(2026, 11, 22),
      endDate: DateTime(2026, 11, 21),
      reason: 'Family travel arrangement',
      availableDays: 12,
      existingRequests: const [],
    );
    expect(result, isA<FailureResult<void>>());
  });

  test('overlapping pending leave is rejected', () {
    final result = validator.validate(
      today: today,
      startDate: DateTime(2026, 11, 22),
      endDate: DateTime(2026, 11, 23),
      reason: 'Family travel arrangement',
      availableDays: 12,
      existingRequests: [
        request(LeaveStatus.pending, DateTime(2026, 11, 21), DateTime(2026, 11, 24)),
      ],
    );
    expect(result, isA<FailureResult<void>>());
  });

  test('overlapping approved leave is rejected', () {
    final result = validator.validate(
      today: today,
      startDate: DateTime(2026, 11, 22),
      endDate: DateTime(2026, 11, 23),
      reason: 'Family travel arrangement',
      availableDays: 12,
      existingRequests: [
        request(LeaveStatus.approved, DateTime(2026, 11, 21), DateTime(2026, 11, 24)),
      ],
    );
    expect(result, isA<FailureResult<void>>());
  });

  test('rejected leave does not block the same dates', () {
    final result = validator.validate(
      today: today,
      startDate: DateTime(2026, 11, 22),
      endDate: DateTime(2026, 11, 22),
      reason: 'Personal work appointment',
      availableDays: 12,
      existingRequests: [
        request(LeaveStatus.rejected, DateTime(2026, 11, 22), DateTime(2026, 11, 22)),
      ],
    );
    expect(result, isA<Success<void>>());
  });

  test('rejects short reasons and balance overrun', () {
    final shortReason = validator.validate(
      today: today,
      startDate: DateTime(2026, 11, 25),
      endDate: DateTime(2026, 11, 25),
      reason: 'short',
      availableDays: 12,
      existingRequests: const [],
    );
    final balanceOverrun = validator.validate(
      today: today,
      startDate: DateTime(2026, 11, 25),
      endDate: DateTime(2026, 11, 27),
      reason: 'Three days of personal work',
      availableDays: 2,
      existingRequests: const [],
    );
    expect(shortReason, isA<FailureResult<void>>());
    expect(balanceOverrun, isA<FailureResult<void>>());
  });
}

LeaveRequest request(LeaveStatus status, DateTime start, DateTime end) => LeaveRequest(
      id: status.name,
      type: LeaveType.casual,
      startDate: start,
      endDate: end,
      reason: 'Existing leave request',
      status: status,
    );
