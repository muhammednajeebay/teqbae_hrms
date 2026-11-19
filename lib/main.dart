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

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  const clock = SystemClock();
  final calendar = CompanyCalendar(defaultTimeZone: config.companyTimeZone);
  final connectivity = DeviceConnectivityService(Connectivity());
  const distanceCalculator = DistanceCalculator();
  const geofenceRule = GeofenceRule(distanceCalculator);
  const attendanceRules = AttendanceRules();
  const locationService = GeolocatorLocationService();

  final database = AppDatabase();
  final api = RebsApi(config);

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

  final syncService = SyncService(
    attendanceRepository: attendanceRepository,
    apiClient: api,
    connectivityService: connectivity,
  );

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
  ));
}
