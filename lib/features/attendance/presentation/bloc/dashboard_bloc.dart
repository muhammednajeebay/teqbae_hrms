import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/dashboard_event.dart';
import 'package:teqbae_hrms/features/attendance/presentation/bloc/dashboard_state.dart';
import 'package:teqbae_hrms/features/employee/domain/employee_repository.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';

/// Manages all data shown on the main dashboard screen.
///
/// Responsibilities:
/// - Loads employee profile, attendance records, leave balance, and local events.
/// - Derives the employee's current status for today (not checked in / checked
///   in / checked out) from both synced server records and local pending events.
/// - Computes the elapsed working time and refreshes it every minute.
/// - Triggers a full reload whenever the database or connectivity changes.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  /// Creates a [DashboardBloc] with all required dependencies injected.
  DashboardBloc({
    required AttendanceRepository attendanceRepository,
    required EmployeeRepository employeeRepository,
    required LeaveRepository leaveRepository,
    required ConnectivityService connectivityService,
    required AttendanceRules rules,
    required Clock clock,
    required CompanyCalendar calendar,
  })  : _attendanceRepository = attendanceRepository,
        _employeeRepository = employeeRepository,
        _leaveRepository = leaveRepository,
        _connectivityService = connectivityService,
        _rules = rules,
        _clock = clock,
        _calendar = calendar,
        super(const DashboardInitial()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshRequested>(_onRefresh);
    on<DashboardTimerTicked>(_onTimerTicked);
  }

  final AttendanceRepository _attendanceRepository;
  final EmployeeRepository _employeeRepository;
  final LeaveRepository _leaveRepository;
  final ConnectivityService _connectivityService;
  final AttendanceRules _rules;
  final Clock _clock;
  final CompanyCalendar _calendar;

  /// Periodic timer that fires every minute to update the elapsed work time.
  Timer? _tickerTimer;

  /// Subscription to the all-events stream — triggers a refresh when the
  /// local outbox changes (e.g. after a sync or a new check-in/out).
  StreamSubscription<List<AttendanceEvent>>? _eventsSubscription;

  /// Subscription to connectivity changes — triggers a refresh whenever the
  /// device comes online or goes offline.
  StreamSubscription<bool>? _connectivitySubscription;

  /// Called once at startup. Sets up all the reactive subscriptions, starts
  /// the minute-timer, and loads the initial dashboard data.
  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    // Re-load the dashboard whenever any local attendance event changes.
    _eventsSubscription?.cancel();
    _eventsSubscription =
        _attendanceRepository.watchAllEvents().listen((_) {
      add(const DashboardRefreshRequested());
    });

    // Re-load whenever network status changes (online → offline or vice versa).
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _connectivityService.onStatusChanged.listen((_) {
      add(const DashboardRefreshRequested());
    });

    // Update the elapsed working time every minute while the user is checked in.
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      add(const DashboardTimerTicked());
    });

    await _loadDashboard(emit, forceRefresh: false);
  }

  /// Loads fresh data from repositories.
  ///
  /// Uses [forceRefresh] = `true` to bypass the cache and always fetch from
  /// the server (used when connectivity is restored or the user pulls to refresh).
  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadDashboard(emit, forceRefresh: true);
  }

  /// Updates only the [DashboardLoaded.elapsedDuration] field without reloading
  /// anything from the database.
  ///
  /// Only active when the employee is currently checked in. This keeps the
  /// timer display accurate without hitting the database every minute.
  void _onTimerTicked(
    DashboardTimerTicked event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final current = state as DashboardLoaded;
      if (current.todayStatus == TodayAttendanceStatus.checkedIn &&
          current.checkInTime != null) {
        final elapsed = _clock.now().difference(current.checkInTime!);
        emit(current.copyWith(elapsedDuration: elapsed));
      }
    }
  }

  /// Loads all dashboard data from the repositories and emits a new state.
  ///
  /// Applies offline-first logic: if no data is available at all and the device
  /// is offline, emits [DashboardError]. Otherwise emits [DashboardLoaded] with
  /// whatever data is available (may be from cache).
  Future<void> _loadDashboard(
    Emitter<DashboardState> emit, {
    required bool forceRefresh,
  }) async {
    final nowUtc = _clock.now();
    final companyDate = _calendar.formatCompanyDate(nowUtc);
    final month = companyDate.substring(0, 7);
    final isOnline = await _connectivityService.isOnline;

    // Fetch all data sources in parallel (the repositories handle caching).
    final employeeRes =
        await _employeeRepository.getEmployee(forceRefresh: forceRefresh);
    final attendanceRes = await _attendanceRepository.getAttendance(month,
        forceRefresh: forceRefresh);
    final balanceRes =
        await _leaveRepository.getBalance(forceRefresh: forceRefresh);
    final localEvents =
        await _attendanceRepository.getEventsForDate(companyDate);
    final allEvents = await _attendanceRepository.getAllEvents();
    final pendingCount = allEvents
        .where((e) => e.status == AttendanceEventStatus.pending)
        .length;

    // Unwrap successful results; use empty/zero defaults for failures.
    final employee =
        employeeRes is Success ? (employeeRes as Success).value : null;
    final records = attendanceRes is Success
        ? (attendanceRes as Success).value
        : <AttendanceRecord>[];
    final balance =
        balanceRes is Success ? (balanceRes as Success).value.availableDays : 0;

    // If absolutely nothing is available offline, show an error.
    if (employee == null && records.isEmpty && !isOnline) {
      emit(const DashboardError(
          'No cached data available offline. Please connect to the internet.'));
      return;
    }

    // Get today's synced record (may be null on first login or new day).
    final todayRecord =
        await _attendanceRepository.getTodayRecord(companyDate);
    final todayRecords =
        todayRecord != null ? [todayRecord] : <AttendanceRecord>[];

    // Derive check-in / check-out status from both server records and local events.
    final todayStatus = _rules.deriveTodayStatus(
      records: todayRecords,
      events: localEvents,
      companyDate: companyDate,
    );

    // Determine actual check-in and check-out times. The server record takes
    // priority; pending local events fill in the gap if the server record is
    // not yet available.
    DateTime? checkInTime = todayRecord?.checkInAt;
    DateTime? checkOutTime = todayRecord?.checkOutAt;

    for (final ev in localEvents) {
      if (ev.status != AttendanceEventStatus.rejected) {
        if (ev.type == AttendanceEventType.checkIn) {
          checkInTime ??= ev.occurredAt;
        } else if (ev.type == AttendanceEventType.checkOut) {
          checkOutTime ??= ev.occurredAt;
        }
      }
    }

    // Compute elapsed time for the working-hours display.
    Duration? elapsed;
    if (todayStatus == TodayAttendanceStatus.checkedIn &&
        checkInTime != null) {
      elapsed = nowUtc.difference(checkInTime);
    } else if (todayStatus == TodayAttendanceStatus.checkedOut &&
        checkInTime != null &&
        checkOutTime != null) {
      elapsed = checkOutTime.difference(checkInTime);
    }

    // Only show the last 5 records in the dashboard history card.
    final recentRecords = records.take(5).toList();

    emit(DashboardLoaded(
      employee: employee,
      todayStatus: todayStatus,
      recentRecords: recentRecords,
      availableLeaveDays: balance,
      isOffline: !isOnline,
      isFromCache: !isOnline || (!forceRefresh && employee != null),
      lastUpdated: nowUtc,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      elapsedDuration: elapsed,
      pendingCount: pendingCount,
    ));
  }

  /// Cancels all subscriptions and timers when the BLoC is closed.
  ///
  /// This is called automatically by [flutter_bloc] when the widget tree no
  /// longer needs this BLoC.
  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    _eventsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
