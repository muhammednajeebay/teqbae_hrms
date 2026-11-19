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

/// Handles check-in and check-out actions requested by the user on the
/// dashboard.
///
/// Uses the **droppable** event transformer so that if the user taps the
/// button multiple times in quick succession, only the first tap is processed
/// and all subsequent taps while the first is still running are silently
/// discarded. This prevents duplicate outbox entries.
///
/// The check-in / check-out flow is:
/// 1. Local business-rule validation (no double check-in, check-out needs check-in).
/// 2. Fetch employee's office location from repository.
/// 3. Read the current GPS position (or simulated preset).
/// 4. Geofence check — employee must be within 200 m of the office.
/// 5. Save the event locally in the outbox as [AttendanceEventStatus.pending].
/// 6. If online, trigger [SyncService.syncNow] immediately.
class AttendanceActionBloc
    extends Bloc<AttendanceActionEvent, AttendanceActionState> {
  /// Creates an [AttendanceActionBloc] with all required dependencies injected.
  ///
  /// A custom [uuid] can be supplied for tests to produce predictable IDs.
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
    // Both events use droppable() to discard duplicate taps while one is running.
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

  /// Delegates check-in handling to the shared [_handleAction] method.
  Future<void> _onCheckIn(
    CheckInRequested event,
    Emitter<AttendanceActionState> emit,
  ) async {
    await _handleAction(AttendanceEventType.checkIn, emit);
  }

  /// Delegates check-out handling to the shared [_handleAction] method.
  Future<void> _onCheckOut(
    CheckOutRequested event,
    Emitter<AttendanceActionState> emit,
  ) async {
    await _handleAction(AttendanceEventType.checkOut, emit);
  }

  /// Runs the full check-in / check-out validation and save pipeline.
  ///
  /// Emits [AttendanceActionInProgress] at the start, then either
  /// [AttendanceActionSuccess] or [AttendanceActionFailure] at the end.
  Future<void> _handleAction(
    AttendanceEventType type,
    Emitter<AttendanceActionState> emit,
  ) async {
    emit(AttendanceActionInProgress(type));

    final nowUtc = _clock.now();
    final companyDate = _calendar.formatCompanyDate(nowUtc);

    // Step 1: Check local business rules — does the employee's current state
    // allow this action today?
    final todayRecord = await _attendanceRepository.getTodayRecord(companyDate);
    final todayRecords =
        todayRecord != null ? <AttendanceRecord>[todayRecord] : const <AttendanceRecord>[];
    final localEvents = await _attendanceRepository.getEventsForDate(companyDate);

    final ruleResult = type == AttendanceEventType.checkIn
        ? _rules.canCheckIn(
            records: todayRecords, events: localEvents, companyDate: companyDate)
        : _rules.canCheckOut(
            records: todayRecords, events: localEvents, companyDate: companyDate);

    if (ruleResult is FailureResult<void>) {
      emit(AttendanceActionFailure(ruleResult.failure.message));
      return;
    }

    // Step 2: Get the office location from the employee profile (falls back to
    // the hard-coded Ernakulam default if the fetch fails).
    final employeeResult = await _employeeRepository.getEmployee();
    final officeConfig = employeeResult is Success
        ? (employeeResult as Success).value.officeLocation
        : const OfficeConfig(latitude: 9.9312, longitude: 76.2673, radiusMeters: 200.0);

    // Step 3: Read the device's current GPS position (or simulated preset).
    final locationResult = await _locationService.currentLocation();
    if (locationResult is FailureResult<AttendanceLocation>) {
      emit(AttendanceActionFailure(locationResult.failure.message));
      return;
    }

    final location = (locationResult as Success<AttendanceLocation>).value;

    // Step 4: Confirm the employee is within the geofence radius.
    final geofenceResult = _geofenceRule.validate(
      office: officeConfig,
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (geofenceResult is FailureResult<double>) {
      emit(AttendanceActionFailure(geofenceResult.failure.message));
      return;
    }

    // Step 5: Persist the event locally in the outbox with a fresh UUID.
    // The UUID never changes — the same ID is retried on subsequent sync
    // attempts, letting the server detect and silently ignore duplicates.
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

    // Step 6: If online, kick off a sync immediately so the user sees the
    // event move from "Pending" to "Synced" as fast as possible.
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      _syncService.syncNow(currentMonth: companyDate.substring(0, 7));
    }

    final actionName =
        type == AttendanceEventType.checkIn ? 'Check-in' : 'Check-out';
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
