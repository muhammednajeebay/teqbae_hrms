import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';

/// The outcome of a single [SyncService.syncNow] run.
///
/// Gives the caller a clear picture of what happened:
/// - How many events were successfully sent.
/// - How many were permanently rejected.
/// - How many are still waiting (because the run was interrupted).
/// - What error stopped the run, if any.
class SyncResult extends Equatable {
  const SyncResult({
    required this.syncedCount,
    required this.rejectedCount,
    required this.pendingCount,
    this.failure,
  });

  /// Number of events that were sent and acknowledged by the server
  /// (HTTP 200 or 201).
  final int syncedCount;

  /// Number of events that the server permanently rejected (HTTP 409 or 422),
  /// plus any dependent events that were automatically rejected as a result.
  final int rejectedCount;

  /// Number of events still in the outbox after this run completed.
  final int pendingCount;

  /// The [NetworkFailure] or [ServerFailure] that caused the sync run to stop
  /// early. `null` means the run processed all events without being blocked.
  final Failure? failure;

  /// `true` when no failure occurred and no events were rejected — every
  /// pending event was successfully synced.
  bool get isSuccess => failure == null && rejectedCount == 0;

  @override
  List<Object?> get props => [syncedCount, rejectedCount, pendingCount, failure];
}
