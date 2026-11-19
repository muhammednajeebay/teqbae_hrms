import 'package:equatable/equatable.dart';

sealed class AttendanceActionEvent extends Equatable {
  const AttendanceActionEvent();

  @override
  List<Object?> get props => [];
}

class CheckInRequested extends AttendanceActionEvent {
  const CheckInRequested();
}

class CheckOutRequested extends AttendanceActionEvent {
  const CheckOutRequested();
}
