import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_result.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_service.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_event.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_state.dart';

class MockSyncService extends Mock implements SyncService {}
class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockSyncService syncService;
  late MockAttendanceRepository attendanceRepository;

  setUp(() {
    syncService = MockSyncService();
    attendanceRepository = MockAttendanceRepository();
    when(() => attendanceRepository.watchAllEvents()).thenAnswer((_) => const Stream.empty());
    when(() => syncService.onSyncCompleted).thenAnswer((_) => const Stream.empty());
  });

  group('SyncBloc', () {
    blocTest<SyncBloc, SyncState>(
      'emits updated pending count when allEvents stream updates',
      build: () => SyncBloc(
        syncService: syncService,
        attendanceRepository: attendanceRepository,
      ),
      act: (bloc) => bloc.add(SyncEventsUpdated([
        AttendanceEvent(
          clientEventId: 'evt-1',
          type: AttendanceEventType.checkIn,
          occurredAt: DateTime.utc(2026, 11, 19),
          companyDate: '2026-11-19',
          latitude: 9.9312,
          longitude: 76.2673,
          status: AttendanceEventStatus.pending,
        ),
      ])),
      expect: () => [
        predicate<SyncState>((state) => state.pendingCount == 1 && state.allEvents.length == 1),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'emits syncing state and then success on SyncRequested',
      build: () {
        when(() => syncService.syncNow(currentMonth: any(named: 'currentMonth'))).thenAnswer(
          (_) async => const SyncResult(syncedCount: 1, rejectedCount: 0, pendingCount: 0),
        );
        return SyncBloc(
          syncService: syncService,
          attendanceRepository: attendanceRepository,
        );
      },
      act: (bloc) => bloc.add(const SyncRequested()),
      expect: () => [
        predicate<SyncState>((state) => state.isSyncing == true && state.status == SyncStatus.syncing),
        predicate<SyncState>((state) => state.isSyncing == false && state.status == SyncStatus.success),
      ],
    );
  });
}
