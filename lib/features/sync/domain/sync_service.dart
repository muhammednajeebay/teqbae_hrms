import 'dart:async';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_api_client.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_result.dart';

class SyncService {
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

  StreamSubscription<bool>? _connectivitySubscription;
  final _syncResultController = StreamController<SyncResult>.broadcast();
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;
  Stream<SyncResult> get onSyncCompleted => _syncResultController.stream;

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivityService?.onStatusChanged.listen((isOnline) {
      if (isOnline) {
        syncNow();
      }
    });
  }

  Future<SyncResult> syncNow({String? currentMonth}) async {
    if (_isSyncing) {
      final pendingCount = (await _attendanceRepository.getPendingEvents()).length;
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
      if (pendingEvents.isEmpty) {
        final result = const SyncResult(
          syncedCount: 0,
          rejectedCount: 0,
          pendingCount: 0,
        );
        _syncResultController.add(result);
        return result;
      }

      final rejectedIds = <String>{};

      for (var i = 0; i < pendingEvents.length; i++) {
        final event = pendingEvents[i];

        if (rejectedIds.contains(event.clientEventId)) {
          continue;
        }

        final result = await _apiClient.postAttendanceEvent(event);

        if (result is Success<bool>) {
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
            await _attendanceRepository.updateEventStatus(
              clientEventId: event.clientEventId,
              status: AttendanceEventStatus.rejected,
              error: failure.message,
              attempts: event.attempts + 1,
            );
            rejectedCount++;
            rejectedIds.add(event.clientEventId);

            // Decision D9: If a check-in is rejected, mark any dependent check-out as rejected
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
            // Network failure, timeout, 5xx server error -> keep Pending, increment attempts, record error and stop loop.
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

      // If any events were successfully synced, refresh month attendance records
      if (syncedCount > 0 && currentMonth != null) {
        await _attendanceRepository.getAttendance(currentMonth, forceRefresh: true);
      }

      final remainingPending = (await _attendanceRepository.getPendingEvents()).length;
      final finalResult = SyncResult(
        syncedCount: syncedCount,
        rejectedCount: rejectedCount,
        pendingCount: remainingPending,
        failure: syncFailure,
      );
      _syncResultController.add(finalResult);
      return finalResult;
    } finally {
      _isSyncing = false;
    }
  }

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

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncResultController.close();
  }
}
