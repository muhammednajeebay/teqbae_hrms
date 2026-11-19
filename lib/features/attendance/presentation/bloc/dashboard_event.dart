import 'package:equatable/equatable.dart';

/// All events that can be sent to [DashboardBloc].
///
/// Sealed so the compiler enforces exhaustive handling.
sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched once when the app starts (from the composition root in [RebsHrmsApp]).
///
/// Causes [DashboardBloc] to load all dashboard data for the first time and
/// begin listening to database and connectivity changes.
class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

/// Requests a full reload of all dashboard data.
///
/// Dispatched automatically whenever:
/// - A connectivity change is detected (online / offline toggle).
/// - The local attendance event database changes (after check-in/out or sync).
/// - The user pulls to refresh.
class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

/// Fired once per minute by an internal [Timer] inside [DashboardBloc].
///
/// Used to update the elapsed working-time display while the employee is
/// checked in, without reloading all dashboard data from the database.
class DashboardTimerTicked extends DashboardEvent {
  const DashboardTimerTicked();
}
