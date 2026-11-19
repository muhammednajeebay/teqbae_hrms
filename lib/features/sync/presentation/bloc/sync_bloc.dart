import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_service.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_event.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required SyncService syncService,
    required AttendanceRepository attendanceRepository,
    SyncState initialState = const SyncState(),
  })  : _syncService = syncService,
        _attendanceRepository = attendanceRepository,
        super(initialState) {
    on<SyncStarted>(_onStarted);
    on<SyncRequested>(_onRequested);
    on<SyncEventsUpdated>(_onEventsUpdated);
    on<SyncResultReceived>(_onResultReceived);
  }

  final SyncService _syncService;
  final AttendanceRepository _attendanceRepository;

  StreamSubscription<List<AttendanceEvent>>? _eventsSubscription;
  StreamSubscription<dynamic>? _syncResultSubscription;

  void _onStarted(SyncStarted event, Emitter<SyncState> emit) {
    _eventsSubscription?.cancel();
    _eventsSubscription = _attendanceRepository.watchAllEvents().listen((events) {
      add(SyncEventsUpdated(events));
    });

    _syncResultSubscription?.cancel();
    _syncResultSubscription = _syncService.onSyncCompleted.listen((result) {
      add(SyncResultReceived(result));
    });
  }

  Future<void> _onRequested(SyncRequested event, Emitter<SyncState> emit) async {
    if (state.isSyncing) return;

    emit(state.copyWith(
      status: SyncStatus.syncing,
      isSyncing: true,
      lastError: null,
    ));

    final result = await _syncService.syncNow(currentMonth: event.currentMonth);
    add(SyncResultReceived(result));
  }

  void _onEventsUpdated(SyncEventsUpdated event, Emitter<SyncState> emit) {
    final pendingCount = event.allEvents
        .where((e) => e.status == AttendanceEventStatus.pending)
        .length;

    emit(state.copyWith(
      allEvents: event.allEvents,
      pendingCount: pendingCount,
    ));
  }

  void _onResultReceived(SyncResultReceived event, Emitter<SyncState> emit) {
    final result = event.result;
    final isSuccess = result.failure == null;

    emit(state.copyWith(
      status: isSuccess ? SyncStatus.success : SyncStatus.failure,
      isSyncing: false,
      lastSyncTime: DateTime.now().toUtc(),
      lastError: result.failure?.message,
      pendingCount: result.pendingCount,
    ));
  }

  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    _syncResultSubscription?.cancel();
    return super.close();
  }
}
