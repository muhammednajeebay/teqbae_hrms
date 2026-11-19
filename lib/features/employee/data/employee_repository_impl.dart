import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/employee/domain/employee_repository.dart';

/// Concrete implementation of [EmployeeRepository].
///
/// Applies an offline-first cache strategy:
/// 1. Offline → return cached profile (or failure if no cache exists).
/// 2. Online + cache exists + no force refresh → return cache and trigger a
///    silent background refresh.
/// 3. Online + (no cache or force refresh) → fetch from API, cache, return.
class EmployeeRepositoryImpl implements EmployeeRepository {
  /// Creates an [EmployeeRepositoryImpl] with all dependencies injected.
  EmployeeRepositoryImpl({
    required RebsApi api,
    required AppDatabase database,
    required ConnectivityService connectivity,
  })  : _api = api,
        _database = database,
        _connectivity = connectivity;

  final RebsApi _api;
  final AppDatabase _database;
  final ConnectivityService _connectivity;

  /// Retrieves the employee profile using the offline-first strategy.
  ///
  /// If [forceRefresh] is `true`, always fetches from the network when online
  /// (used after the user explicitly refreshes the dashboard).
  @override
  Future<Result<Employee>> getEmployee({bool forceRefresh = false}) async {
    final cached = await _database.getCachedEmployee();
    final isOnline = await _connectivity.isOnline;

    if (!isOnline) {
      if (cached != null) {
        return Success(cached);
      }
      return const FailureResult(
          NetworkFailure('You are offline and no employee profile is cached.'));
    }

    if (!forceRefresh && cached != null) {
      // Return the cached profile immediately and refresh in the background
      // so the user is never blocked waiting for a network round-trip.
      _refreshEmployee();
      return Success(cached);
    }

    final result = await _api.getEmployee();
    if (result is Success<Employee>) {
      await _database.cacheEmployee(result.value);
      return result;
    } else if (cached != null) {
      // Network fetch failed but we have a valid cache — use it.
      return Success(cached);
    }
    return result;
  }

  /// Returns a live stream of the locally cached employee profile.
  ///
  /// Emits a new value when the cache row is inserted or updated.
  @override
  Stream<Employee?> watchEmployee() => _database.watchCachedEmployee();

  /// Fetches the latest employee profile from the API and updates the local
  /// cache silently in the background.
  ///
  /// Errors are intentionally ignored — this is a best-effort refresh. If it
  /// fails, the existing cache remains valid.
  Future<void> _refreshEmployee() async {
    final result = await _api.getEmployee();
    if (result is Success<Employee>) {
      await _database.cacheEmployee(result.value);
    }
  }
}
