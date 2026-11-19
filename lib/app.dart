import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/core/config/app_config.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/attendance/data/location_service.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/attendance/domain/geofence_rule.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/attendance_action_bloc.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/dashboard_bloc.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/dashboard_event.dart';
import 'package:teqbae_hrms/features/attendance/presentation/pages/dashboard_page.dart';
import 'package:teqbae_hrms/features/employee/domain/employee_repository.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_bloc.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_event.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_service.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_event.dart';

/// The root widget of the REBS HRMS application.
///
/// [RebsHrmsApp] is a pure composition widget — it does not hold any business
/// logic itself. Its only job is to:
/// 1. Create all BLoCs and Cubits by injecting the dependencies passed in.
/// 2. Provide those BLoCs to the widget subtree via [MultiBlocProvider].
/// 3. Configure the [MaterialApp] theme and set [DashboardPage] as the home.
class RebsHrmsApp extends StatelessWidget {
  /// Creates the root application widget.
  ///
  /// All parameters are required except [config] and [api], which are only
  /// needed by the Debug Panel and can be omitted in widget tests.
  const RebsHrmsApp({
    super.key,
    required this.employeeRepository,
    required this.attendanceRepository,
    required this.leaveRepository,
    required this.syncService,
    required this.connectivityService,
    required this.locationService,
    required this.geofenceRule,
    required this.attendanceRules,
    required this.clock,
    required this.calendar,
    this.config,
    this.api,
  });

  /// Provides employee profile data (fetches from API or returns cached).
  final EmployeeRepository employeeRepository;

  /// Stores and retrieves attendance records and the local outbox queue.
  final AttendanceRepository attendanceRepository;

  /// Manages leave balance and leave requests (online + cached offline).
  final LeaveRepository leaveRepository;

  /// Runs the offline outbox sync loop and fires result events.
  final SyncService syncService;

  /// Reports whether the device has an active internet connection.
  final ConnectivityService connectivityService;

  /// Returns the current GPS coordinates or a simulated preset.
  final LocationService locationService;

  /// Checks whether the user is within the allowed distance from the office.
  final GeofenceRule geofenceRule;

  /// Enforces attendance business rules (one check-in per day, etc.).
  final AttendanceRules attendanceRules;

  /// Provides the current wall-clock time (swappable in tests via [FixedClock]).
  final Clock clock;

  /// Converts UTC timestamps to the company's local calendar date.
  final CompanyCalendar calendar;

  /// App-level configuration loaded from --dart-define flags (optional in tests).
  final AppConfig? config;

  /// HTTP client used by the Debug Panel to change mock server scenarios.
  final RebsApi? api;

  /// Builds the widget tree.
  ///
  /// Creates one [SyncBloc], one [DashboardBloc], one [LeaveListBloc], and one
  /// [AttendanceActionBloc], makes them available to all descendant widgets via
  /// [MultiBlocProvider], and sets up Material 3 theming.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // SyncBloc — starts listening to outbox events immediately on app launch.
        BlocProvider<SyncBloc>(
          create: (_) => SyncBloc(
            syncService: syncService,
            attendanceRepository: attendanceRepository,
          )..add(const SyncStarted()),
        ),
        // DashboardBloc — loads employee, attendance, and leave data for the home screen.
        BlocProvider<DashboardBloc>(
          create: (_) => DashboardBloc(
            attendanceRepository: attendanceRepository,
            employeeRepository: employeeRepository,
            leaveRepository: leaveRepository,
            connectivityService: connectivityService,
            rules: attendanceRules,
            clock: clock,
            calendar: calendar,
          )..add(const DashboardStarted()),
        ),
        // LeaveListBloc — streams leave requests and balance from the repository.
        BlocProvider<LeaveListBloc>(
          create: (_) => LeaveListBloc(
            leaveRepository: leaveRepository,
            connectivityService: connectivityService,
          )..add(const LeaveListStarted()),
        ),
        // AttendanceActionBloc — handles check-in and check-out taps.
        BlocProvider<AttendanceActionBloc>(
          create: (_) => AttendanceActionBloc(
            rules: attendanceRules,
            locationService: locationService,
            geofenceRule: geofenceRule,
            attendanceRepository: attendanceRepository,
            employeeRepository: employeeRepository,
            syncService: syncService,
            connectivityService: connectivityService,
            clock: clock,
            calendar: calendar,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'REBS HRMS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A5B)),
          useMaterial3: true,
        ),
        home: DashboardPage(
          attendanceRepository: attendanceRepository,
          leaveRepository: leaveRepository,
          connectivityService: connectivityService,
          clock: clock,
          calendar: calendar,
          config: config,
          api: api,
          // Only pass the configurable service if it supports simulation;
          // null means the Debug Panel button will not appear on the home screen.
          locationService: locationService is ConfigurableLocationService
              ? locationService as ConfigurableLocationService
              : null,
        ),
      ),
    );
  }
}
