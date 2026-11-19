import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/employee/domain/employee_repository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
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

  @override
  Future<Result<Employee>> getEmployee({bool forceRefresh = false}) async {
    final cached = await _database.getCachedEmployee();
    final isOnline = await _connectivity.isOnline;

    if (!isOnline) {
      if (cached != null) {
        return Success(cached);
      }
      return const FailureResult(NetworkFailure('You are offline and no employee profile is cached.'));
    }

    if (!forceRefresh && cached != null) {
      // Background refresh
      _refreshEmployee();
      return Success(cached);
    }

    final result = await _api.getEmployee();
    if (result is Success<Employee>) {
      await _database.cacheEmployee(result.value);
      return result;
    } else if (cached != null) {
      return Success(cached);
    }
    return result;
  }

  @override
  Stream<Employee?> watchEmployee() => _database.watchCachedEmployee();

  Future<void> _refreshEmployee() async {
    final result = await _api.getEmployee();
    if (result is Success<Employee>) {
      await _database.cacheEmployee(result.value);
    }
  }
}
