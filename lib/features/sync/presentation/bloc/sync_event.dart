import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

/// Contract for every type of event the user can send to [SyncBloc].
///
/// Sealed so the compiler enforces exhaustive handling.
sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched once at app startup to begin listening to the outbox stream and
/// the [SyncService.onSyncCompleted] stream.
class SyncStarted extends SyncEvent {
  const SyncStarted();
}

/// User (or another BLoC) requested a manual sync right now.
///
/// [currentMonth] is passed to [SyncService.syncNow] so that after a
/// successful sync the attendance records for that month can be refreshed from
/// the server.
class SyncRequested extends SyncEvent {
  const SyncRequested({this.currentMonth});

  /// The `yyyy-MM` month string to refresh after syncing. `null` skips the
  /// post-sync attendance fetch.
  final String? currentMonth;

  @override
  List<Object?> get props => [currentMonth];
}

/// Internal event emitted when the all-events database stream pushes a
/// new list (e.g. after a check-in/out or status update).
class SyncEventsUpdated extends SyncEvent {
  const SyncEventsUpdated(this.allEvents);

  /// The latest snapshot of all attendance events from the local database.
  final List<AttendanceEvent> allEvents;

  @override
  List<Object?> get props => [allEvents];
}

/// Internal event emitted when [SyncService] finishes a sync run and broadcasts
/// its result via [SyncService.onSyncCompleted].
class SyncResultReceived extends SyncEvent {
  const SyncResultReceived(this.result);

  /// The outcome of the most recent sync run.
  final dynamic result;

  @override
  List<Object?> get props => [result];
}
