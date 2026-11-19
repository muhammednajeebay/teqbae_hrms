import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  LeaveRepositoryImpl({
    required RebsApi api,
    required AppDatabase database,
    required ConnectivityService connectivity,
  })  : _api = api,
        _database = database,
        _connectivity = connectivity;

  final RebsApi _api;
  final AppDatabase _database;
  final ConnectivityService _connectivity;

  @override
  Future<Result<LeaveBalance>> getBalance({bool forceRefresh = false}) async {
    final cached = await _database.getCachedLeaveBalance();
    final isOnline = await _connectivity.isOnline;

    if (!isOnline) {
      if (cached != null) {
        return Success(cached);
      }
      return const FailureResult(NetworkFailure('You are offline and no leave balance is cached.'));
    }

    if (!forceRefresh && cached != null) {
      _refreshBalance();
      return Success(cached);
    }

    final result = await _api.getLeaveBalance();
    if (result is Success<LeaveBalance>) {
      await _database.cacheLeaveBalance(result.value);
      return result;
    } else if (cached != null) {
      return Success(cached);
    }
    return result;
  }

  @override
  Stream<LeaveBalance?> watchBalance() => _database.watchLeaveBalance();

  @override
  Future<Result<List<LeaveRequest>>> getRequests({bool forceRefresh = false}) async {
    final cached = await _database.getCachedLeaveRequests();
    final isOnline = await _connectivity.isOnline;

    if (!isOnline) {
      return Success(cached);
    }

    if (!forceRefresh && cached.isNotEmpty) {
      _refreshRequests();
      return Success(cached);
    }

    final result = await _api.getLeaveRequests();
    if (result is Success<List<LeaveRequest>>) {
      await _database.replaceLeaveRequests(result.value);
      return result;
    } else if (cached.isNotEmpty) {
      return Success(cached);
    }
    return result;
  }

  @override
  Stream<List<LeaveRequest>> watchRequests() => _database.watchLeaveRequests();

  @override
  Future<Result<LeaveRequest>> applyLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final isOnline = await _connectivity.isOnline;
    if (!isOnline) {
      return const FailureResult(NetworkFailure('Internet connection is required to submit leave requests.'));
    }

    final result = await _api.postLeaveRequest(
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );

    if (result is Success<LeaveRequest>) {
      // Refresh cached requests & balance after submitting
      _refreshRequests();
      _refreshBalance();
    }
    return result;
  }

  Future<void> _refreshBalance() async {
    final result = await _api.getLeaveBalance();
    if (result is Success<LeaveBalance>) {
      await _database.cacheLeaveBalance(result.value);
    }
  }

  Future<void> _refreshRequests() async {
    final result = await _api.getLeaveRequests();
    if (result is Success<List<LeaveRequest>>) {
      await _database.replaceLeaveRequests(result.value);
    }
  }
}
