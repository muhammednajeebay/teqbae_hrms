import 'package:equatable/equatable.dart';

/// Contract for every type of event the user can send to [AttendanceActionBloc].
///
/// Sealed so the compiler enforces exhaustive handling in switch statements.
sealed class AttendanceActionEvent extends Equatable {
  const AttendanceActionEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped the "Check In" button.
///
/// [AttendanceActionBloc] will validate the geofence, check business rules,
/// save the event locally, and trigger sync.
class CheckInRequested extends AttendanceActionEvent {
  const CheckInRequested();
}

/// User tapped the "Check Out" button.
///
/// Same flow as [CheckInRequested] but for a check-out action.
class CheckOutRequested extends AttendanceActionEvent {
  const CheckOutRequested();
}
