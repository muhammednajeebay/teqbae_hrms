import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/leave/data/leave_repository_impl.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

class MockRebsApi extends Mock implements RebsApi {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase database;
  late MockRebsApi api;
  late MockConnectivityService connectivity;
  late LeaveRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    api = MockRebsApi();
    connectivity = MockConnectivityService();
    repository = LeaveRepositoryImpl(
      api: api,
      database: database,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('LeaveRepositoryImpl', () {
    test('getBalance returns cached balance when offline', () async {
      final balance = LeaveBalance(availableDays: 10, updatedAt: DateTime.utc(2026, 11, 19));
      await database.cacheLeaveBalance(balance);

      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      final result = await repository.getBalance();
      expect(result, isA<Success<LeaveBalance>>());
      expect((result as Success<LeaveBalance>).value.availableDays, 10);
      verifyZeroInteractions(api);
    });

    test('getRequests caches requests from API when online', () async {
      final requests = [
        LeaveRequest(
          id: 'leave-100',
          type: LeaveType.casual,
          startDate: DateTime.utc(2026, 12, 1),
          endDate: DateTime.utc(2026, 12, 2),
          reason: 'Personal work vacation',
          status: LeaveStatus.pending,
        ),
      ];

      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => api.getLeaveRequests()).thenAnswer((_) async => Success(requests));

      final result = await repository.getRequests(forceRefresh: true);
      expect(result, isA<Success<List<LeaveRequest>>>());

      final cached = await database.getCachedLeaveRequests();
      expect(cached.length, 1);
      expect(cached.first.id, 'leave-100');
    });

    test('applyLeave blocks submission when offline', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      final result = await repository.applyLeave(
        type: LeaveType.casual,
        startDate: DateTime.utc(2026, 12, 1),
        endDate: DateTime.utc(2026, 12, 2),
        reason: 'Personal time off for rest',
      );

      expect(result, isA<FailureResult<LeaveRequest>>());
      expect((result as FailureResult<LeaveRequest>).failure, isA<NetworkFailure>());
      verifyZeroInteractions(api);
    });
  });
}
