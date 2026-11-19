import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

sealed class AttendanceActionState extends Equatable {
  const AttendanceActionState();

  @override
  List<Object?> get props => [];
}

class AttendanceActionInitial extends AttendanceActionState {
  const AttendanceActionInitial();
}

class AttendanceActionInProgress extends AttendanceActionState {
  const AttendanceActionInProgress(this.type);

  final AttendanceEventType type;

  @override
  List<Object?> get props => [type];
}

class AttendanceActionSuccess extends AttendanceActionState {
  const AttendanceActionSuccess({
    required this.type,
    required this.message,
    required this.isOffline,
  });

  final AttendanceEventType type;
  final String message;
  final bool isOffline;

  @override
  List<Object?> get props => [type, message, isOffline];
}

class AttendanceActionFailure extends AttendanceActionState {
  const AttendanceActionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
