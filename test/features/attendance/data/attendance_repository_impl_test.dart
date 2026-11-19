import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/attendance/data/attendance_repository_impl.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

class MockRebsApi extends Mock implements RebsApi {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase database;
  late MockRebsApi api;
  late MockConnectivityService connectivity;
  late AttendanceRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    api = MockRebsApi();
    connectivity = MockConnectivityService();
    repository = AttendanceRepositoryImpl(
      api: api,
      database: database,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('AttendanceRepositoryImpl', () {
    test('recordEvent stores pending event in database outbox', () async {
      final event = AttendanceEvent(
        clientEventId: 'evt-unique-1',
        type: AttendanceEventType.checkIn,
        occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );

      final result = await repository.recordEvent(event);
      expect(result, isA<Success<void>>());

      final pending = await repository.getPendingEvents();
      expect(pending.length, 1);
      expect(pending.first.clientEventId, 'evt-unique-1');
    });

    test('getAttendance fetches from API and caches records when online', () async {
      const records = [
        AttendanceRecord(
          companyDate: '2026-11-19',
          checkInAt: null,
          checkOutAt: null,
        ),
      ];

      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => api.attendance('2026-11')).thenAnswer((_) async => const Success(records));

      final result = await repository.getAttendance('2026-11', forceRefresh: true);
      expect(result, isA<Success<List<AttendanceRecord>>>());

      final cached = await database.attendanceForMonth('2026-11');
      expect(cached.length, 1);
    });

    test('getAttendance returns cached records when offline', () async {
      await database.replaceAttendanceRecords([
        const AttendanceRecord(
          companyDate: '2026-11-18',
          checkInAt: null,
          checkOutAt: null,
        ),
      ]);

      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      final result = await repository.getAttendance('2026-11');
      expect(result, isA<Success<List<AttendanceRecord>>>());
      expect((result as Success<List<AttendanceRecord>>).value.length, 1);
      verifyZeroInteractions(api);
    });

    test('updateEventStatus updates status in database', () async {
      final event = AttendanceEvent(
        clientEventId: 'evt-update-test',
        type: AttendanceEventType.checkIn,
        occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );
      await repository.recordEvent(event);

      await repository.updateEventStatus(
        clientEventId: 'evt-update-test',
        status: AttendanceEventStatus.synced,
      );

      final pending = await repository.getPendingEvents();
      expect(pending, isEmpty);
    });
  });
}
