import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
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
import 'package:teqbae_hrms/features/sync/domain/sync_service.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_event.dart';

class RebsHrmsApp extends StatelessWidget {
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
  });

  final EmployeeRepository employeeRepository;
  final AttendanceRepository attendanceRepository;
  final LeaveRepository leaveRepository;
  final SyncService syncService;
  final ConnectivityService connectivityService;
  final LocationService locationService;
  final GeofenceRule geofenceRule;
  final AttendanceRules attendanceRules;
  final Clock clock;
  final CompanyCalendar calendar;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SyncBloc>(
          create: (_) => SyncBloc(
            syncService: syncService,
            attendanceRepository: attendanceRepository,
          )..add(const SyncStarted()),
        ),
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
        home: DashboardPage(attendanceRepository: attendanceRepository),
      ),
    );
  }
}
