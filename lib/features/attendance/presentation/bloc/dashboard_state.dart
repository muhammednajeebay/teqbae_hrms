import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';

/// All possible states [DashboardBloc] can emit.
///
/// Sealed so callers must handle every case in a switch expression.
sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// The very first state before any data has been loaded.
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Data is currently being fetched. The UI should show a loading indicator.
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// All data loaded successfully. Contains everything the dashboard needs to
/// render the employee card, today's status, timers, leave balance, and history.
class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.employee,
    required this.todayStatus,
    required this.recentRecords,
    required this.availableLeaveDays,
    required this.isOffline,
    required this.isFromCache,
    required this.lastUpdated,
    this.checkInTime,
    this.checkOutTime,
    this.elapsedDuration,
    this.pendingCount = 0,
  });

  /// The authenticated employee's profile. `null` on the very first offline
  /// launch before any data has ever been cached.
  final Employee? employee;

  /// Whether the employee has checked in, checked out, or done neither today.
  final TodayAttendanceStatus todayStatus;

  /// The five most recent attendance records to display in the history card.
  final List<AttendanceRecord> recentRecords;

  /// Number of leave days remaining according to the latest cached balance.
  final int availableLeaveDays;

  /// `true` when the device has no internet connection.
  final bool isOffline;

  /// `true` when the displayed data came from the local cache (not live from
  /// the server). Used to show a "data may be outdated" badge.
  final bool isFromCache;

  /// UTC timestamp of when this state was computed. Used to decide whether a
  /// refresh is necessary.
  final DateTime lastUpdated;

  /// The UTC time the employee checked in today, from either the server record
  /// or a local pending event. `null` if no check-in exists yet.
  final DateTime? checkInTime;

  /// The UTC time the employee checked out today. `null` if not yet checked out.
  final DateTime? checkOutTime;

  /// How long the employee has been at work today. Updated every minute by the
  /// timer while [todayStatus] is [TodayAttendanceStatus.checkedIn].
  final Duration? elapsedDuration;

  /// Number of attendance events waiting to be synced to the server.
  final int pendingCount;

  /// Returns a copy of this state with any supplied fields replaced.
  ///
  /// Used by the timer handler to update [elapsedDuration] without rebuilding
  /// the entire state from the database.
  DashboardLoaded copyWith({
    Employee? employee,
    TodayAttendanceStatus? todayStatus,
    List<AttendanceRecord>? recentRecords,
    int? availableLeaveDays,
    bool? isOffline,
    bool? isFromCache,
    DateTime? lastUpdated,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    Duration? elapsedDuration,
    int? pendingCount,
  }) {
    return DashboardLoaded(
      employee: employee ?? this.employee,
      todayStatus: todayStatus ?? this.todayStatus,
      recentRecords: recentRecords ?? this.recentRecords,
      availableLeaveDays: availableLeaveDays ?? this.availableLeaveDays,
      isOffline: isOffline ?? this.isOffline,
      isFromCache: isFromCache ?? this.isFromCache,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }

  @override
  List<Object?> get props => [
        employee,
        todayStatus,
        recentRecords,
        availableLeaveDays,
        isOffline,
        isFromCache,
        lastUpdated,
        checkInTime,
        checkOutTime,
        elapsedDuration,
        pendingCount,
      ];
}

/// Something went wrong and the dashboard cannot be displayed.
///
/// Shown when the device is offline AND no cached data is available (first run
/// with no internet). [message] is safe to display to the user.
class DashboardError extends DashboardState {
  const DashboardError(this.message);

  /// Human-readable description of the error.
  final String message;

  @override
  List<Object?> get props => [message];
}
