import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

/// A minimal API contract used by [SyncService] to send attendance events.
///
/// [SyncService] only depends on this narrow interface rather than the full
/// [RebsApi] class. This makes [SyncService] testable with a lightweight fake
/// that only needs to implement one method.
abstract interface class SyncApiClient {
  /// Sends an attendance [event] to the server.
  ///
  /// Returns [Success] with `true` when the server responds with HTTP 200
  /// (duplicate) or 201 (new record).
  ///
  /// Returns a [FailureResult] when:
  /// - The request times out or the network is unreachable → [NetworkFailure].
  /// - The server rejects the event with 409 or 422 → [ServerFailure] with
  ///   the status code and optional error code from the response body.
  /// - The server returns 5xx → [ServerFailure].
  Future<Result<bool>> postAttendanceEvent(AttendanceEvent event);
}
