import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

/// Represents the different loading phases of the leave list.
enum LeaveListStatus {
  /// No data has been fetched yet.
  initial,

  /// A fetch is in progress.
  loading,

  /// Data loaded successfully (may be from cache while offline).
  success,

  /// An unrecoverable error occurred (not currently used but reserved for
  /// future error-state handling).
  failure,
}

/// The immutable state emitted by [LeaveListBloc].
class LeaveListState extends Equatable {
  const LeaveListState({
    this.status = LeaveListStatus.initial,
    this.requests = const [],
    this.balance,
    this.isOffline = false,
    this.errorMessage,
  });

  /// Current loading phase.
  final LeaveListStatus status;

  /// The list of leave requests to show in the UI. Empty before data loads.
  final List<LeaveRequest> requests;

  /// The employee's leave balance. `null` before the balance has been fetched.
  final LeaveBalance? balance;

  /// `true` when the device has no internet connection.
  final bool isOffline;

  /// Error message to display, if any. Typically set only on a failure state.
  final String? errorMessage;

  /// Returns a copy of this state with any supplied fields replaced.
  ///
  /// Note: [errorMessage] must be passed explicitly as `null` to clear it —
  /// the same pattern used in [SyncState.copyWith].
  LeaveListState copyWith({
    LeaveListStatus? status,
    List<LeaveRequest>? requests,
    LeaveBalance? balance,
    bool? isOffline,
    String? errorMessage,
  }) {
    return LeaveListState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      balance: balance ?? this.balance,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, requests, balance, isOffline, errorMessage];
}
