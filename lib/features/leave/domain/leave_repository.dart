import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

abstract interface class LeaveRepository {
  Future<Result<LeaveBalance>> getBalance({bool forceRefresh = false});
  Stream<LeaveBalance?> watchBalance();
  Future<Result<List<LeaveRequest>>> getRequests({bool forceRefresh = false});
  Stream<List<LeaveRequest>> watchRequests();
  Future<Result<LeaveRequest>> applyLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  });
}
