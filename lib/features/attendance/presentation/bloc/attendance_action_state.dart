import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

/// All possible states [AttendanceActionBloc] can emit.
///
/// Sealed so callers must handle every case in a switch expression.
sealed class AttendanceActionState extends Equatable {
  const AttendanceActionState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet. The buttons are shown and ready to tap.
class AttendanceActionInitial extends AttendanceActionState {
  const AttendanceActionInitial();
}

/// The user tapped a button and the action is in progress.
///
/// [type] tells the UI which action is running so it can show the right
/// loading indicator on the correct button.
class AttendanceActionInProgress extends AttendanceActionState {
  const AttendanceActionInProgress(this.type);

  /// Which button the user tapped — check-in or check-out.
  final AttendanceEventType type;

  @override
  List<Object?> get props => [type];
}

/// The check-in or check-out was saved locally (and sync was triggered if online).
class AttendanceActionSuccess extends AttendanceActionState {
  const AttendanceActionSuccess({
    required this.type,
    required this.message,
    required this.isOffline,
  });

  /// Which action completed.
  final AttendanceEventType type;

  /// A human-readable success message safe to display in a SnackBar or banner.
  final String message;

  /// `true` if the device was offline when the action was saved — the UI can
  /// show a "Will sync later" note in this case.
  final bool isOffline;

  @override
  List<Object?> get props => [type, message, isOffline];
}

/// Something prevented the action from completing.
///
/// [message] is always safe to show to the user (e.g. "You are 350 m away.").
class AttendanceActionFailure extends AttendanceActionState {
  const AttendanceActionFailure(
    this.message, {
    this.isLocationPermanentlyDenied = false,
    this.isLocationServiceDisabled = false,
  });

  /// Human-readable explanation of why the action failed.
  final String message;

  /// Whether the action failed because location permission is permanently denied.
  final bool isLocationPermanentlyDenied;

  /// Whether the action failed because device location services (GPS) are turned off.
  final bool isLocationServiceDisabled;

  @override
  List<Object?> get props => [
        message,
        isLocationPermanentlyDenied,
        isLocationServiceDisabled,
      ];
}
