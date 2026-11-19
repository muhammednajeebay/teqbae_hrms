import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

/// All events the user or the system can send to [LeaveListBloc].
///
/// Sealed so the compiler enforces exhaustive handling.
sealed class LeaveListEvent extends Equatable {
  const LeaveListEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched once at startup (from the composition root) to begin loading
/// data and subscribing to the database and connectivity streams.
class LeaveListStarted extends LeaveListEvent {
  const LeaveListStarted();
}

/// User pulled to refresh or the device just came back online.
class LeaveListRefreshRequested extends LeaveListEvent {
  const LeaveListRefreshRequested();
}

/// Internal event emitted when the leave-request database stream pushes a
/// new list (e.g. after a successful submission or background refresh).
class LeaveRequestsUpdated extends LeaveListEvent {
  const LeaveRequestsUpdated(this.requests);

  /// The latest snapshot of leave requests from the local database.
  final List<LeaveRequest> requests;

  @override
  List<Object?> get props => [requests];
}

/// Internal event emitted when the leave-balance database stream pushes a
/// new value (e.g. after a background balance refresh).
class LeaveBalanceUpdated extends LeaveListEvent {
  const LeaveBalanceUpdated(this.balance);

  /// The latest cached leave balance. `null` if the balance has never been
  /// fetched.
  final LeaveBalance? balance;

  @override
  List<Object?> get props => [balance];
}
