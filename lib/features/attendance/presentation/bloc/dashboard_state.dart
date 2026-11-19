import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

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

  final Employee? employee;
  final TodayAttendanceStatus todayStatus;
  final List<AttendanceRecord> recentRecords;
  final int availableLeaveDays;
  final bool isOffline;
  final bool isFromCache;
  final DateTime lastUpdated;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final Duration? elapsedDuration;
  final int pendingCount;

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

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
