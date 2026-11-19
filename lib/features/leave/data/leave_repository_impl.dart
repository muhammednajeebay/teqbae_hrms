import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';

/// Concrete implementation of [LeaveRepository].
///
/// Leave **reads** (balance and request list) use the same offline-first cache
/// strategy as the attendance and employee repositories.
///
/// Leave **writes** (submitting a new request) always require internet
/// connectivity — there is no offline outbox for leave (Decision D21). The
/// decision was made to keep the complexity budget low; leave submission is not
/// a time-critical action unlike attendance check-in/out.
class LeaveRepositoryImpl implements LeaveRepository {
  /// Creates a [LeaveRepositoryImpl] with all dependencies injected.
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

  /// Fetches the leave balance using the offline-first strategy.
  ///
  /// - Offline + no cache → [NetworkFailure] (the user must connect first).
  /// - Offline + cache → returns cached balance with no network call.
  /// - Online + cache + no force refresh → returns cache immediately and
  ///   triggers a silent background refresh.
  /// - Online + (no cache or force refresh) → fetches from API and caches.
  @override
  Future<Result<LeaveBalance>> getBalance({bool forceRefresh = false}) async {
    final cached = await _database.getCachedLeaveBalance();
    final isOnline = await _connectivity.isOnline;

    if (!isOnline) {
      if (cached != null) {
        return Success(cached);
      }
      return const FailureResult(
          NetworkFailure('You are offline and no leave balance is cached.'));
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

  /// A live stream of the cached leave balance from the local database.
  @override
  Stream<LeaveBalance?> watchBalance() => _database.watchLeaveBalance();

  /// Fetches the list of leave requests using the offline-first strategy.
  ///
  /// Returns a cached list offline. Triggers a silent background refresh when
  /// online and the cache is not empty (unless forced).
  @override
  Future<Result<List<LeaveRequest>>> getRequests(
      {bool forceRefresh = false}) async {
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

  /// A live stream of cached leave requests from the local database.
  @override
  Stream<List<LeaveRequest>> watchRequests() => _database.watchLeaveRequests();

  /// Submits a new leave request to the server.
  ///
  /// Returns a [NetworkFailure] immediately if the device is offline.
  /// On success, refreshes both the request list and the leave balance in the
  /// background so the UI reflects the updated data without a manual pull.
  @override
  Future<Result<LeaveRequest>> applyLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final isOnline = await _connectivity.isOnline;
    if (!isOnline) {
      return const FailureResult(NetworkFailure(
          'Internet connection is required to submit leave requests.'));
    }

    final result = await _api.postLeaveRequest(
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );

    if (result is Success<LeaveRequest>) {
      // Refresh both cached datasets silently so the leave list and balance
      // display update without requiring the user to pull-to-refresh.
      _refreshRequests();
      _refreshBalance();
    }
    return result;
  }

  /// Fetches the latest leave balance from the API and updates the local cache.
  ///
  /// Errors are silently swallowed — this is a best-effort background refresh.
  Future<void> _refreshBalance() async {
    final result = await _api.getLeaveBalance();
    if (result is Success<LeaveBalance>) {
      await _database.cacheLeaveBalance(result.value);
    }
  }

  /// Fetches the latest list of leave requests and replaces the local cache.
  ///
  /// Errors are silently swallowed — this is a best-effort background refresh.
  Future<void> _refreshRequests() async {
    final result = await _api.getLeaveRequests();
    if (result is Success<List<LeaveRequest>>) {
      await _database.replaceLeaveRequests(result.value);
    }
  }
}
