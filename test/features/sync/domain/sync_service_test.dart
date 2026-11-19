import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/attendance/data/attendance_repository_impl.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_api_client.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_service.dart';

class MockSyncApiClient extends Mock implements SyncApiClient {}
class MockRebsApi extends Mock implements RebsApi {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase database;
  late AttendanceRepository repository;
  late MockSyncApiClient apiClient;
  late MockConnectivityService connectivity;
  late SyncService syncService;

  setUpAll(() {
    registerFallbackValue(AttendanceEvent(
      clientEventId: 'fallback',
      type: AttendanceEventType.checkIn,
      occurredAt: DateTime.utc(2026, 11, 19),
      companyDate: '2026-11-19',
      latitude: 9.9312,
      longitude: 76.2673,
      status: AttendanceEventStatus.pending,
    ));
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    connectivity = MockConnectivityService();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.onStatusChanged).thenAnswer((_) => const Stream.empty());

    final dummyApi = MockRebsApi();
    repository = AttendanceRepositoryImpl(
      api: dummyApi,
      database: database,
      connectivity: connectivity,
    );

    apiClient = MockSyncApiClient();
    syncService = SyncService(
      attendanceRepository: repository,
      apiClient: apiClient,
      connectivityService: connectivity,
    );
  });

  tearDown(() async {
    syncService.dispose();
    await database.close();
  });

  group('SyncService - Core Invariant Tests (Required by Assignment)', () {
    test('1. Retry does not create a duplicate: same ID sent twice returns synced and avoids duplicate', () async {
      final event = AttendanceEvent(
        clientEventId: 'evt-retry-1',
        type: AttendanceEventType.checkIn,
        occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );
      await repository.recordEvent(event);

      // Server returns 200 OK duplicate: true (Success(true) in domain)
      when(() => apiClient.postAttendanceEvent(any()))
          .thenAnswer((_) async => const Success(true));

      final result1 = await syncService.syncNow();
      expect(result1.syncedCount, 1);
      expect(result1.pendingCount, 0);

      // Verify status in DB is synced
      final all = await repository.getAllEvents();
      expect(all.first.status, AttendanceEventStatus.synced);

      // Subsequent sync does not re-send
      final result2 = await syncService.syncNow();
      expect(result2.syncedCount, 0);
      expect(result2.pendingCount, 0);
      verify(() => apiClient.postAttendanceEvent(any())).called(1);
    });

    test('2. Pending events survive persistence and restart', () async {
      final event = AttendanceEvent(
        clientEventId: 'evt-survive-restart',
        type: AttendanceEventType.checkIn,
        occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );
      await repository.recordEvent(event);

      // Simulate app restart by creating a new repository instance pointing to the same database
      final restartedRepo = AttendanceRepositoryImpl(
        api: MockRebsApi(),
        database: database,
        connectivity: connectivity,
      );

      final pending = await restartedRepo.getPendingEvents();
      expect(pending.length, 1);
      expect(pending.first.clientEventId, 'evt-survive-restart');
      expect(pending.first.status, AttendanceEventStatus.pending);
    });

    test('3. Pending events are synced in sequence order: check-in first, then check-out', () async {
      final checkIn = AttendanceEvent(
        clientEventId: 'evt-in',
        type: AttendanceEventType.checkIn,
        occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );
      final checkOut = AttendanceEvent(
        clientEventId: 'evt-out',
        type: AttendanceEventType.checkOut,
        occurredAt: DateTime.utc(2026, 11, 19, 17, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );

      await repository.recordEvent(checkIn);
      await repository.recordEvent(checkOut);

      final callOrder = <String>[];
      when(() => apiClient.postAttendanceEvent(any())).thenAnswer((invocation) async {
        final evt = invocation.positionalArguments.first as AttendanceEvent;
        callOrder.add(evt.clientEventId);
        return const Success(true);
      });

      final result = await syncService.syncNow();
      expect(result.syncedCount, 2);
      expect(callOrder, ['evt-in', 'evt-out']);
    });

    test('4. Timeout after server accepted -> retry -> treated as Synced, not Rejected', () async {
      final event = AttendanceEvent(
        clientEventId: 'evt-timeout-accepted',
        type: AttendanceEventType.checkIn,
        occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );
      await repository.recordEvent(event);

      // First call times out
      when(() => apiClient.postAttendanceEvent(any()))
          .thenAnswer((_) async => const FailureResult(NetworkFailure('Connection timed out.')));

      final firstSync = await syncService.syncNow();
      expect(firstSync.syncedCount, 0);
      expect(firstSync.pendingCount, 1);

      // On retry, server had already accepted it, so it returns duplicate: true (Success)
      when(() => apiClient.postAttendanceEvent(any()))
          .thenAnswer((_) async => const Success(true));

      final secondSync = await syncService.syncNow();
      expect(secondSync.syncedCount, 1);
      expect(secondSync.pendingCount, 0);

      final all = await repository.getAllEvents();
      expect(all.first.status, AttendanceEventStatus.synced);
    });

    test('5. Rejected check-in automatically marks dependent check-out as Rejected too', () async {
      final checkIn = AttendanceEvent(
        clientEventId: 'evt-check-in-fail',
        type: AttendanceEventType.checkIn,
        occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );
      final checkOut = AttendanceEvent(
        clientEventId: 'evt-check-out-dependent',
        type: AttendanceEventType.checkOut,
        occurredAt: DateTime.utc(2026, 11, 19, 17, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );

      await repository.recordEvent(checkIn);
      await repository.recordEvent(checkOut);

      // Check-in receives business rejection (409 conflict or 422 rule violation)
      when(() => apiClient.postAttendanceEvent(any())).thenAnswer((invocation) async {
        final evt = invocation.positionalArguments.first as AttendanceEvent;
        if (evt.clientEventId == 'evt-check-in-fail') {
          return const FailureResult(ServerFailure('Already checked in on another device.', statusCode: 409));
        }
        return const Success(true);
      });

      final result = await syncService.syncNow();
      expect(result.syncedCount, 0);
      expect(result.rejectedCount, 2);
      expect(result.pendingCount, 0);

      final all = await repository.getAllEvents();
      final inEvent = all.firstWhere((e) => e.clientEventId == 'evt-check-in-fail');
      final outEvent = all.firstWhere((e) => e.clientEventId == 'evt-check-out-dependent');

      expect(inEvent.status, AttendanceEventStatus.rejected);
      expect(outEvent.status, AttendanceEventStatus.rejected);
      expect(outEvent.lastError, 'Depends on a rejected check-in.');
    });
  });
}
