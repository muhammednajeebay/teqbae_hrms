import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/attendance/data/location_service.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/attendance/domain/geofence_rule.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/attendance_action_event.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/attendance_action_state.dart';
import 'package:teqbae_hrms/features/employee/domain/employee_repository.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_service.dart';

class AttendanceActionBloc extends Bloc<AttendanceActionEvent, AttendanceActionState> {
  AttendanceActionBloc({
    required AttendanceRules rules,
    required LocationService locationService,
    required GeofenceRule geofenceRule,
    required AttendanceRepository attendanceRepository,
    required EmployeeRepository employeeRepository,
    required SyncService syncService,
    required ConnectivityService connectivityService,
    required Clock clock,
    required CompanyCalendar calendar,
    Uuid? uuid,
  })  : _rules = rules,
        _locationService = locationService,
        _geofenceRule = geofenceRule,
        _attendanceRepository = attendanceRepository,
        _employeeRepository = employeeRepository,
        _syncService = syncService,
        _connectivityService = connectivityService,
        _clock = clock,
        _calendar = calendar,
        _uuid = uuid ?? const Uuid(),
        super(const AttendanceActionInitial()) {
    on<CheckInRequested>(_onCheckIn, transformer: droppable());
    on<CheckOutRequested>(_onCheckOut, transformer: droppable());
  }

  final AttendanceRules _rules;
  final LocationService _locationService;
  final GeofenceRule _geofenceRule;
  final AttendanceRepository _attendanceRepository;
  final EmployeeRepository _employeeRepository;
  final SyncService _syncService;
  final ConnectivityService _connectivityService;
  final Clock _clock;
  final CompanyCalendar _calendar;
  final Uuid _uuid;

  Future<void> _onCheckIn(CheckInRequested event, Emitter<AttendanceActionState> emit) async {
    await _handleAction(AttendanceEventType.checkIn, emit);
  }

  Future<void> _onCheckOut(CheckOutRequested event, Emitter<AttendanceActionState> emit) async {
    await _handleAction(AttendanceEventType.checkOut, emit);
  }

  Future<void> _handleAction(AttendanceEventType type, Emitter<AttendanceActionState> emit) async {
    emit(AttendanceActionInProgress(type));

    final nowUtc = _clock.now();
    final companyDate = _calendar.formatCompanyDate(nowUtc);

    // 1. Local business rule validation
    final todayRecord = await _attendanceRepository.getTodayRecord(companyDate);
    final todayRecords = todayRecord != null ? <AttendanceRecord>[todayRecord] : const <AttendanceRecord>[];
    final localEvents = await _attendanceRepository.getEventsForDate(companyDate);

    final ruleResult = type == AttendanceEventType.checkIn
        ? _rules.canCheckIn(records: todayRecords, events: localEvents, companyDate: companyDate)
        : _rules.canCheckOut(records: todayRecords, events: localEvents, companyDate: companyDate);

    if (ruleResult is FailureResult<void>) {
      emit(AttendanceActionFailure(ruleResult.failure.message));
      return;
    }

    // 2. Fetch office configuration
    final employeeResult = await _employeeRepository.getEmployee();
    final officeConfig = employeeResult is Success
        ? (employeeResult as Success).value.officeLocation
        : const OfficeConfig(latitude: 9.9312, longitude: 76.2673, radiusMeters: 200.0);

    // 3. Location permission & position reading
    final locationResult = await _locationService.currentLocation();
    if (locationResult is FailureResult<AttendanceLocation>) {
      emit(AttendanceActionFailure(locationResult.failure.message));
      return;
    }

    final location = (locationResult as Success<AttendanceLocation>).value;

    // 4. Geofence radius check (200m)
    final geofenceResult = _geofenceRule.validate(
      office: officeConfig,
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (geofenceResult is FailureResult<double>) {
      emit(AttendanceActionFailure(geofenceResult.failure.message));
      return;
    }

    // 5. Save locally in outbox (Pending)
    final clientEventId = _uuid.v4();
    final attendanceEvent = AttendanceEvent(
      clientEventId: clientEventId,
      type: type,
      occurredAt: nowUtc,
      companyDate: companyDate,
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      isMockedLocation: location.isMocked,
      status: AttendanceEventStatus.pending,
    );

    final recordResult = await _attendanceRepository.recordEvent(attendanceEvent);
    if (recordResult is FailureResult<void>) {
      emit(AttendanceActionFailure(recordResult.failure.message));
      return;
    }

    // 6. Trigger sync
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      _syncService.syncNow(currentMonth: companyDate.substring(0, 7));
    }

    final actionName = type == AttendanceEventType.checkIn ? 'Check-in' : 'Check-out';
    final successMessage = isOnline
        ? '$actionName recorded and syncing.'
        : '$actionName saved offline. Will sync when online.';

    emit(AttendanceActionSuccess(
      type: type,
      message: successMessage,
      isOffline: !isOnline,
    ));
  }
}
