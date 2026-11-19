import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';

/// Contract for anything that can provide employee profile data.
///
/// The domain and presentation layers use this interface so the data source
/// (real API + SQLite cache vs. fake in tests) can be swapped transparently.
abstract interface class EmployeeRepository {
  /// Returns the employee profile.
  ///
  /// - Offline: returns the locally cached profile, or a [NetworkFailure] if
  ///   no cache exists yet (first run without internet).
  /// - Online + cache hit + no force refresh: returns the cache immediately and
  ///   starts a silent background refresh.
  /// - Online + (empty cache or force refresh): fetches from the API, caches the
  ///   result, and returns it.
  Future<Result<Employee>> getEmployee({bool forceRefresh = false});

  /// A live stream of the cached employee profile from the local database.
  ///
  /// Emits a new value when the cache is updated (after a background refresh
  /// succeeds). Emits `null` before the profile has ever been cached.
  Stream<Employee?> watchEmployee();
}
