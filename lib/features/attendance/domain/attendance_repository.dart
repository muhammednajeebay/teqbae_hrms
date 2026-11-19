import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

/// Contract that any class providing attendance data must fulfill.
///
/// The domain and presentation layers depend only on this interface, never on
/// the concrete [AttendanceRepositoryImpl]. This allows the data layer to be
/// swapped out (e.g. with a fake repository in tests) without touching any
/// business logic.
abstract interface class AttendanceRepository {
  /// Returns the list of synced attendance records for the given [month]
  /// (`yyyy-MM` format).
  ///
  /// If the device is offline, returns cached records from the local database.
  /// If [forceRefresh] is `true`, always fetches from the server when online.
  Future<Result<List<AttendanceRecord>>> getAttendance(
    String month, {
    bool forceRefresh = false,
  });

  /// A live stream of attendance records for [month] from the local database.
  ///
  /// Emits a new list whenever the database changes (e.g. after a sync).
  Stream<List<AttendanceRecord>> watchAttendance(String month);

  /// Saves a new attendance [event] to the local outbox queue.
  ///
  /// The event is stored with [AttendanceEventStatus.pending] and will be
  /// picked up by [SyncService] on the next sync run.
  Future<Result<void>> recordEvent(AttendanceEvent event);

  /// Returns all events that are still waiting to be sent to the server.
  Future<List<AttendanceEvent>> getPendingEvents();

  /// A live stream of pending events. Emits whenever the outbox changes.
  Stream<List<AttendanceEvent>> watchPendingEvents();

  /// Returns every attendance event in the local database (all statuses).
  Future<List<AttendanceEvent>> getAllEvents();

  /// A live stream of all events. Used by the Sync Status page to display
  /// a real-time outbox view.
  Stream<List<AttendanceEvent>> watchAllEvents();

  /// Updates the [status], [error], and [attempts] of a specific event
  /// identified by [clientEventId].
  ///
  /// Called by [SyncService] after each sync attempt to record the outcome.
  Future<void> updateEventStatus({
    required String clientEventId,
    required AttendanceEventStatus status,
    String? error,
    int? attempts,
  });

  /// Returns all events for a specific company-local calendar date.
  ///
  /// Used by the attendance action BLoC to check the current day's local
  /// events before allowing a check-in or check-out.
  Future<List<AttendanceEvent>> getEventsForDate(String companyDate);

  /// Returns the synced server record for a specific [companyDate], or `null`
  /// if no record exists for that date in the local cache.
  Future<AttendanceRecord?> getTodayRecord(String companyDate);
}
