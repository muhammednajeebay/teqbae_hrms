import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';

abstract interface class EmployeeRepository {
  Future<Result<Employee>> getEmployee({bool forceRefresh = false});
  Stream<Employee?> watchEmployee();
}
