import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_service.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_event.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_state.dart';

/// Bridges [SyncService] (a pure Dart service) with the Flutter widget tree.
///
/// [SyncBloc] does not perform any sync logic itself — it delegates to
/// [SyncService] and translates its async results into [SyncState] changes
/// that the UI can react to.
///
/// Event flow:
/// - [SyncStarted] → subscribe to outbox stream and sync-result stream.
/// - [SyncRequested] → call [SyncService.syncNow] and emit syncing/idle states.
/// - [SyncEventsUpdated] → update [SyncState.allEvents] and pending count.
/// - [SyncResultReceived] → update status/error/timestamp after a sync run.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  /// Creates a [SyncBloc].
  ///
  /// [initialState] can be supplied in tests to start the BLoC in a specific
  /// state without running any real async work.
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

  /// Subscription to the all-events database stream.
  StreamSubscription<List<AttendanceEvent>>? _eventsSubscription;

  /// Subscription to sync-result notifications from [SyncService].
  StreamSubscription<dynamic>? _syncResultSubscription;

  /// Sets up the two reactive subscriptions that keep [SyncState] up to date.
  ///
  /// - Any change to the local event database (insert, update) triggers
  ///   [SyncEventsUpdated] with the full new list.
  /// - Each time [SyncService] completes a sync run it broadcasts a [SyncResult],
  ///   which we re-dispatch as [SyncResultReceived].
  void _onStarted(SyncStarted event, Emitter<SyncState> emit) {
    _eventsSubscription?.cancel();
    _eventsSubscription =
        _attendanceRepository.watchAllEvents().listen((events) {
      add(SyncEventsUpdated(events));
    });

    _syncResultSubscription?.cancel();
    _syncResultSubscription = _syncService.onSyncCompleted.listen((result) {
      add(SyncResultReceived(result));
    });
  }

  /// Runs a sync now if one is not already in progress.
  ///
  /// Emits [SyncStatus.syncing] immediately so the UI can show a loading state,
  /// then hands off to [SyncService.syncNow] and dispatches the result as a
  /// [SyncResultReceived] event.
  Future<void> _onRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (state.isSyncing) return;

    emit(state.copyWith(
      status: SyncStatus.syncing,
      isSyncing: true,
      lastError: null, // clear previous error while syncing
    ));

    final result = await _syncService.syncNow(currentMonth: event.currentMonth);
    add(SyncResultReceived(result));
  }

  /// Updates [SyncState.allEvents] and recalculates the pending count whenever
  /// the outbox database changes.
  void _onEventsUpdated(
    SyncEventsUpdated event,
    Emitter<SyncState> emit,
  ) {
    final pendingCount = event.allEvents
        .where((e) => e.status == AttendanceEventStatus.pending)
        .length;

    emit(state.copyWith(
      allEvents: event.allEvents,
      pendingCount: pendingCount,
    ));
  }

  /// Updates status, timestamp, and error after a sync run completes.
  ///
  /// A sync is considered successful if [SyncResult.failure] is `null`
  /// (network errors, 5xx responses, and timeouts all set a failure).
  void _onResultReceived(
    SyncResultReceived event,
    Emitter<SyncState> emit,
  ) {
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

  /// Cancels both stream subscriptions when the BLoC is closed.
  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    _syncResultSubscription?.cancel();
    return super.close();
  }
}
