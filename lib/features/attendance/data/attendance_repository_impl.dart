import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';

/// Concrete implementation of [AttendanceRepository].
///
/// Applies an offline-first strategy for reads:
/// 1. If offline, return whatever is in the SQLite cache.
/// 2. If online and cache is populated (and not forced), return cache immediately
///    and trigger a background refresh so the UI is never blocked.
/// 3. If online and cache is empty (or force refresh), fetch from the API and
///    store the result before returning.
///
/// Writes (new attendance events) are always local-first:
/// the event is saved to the outbox in the SQLite database before returning,
/// regardless of network state. The [SyncService] handles server delivery later.
class AttendanceRepositoryImpl implements AttendanceRepository {
  /// Creates an [AttendanceRepositoryImpl] with the required dependencies
  /// injected via named parameters.
  AttendanceRepositoryImpl({
    required RebsApi api,
    required AppDatabase database,
    required ConnectivityService connectivity,
  })  : _api = api,
        _database = database,
        _connectivity = connectivity;

  final RebsApi _api;
  final AppDatabase _database;
  final ConnectivityService _connectivity;

  /// Fetches attendance records for [month] using the offline-first strategy.
  ///
  /// - Offline → returns local cache (may be empty on first launch).
  /// - Online + cache hit + no force refresh → returns cache, starts
  ///   background refresh silently.
  /// - Online + (empty cache or force refresh) → fetches from API, stores,
  ///   returns fresh data.
  @override
  Future<Result<List<AttendanceRecord>>> getAttendance(
    String month, {
    bool forceRefresh = false,
  }) async {
    final cached = await _database.attendanceForMonth(month);
    final isOnline = await _connectivity.isOnline;

    if (!isOnline) {
      return Success(cached);
    }

    if (!forceRefresh && cached.isNotEmpty) {
      _refreshAttendance(month);
      return Success(cached);
    }

    final result = await _api.attendance(month);
    if (result is Success<List<AttendanceRecord>>) {
      await _database.replaceAttendanceRecords(result.value);
      return result;
    } else if (cached.isNotEmpty) {
      return Success(cached);
    }
    return result;
  }

  /// Returns a reactive stream of attendance records from the local database.
  ///
  /// The stream emits a new list automatically whenever the database row for
  /// [month] changes (after a sync, for example).
  @override
  Stream<List<AttendanceRecord>> watchAttendance(String month) =>
      _database.watchAttendanceForMonth(month);

  /// Saves a new attendance [event] to the local outbox queue.
  ///
  /// The database write happens inside a Drift transaction, so the event is
  /// either fully saved or not saved at all — there is no partial state.
  @override
  Future<Result<void>> recordEvent(AttendanceEvent event) async {
    try {
      await _database.saveAttendanceEvent(event);
      return const Success(null);
    } catch (e) {
      return FailureResult(StorageFailure('Failed to save attendance event locally: $e'));
    }
  }

  /// Returns all outbox events with [AttendanceEventStatus.pending] status,
  /// ordered oldest-first (by autoincrement sequence).
  @override
  Future<List<AttendanceEvent>> getPendingEvents() =>
      _database.pendingEvents();

  /// A live stream of pending events. Useful for showing a live pending count badge.
  @override
  Stream<List<AttendanceEvent>> watchPendingEvents() =>
      _database.watchPendingEvents();

  /// Returns every attendance event (all statuses) from the local database.
  @override
  Future<List<AttendanceEvent>> getAllEvents() => _database.allEvents();

  /// A live stream of all events. Used by the Sync Status page.
  @override
  Stream<List<AttendanceEvent>> watchAllEvents() => _database.watchAllEvents();

  /// Updates the status, error message, and attempt count for a specific event.
  ///
  /// Called by [SyncService] after each sync attempt to persist the outcome.
  @override
  Future<void> updateEventStatus({
    required String clientEventId,
    required AttendanceEventStatus status,
    String? error,
    int? attempts,
  }) {
    return _database.updateEventStatus(
      clientEventId: clientEventId,
      status: status,
      error: error,
      attempts: attempts,
    );
  }

  /// Returns all events (any status) for the given company-local date.
  @override
  Future<List<AttendanceEvent>> getEventsForDate(String companyDate) =>
      _database.eventsForDate(companyDate);

  /// Returns the synced server record for the given date, or `null` if none.
  @override
  Future<AttendanceRecord?> getTodayRecord(String companyDate) =>
      _database.todayRecord(companyDate);

  /// Silently fetches fresh attendance data from the API in the background
  /// and updates the local cache.
  ///
  /// Errors are intentionally swallowed — this is a best-effort refresh that
  /// should not interrupt the user if it fails.
  Future<void> _refreshAttendance(String month) async {
    final result = await _api.attendance(month);
    if (result is Success<List<AttendanceRecord>>) {
      await _database.replaceAttendanceRecords(result.value);
    }
  }
}
