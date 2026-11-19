import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

/// Represents the different phases of the sync lifecycle.
enum SyncStatus {
  /// No sync has run yet since app launch.
  initial,

  /// A sync run is currently in progress.
  syncing,

  /// The last sync run completed without network or server errors.
  success,

  /// The last sync run encountered a network or server error and stopped.
  failure,
}

/// The immutable state emitted by [SyncBloc].
///
/// Holds everything the Sync Status page and the pending-count badge need to
/// display the current sync situation to the user.
class SyncState extends Equatable {
  const SyncState({
    this.status = SyncStatus.initial,
    this.pendingCount = 0,
    this.allEvents = const [],
    this.lastSyncTime,
    this.lastError,
    this.isSyncing = false,
  });

  /// Current phase of the sync lifecycle.
  final SyncStatus status;

  /// How many events in the outbox are still waiting to be sent.
  final int pendingCount;

  /// All attendance events (every status) from the local database.
  /// Used by the Sync Status page to show the full outbox history.
  final List<AttendanceEvent> allEvents;

  /// UTC timestamp of when the last sync run finished. `null` before the first
  /// sync.
  final DateTime? lastSyncTime;

  /// Error message from the most recent failed sync attempt. `null` if the
  /// last sync succeeded or if no sync has run yet.
  final String? lastError;

  /// `true` while a sync is actively running. Used to disable the "Sync Now"
  /// button and show a loading indicator.
  final bool isSyncing;

  /// Returns a copy of this state with any supplied fields replaced.
  ///
  /// Note: [lastError] is intentionally not defaulted to `this.lastError` —
  /// passing `null` explicitly clears the previous error, which is the desired
  /// behaviour when a new sync starts successfully.
  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    List<AttendanceEvent>? allEvents,
    DateTime? lastSyncTime,
    String? lastError,
    bool? isSyncing,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      allEvents: allEvents ?? this.allEvents,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pendingCount,
        allEvents,
        lastSyncTime,
        lastError,
        isSyncing,
      ];
}
