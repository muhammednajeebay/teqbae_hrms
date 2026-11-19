import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/employee/data/employee_repository_impl.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

class MockRebsApi extends Mock implements RebsApi {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase database;
  late MockRebsApi api;
  late MockConnectivityService connectivity;
  late EmployeeRepositoryImpl repository;

  const testEmployee = Employee(
    id: 'EMP-001',
    name: 'Ananya Nair',
    department: 'Operations',
    officeLocation: OfficeConfig(
      latitude: 9.9312,
      longitude: 76.2673,
      radiusMeters: 200,
    ),
    companyTimeZone: 'Asia/Kolkata',
  );

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    api = MockRebsApi();
    connectivity = MockConnectivityService();
    repository = EmployeeRepositoryImpl(
      api: api,
      database: database,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('EmployeeRepositoryImpl', () {
    test('fetches from API and caches locally when online', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => api.getEmployee()).thenAnswer((_) async => const Success(testEmployee));

      final result = await repository.getEmployee(forceRefresh: true);

      expect(result, isA<Success<Employee>>());
      expect((result as Success<Employee>).value.name, 'Ananya Nair');

      final cached = await database.getCachedEmployee();
      expect(cached?.name, 'Ananya Nair');
    });

    test('returns cached employee when offline', () async {
      await database.cacheEmployee(testEmployee);

      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      final result = await repository.getEmployee();

      expect(result, isA<Success<Employee>>());
      expect((result as Success<Employee>).value.id, 'EMP-001');
      verifyZeroInteractions(api);
    });

    test('returns failure when offline and cache is empty', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      final result = await repository.getEmployee();

      expect(result, isA<FailureResult<Employee>>());
      expect((result as FailureResult<Employee>).failure, isA<NetworkFailure>());
    });
  });
}
