import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

enum LeaveListStatus { initial, loading, success, failure }

class LeaveListState extends Equatable {
  const LeaveListState({
    this.status = LeaveListStatus.initial,
    this.requests = const [],
    this.balance,
    this.isOffline = false,
    this.errorMessage,
  });

  final LeaveListStatus status;
  final List<LeaveRequest> requests;
  final LeaveBalance? balance;
  final bool isOffline;
  final String? errorMessage;

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
