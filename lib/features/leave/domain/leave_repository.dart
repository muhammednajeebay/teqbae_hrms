import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

/// Contract for anything that can provide leave balance and request data.
///
/// Domain and presentation code depends on this interface, not on the concrete
/// implementation, so the data layer is swappable in tests.
abstract interface class LeaveRepository {
  /// Returns the employee's current leave balance.
  ///
  /// - Offline + cache exists → returns cached balance.
  /// - Offline + no cache → returns a [NetworkFailure].
  /// - Online + cache + no force refresh → returns cache, refreshes silently.
  /// - Online + (no cache or force refresh) → fetches from API and caches.
  Future<Result<LeaveBalance>> getBalance({bool forceRefresh = false});

  /// A live stream of the cached leave balance from the local database.
  ///
  /// Emits `null` before the balance has ever been fetched.
  Stream<LeaveBalance?> watchBalance();

  /// Returns the list of all leave requests submitted by the employee.
  ///
  /// Uses the same offline-first caching strategy as [getBalance].
  Future<Result<List<LeaveRequest>>> getRequests({bool forceRefresh = false});

  /// A live stream of cached leave requests. Emits a new list whenever the
  /// local cache is updated.
  Stream<List<LeaveRequest>> watchRequests();

  /// Submits a new leave request to the server.
  ///
  /// Requires an active internet connection (Decision D21). Returns a
  /// [NetworkFailure] immediately if the device is offline rather than queuing
  /// the request for later.
  ///
  /// On success, automatically refreshes the local cache for both requests
  /// and balance in the background.
  Future<Result<LeaveRequest>> applyLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  });
}
