import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/app.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/attendance/data/location_service.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/attendance/domain/geofence_rule.dart';
import 'package:teqbae_hrms/features/attendance/presentation/pages/dashboard_page.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/employee/domain/employee_repository.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_service.dart';

class MockEmployeeRepository extends Mock implements EmployeeRepository {}
class MockAttendanceRepository extends Mock implements AttendanceRepository {}
class MockLeaveRepository extends Mock implements LeaveRepository {}
class MockSyncService extends Mock implements SyncService {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockLocationService extends Mock implements LocationService {}
class MockGeofenceRule extends Mock implements GeofenceRule {}

void main() {
  late MockEmployeeRepository employeeRepository;
  late MockAttendanceRepository attendanceRepository;
  late MockLeaveRepository leaveRepository;
  late MockSyncService syncService;
  late MockConnectivityService connectivityService;
  late MockLocationService locationService;
  late MockGeofenceRule geofenceRule;
  final clock = FixedClock(DateTime.utc(2026, 11, 19, 9, 0));
  final calendar = CompanyCalendar();

  setUp(() {
    employeeRepository = MockEmployeeRepository();
    attendanceRepository = MockAttendanceRepository();
    leaveRepository = MockLeaveRepository();
    syncService = MockSyncService();
    connectivityService = MockConnectivityService();
    locationService = MockLocationService();
    geofenceRule = MockGeofenceRule();

    when(() => connectivityService.isOnline).thenAnswer((_) async => true);
    when(() => connectivityService.onStatusChanged).thenAnswer((_) => const Stream.empty());
    when(() => syncService.onSyncCompleted).thenAnswer((_) => const Stream.empty());
    when(() => attendanceRepository.watchAllEvents()).thenAnswer((_) => const Stream.empty());
    when(() => attendanceRepository.getAllEvents()).thenAnswer((_) async => []);
    when(() => attendanceRepository.getPendingEvents()).thenAnswer((_) async => []);
    when(() => attendanceRepository.getEventsForDate(any())).thenAnswer((_) async => []);
    when(() => attendanceRepository.getTodayRecord(any())).thenAnswer((_) async => null);
    when(() => attendanceRepository.getAttendance(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success([]));
    when(() => employeeRepository.getEmployee(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(Employee(
              id: 'EMP-001',
              name: 'Ananya Nair',
              department: 'Engineering',
              officeLocation: OfficeConfig(latitude: 9.9312, longitude: 76.2673, radiusMeters: 200),
              companyTimeZone: 'Asia/Kolkata',
            )));
    when(() => leaveRepository.getBalance(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => Success(LeaveBalance(availableDays: 12, updatedAt: DateTime.now().toUtc())));
  });

  testWidgets('renders DashboardPage and displays REBS HRMS title', (WidgetTester tester) async {
    await tester.pumpWidget(RebsHrmsApp(
      employeeRepository: employeeRepository,
      attendanceRepository: attendanceRepository,
      leaveRepository: leaveRepository,
      syncService: syncService,
      connectivityService: connectivityService,
      locationService: locationService,
      geofenceRule: geofenceRule,
      attendanceRules: const AttendanceRules(),
      clock: clock,
      calendar: calendar,
    ));

    await tester.pump();

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.text('REBS HRMS'), findsOneWidget);
  });
}
