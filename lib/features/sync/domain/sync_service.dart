import 'dart:async';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_api_client.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_result.dart';

/// Core offline-outbox synchronisation service.
///
/// [SyncService] is a plain Dart class with no Flutter or Drift imports. Its
/// single responsibility is to drain the pending-event outbox and send each
/// event to the server in strict order.
///
/// ## Invariants
///
/// 1. **Single-lock:** Only one sync run can be active at a time. Calling
///    [syncNow] while a run is in progress returns immediately with the current
///    pending count.
/// 2. **Oldest-first ordering:** Events are fetched from the repository ordered
///    by autoincrement sequence, so a check-in always reaches the server before
///    its paired check-out.
/// 3. **Idempotent retries:** Each event carries a UUID (`clientEventId`) that
///    never changes. The server uses this ID to detect and silently ignore
///    duplicates, so the same event can be sent multiple times safely.
/// 4. **Dependent-event rejection:** If a check-in event is permanently
///    rejected (HTTP 409 / 422), any pending check-out for the same
///    `companyDate` is immediately marked as rejected locally without sending
///    an invalid request to the server (Decision D9).
/// 5. **Stop on network failure:** If a timeout, connection error, or 5xx
///    response is received, the sync run stops immediately. The failed event
///    stays pending and will be retried on the next run. This prevents a later
///    event from being sent before an earlier one succeeds.
/// 6. **Auto-sync on reconnect:** If [connectivityService] is provided,
///    [SyncService] automatically calls [syncNow] whenever the device comes
///    online.
class SyncService {
  /// Creates a [SyncService].
  ///
  /// [connectivityService] is optional so the service can be created without
  /// auto-reconnect in tests.
  SyncService({
    required AttendanceRepository attendanceRepository,
    required SyncApiClient apiClient,
    ConnectivityService? connectivityService,
  })  : _attendanceRepository = attendanceRepository,
        _apiClient = apiClient,
        _connectivityService = connectivityService {
    _initConnectivityListener();
  }

  final AttendanceRepository _attendanceRepository;
  final SyncApiClient _apiClient;
  final ConnectivityService? _connectivityService;

  /// Subscription to connectivity changes. Automatically cancelled in [dispose].
  StreamSubscription<bool>? _connectivitySubscription;

  /// Broadcast stream that emits a [SyncResult] after each sync run finishes.
  /// [SyncBloc] listens to this to update the UI.
  final _syncResultController = StreamController<SyncResult>.broadcast();

  /// `true` while a sync run is active. Used as an async mutex.
  bool _isSyncing = false;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// A broadcast stream that emits a [SyncResult] each time [syncNow] finishes.
  Stream<SyncResult> get onSyncCompleted => _syncResultController.stream;

  /// Subscribes to [ConnectivityService.onStatusChanged] and calls [syncNow]
  /// each time the device transitions from offline to online.
  void _initConnectivityListener() {
    _connectivitySubscription =
        _connectivityService?.onStatusChanged.listen((isOnline) {
      if (isOnline) {
        syncNow();
      }
    });
  }

  /// Sends all pending outbox events to the server, one at a time.
  ///
  /// - If a sync is already running, returns a [SyncResult] with the current
  ///   pending count without starting a second run.
  /// - If the outbox is empty, publishes an all-zero [SyncResult] immediately.
  /// - After syncing, if [currentMonth] is supplied and at least one event was
  ///   synced, refreshes the attendance records for that month from the server.
  ///
  /// Returns the [SyncResult] describing what happened during this run.
  Future<SyncResult> syncNow({String? currentMonth}) async {
    // Guard: allow only one concurrent sync.
    if (_isSyncing) {
      final pendingCount =
          (await _attendanceRepository.getPendingEvents()).length;
      return SyncResult(
        syncedCount: 0,
        rejectedCount: 0,
        pendingCount: pendingCount,
      );
    }

    _isSyncing = true;
    var syncedCount = 0;
    var rejectedCount = 0;
    Failure? syncFailure;

    try {
      final pendingEvents = await _attendanceRepository.getPendingEvents();

      // Nothing to do — broadcast a clean result and return.
      if (pendingEvents.isEmpty) {
        final result = const SyncResult(
          syncedCount: 0,
          rejectedCount: 0,
          pendingCount: 0,
        );
        _syncResultController.add(result);
        return result;
      }

      // Tracks client IDs of events that have already been rejected (or whose
      // parent check-in was rejected). We skip them in later loop iterations.
      final rejectedIds = <String>{};

      for (var i = 0; i < pendingEvents.length; i++) {
        final event = pendingEvents[i];

        // Skip events that were already handled (cascading rejection).
        if (rejectedIds.contains(event.clientEventId)) {
          continue;
        }

        final result = await _apiClient.postAttendanceEvent(event);

        if (result is Success<bool>) {
          // HTTP 200 (duplicate) or 201 (new) — mark as synced.
          await _attendanceRepository.updateEventStatus(
            clientEventId: event.clientEventId,
            status: AttendanceEventStatus.synced,
            attempts: event.attempts + 1,
            error: null,
          );
          syncedCount++;
        } else if (result is FailureResult<bool>) {
          final failure = result.failure;

          if (_isBusinessRejection(failure)) {
            // HTTP 409 / 422 or known error codes — permanent rejection.
            await _attendanceRepository.updateEventStatus(
              clientEventId: event.clientEventId,
              status: AttendanceEventStatus.rejected,
              error: failure.message,
              attempts: event.attempts + 1,
            );
            rejectedCount++;
            rejectedIds.add(event.clientEventId);

            // Decision D9: If the rejected event is a check-in, immediately
            // reject any pending check-out for the same day so it is never sent
            // to the server in an invalid state.
            if (event.type == AttendanceEventType.checkIn) {
              for (var j = i + 1; j < pendingEvents.length; j++) {
                final dependentCandidate = pendingEvents[j];
                if (dependentCandidate.companyDate == event.companyDate &&
                    dependentCandidate.type == AttendanceEventType.checkOut) {
                  await _attendanceRepository.updateEventStatus(
                    clientEventId: dependentCandidate.clientEventId,
                    status: AttendanceEventStatus.rejected,
                    error: 'Depends on a rejected check-in.',
                    attempts: dependentCandidate.attempts,
                  );
                  rejectedIds.add(dependentCandidate.clientEventId);
                  rejectedCount++;
                }
              }
            }
          } else {
            // Network failure, timeout, or 5xx — keep this event as Pending
            // and stop the loop so we don't send later events out of order.
            await _attendanceRepository.updateEventStatus(
              clientEventId: event.clientEventId,
              status: AttendanceEventStatus.pending,
              error: failure.message,
              attempts: event.attempts + 1,
            );
            syncFailure = failure;
            break;
          }
        }
      }

      // If anything synced successfully, refresh the month's attendance records
      // from the server so the dashboard shows up-to-date history.
      if (syncedCount > 0 && currentMonth != null) {
        await _attendanceRepository.getAttendance(currentMonth,
            forceRefresh: true);
      }

      final remainingPending =
          (await _attendanceRepository.getPendingEvents()).length;
      final finalResult = SyncResult(
        syncedCount: syncedCount,
        rejectedCount: rejectedCount,
        pendingCount: remainingPending,
        failure: syncFailure,
      );
      _syncResultController.add(finalResult);
      return finalResult;
    } finally {
      // Always release the lock, even if an unexpected exception is thrown.
      _isSyncing = false;
    }
  }

  /// Returns `true` if the [failure] represents a permanent business rejection
  /// that should not be retried.
  ///
  /// - HTTP 409 Conflict (duplicate event already processed under a different ID).
  /// - HTTP 422 Unprocessable (business rule violation: wrong order, outside
  ///   radius, invalid event type).
  /// - Known server error codes: `ALREADY_EXISTS`, `INVALID_ORDER`,
  ///   `OUTSIDE_RADIUS`, `INVALID_EVENT`.
  ///
  /// Network errors and 5xx responses return `false` — they should be retried.
  bool _isBusinessRejection(Failure failure) {
    if (failure is ServerFailure) {
      final status = failure.statusCode;
      final code = failure.code;
      if (status == 409 || status == 422) return true;
      if (code == 'ALREADY_EXISTS' ||
          code == 'INVALID_ORDER' ||
          code == 'OUTSIDE_RADIUS' ||
          code == 'INVALID_EVENT') {
        return true;
      }
    }
    return false;
  }

  /// Cancels the connectivity subscription and closes the result stream.
  ///
  /// Call this when the app is shutting down. After calling [dispose],
  /// [syncNow] must not be called again.
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncResultController.close();
  }
}
