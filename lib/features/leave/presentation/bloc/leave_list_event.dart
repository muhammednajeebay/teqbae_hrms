import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

sealed class LeaveListEvent extends Equatable {
  const LeaveListEvent();

  @override
  List<Object?> get props => [];
}

class LeaveListStarted extends LeaveListEvent {
  const LeaveListStarted();
}

class LeaveListRefreshRequested extends LeaveListEvent {
  const LeaveListRefreshRequested();
}

class LeaveRequestsUpdated extends LeaveListEvent {
  const LeaveRequestsUpdated(this.requests);

  final List<LeaveRequest> requests;

  @override
  List<Object?> get props => [requests];
}

class LeaveBalanceUpdated extends LeaveListEvent {
  const LeaveBalanceUpdated(this.balance);

  final LeaveBalance? balance;

  @override
  List<Object?> get props => [balance];
}
