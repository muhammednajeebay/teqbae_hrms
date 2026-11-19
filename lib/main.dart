import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:teqbae_hrms/app.dart';
import 'package:teqbae_hrms/core/config/app_config.dart';
import 'package:teqbae_hrms/core/geo/distance_calculator.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/attendance/data/attendance_repository_impl.dart';
import 'package:teqbae_hrms/features/attendance/data/location_service.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/geofence_rule.dart';
import 'package:teqbae_hrms/features/employee/data/employee_repository_impl.dart';
import 'package:teqbae_hrms/features/leave/data/leave_repository_impl.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_service.dart';

/// Entry point of the REBS HRMS application.
///
/// This function wires together every dependency (config, database, API,
/// repositories, services) and passes them into [RebsHrmsApp] so that
/// the widget tree never has to create or look up its own dependencies.
/// This is the composition root — only this file knows how every piece
/// connects together.
void main() {
  // Ensure Flutter's widget binding is ready before we touch any platform code.
  WidgetsFlutterBinding.ensureInitialized();

  // Read build-time values passed via --dart-define flags.
  final config = AppConfig.fromEnvironment();

  // Core utilities — stateless and reusable anywhere in the app.
  const clock = SystemClock();
  final calendar = CompanyCalendar(defaultTimeZone: config.companyTimeZone);
  final connectivity = DeviceConnectivityService(Connectivity());
  const distanceCalculator = DistanceCalculator();
  const geofenceRule = GeofenceRule(distanceCalculator);
  const attendanceRules = AttendanceRules();

  // Location service that can switch between real GPS and simulated coordinates
  // at runtime (used by the Debug Panel).
  final locationService = ConfigurableLocationService();

  // Data sources: local SQLite database and remote HTTP API.
  final database = AppDatabase();
  final api = RebsApi(config);

  // Repositories — each one knows when to read from cache vs. from the network.
  final employeeRepository = EmployeeRepositoryImpl(
    api: api,
    database: database,
    connectivity: connectivity,
  );
  final attendanceRepository = AttendanceRepositoryImpl(
    api: api,
    database: database,
    connectivity: connectivity,
  );
  final leaveRepository = LeaveRepositoryImpl(
    api: api,
    database: database,
    connectivity: connectivity,
  );

  // Sync service handles the offline outbox: it listens for network changes
  // and sends any pending attendance events to the server in order.
  final syncService = SyncService(
    attendanceRepository: attendanceRepository,
    apiClient: api,
    connectivityService: connectivity,
  );

  // Hand everything to the root widget.
  runApp(RebsHrmsApp(
    employeeRepository: employeeRepository,
    attendanceRepository: attendanceRepository,
    leaveRepository: leaveRepository,
    syncService: syncService,
    connectivityService: connectivity,
    locationService: locationService,
    geofenceRule: geofenceRule,
    attendanceRules: attendanceRules,
    clock: clock,
    calendar: calendar,
    config: config,
    api: api,
  ));
}
