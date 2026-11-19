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

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
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

  Timer? _tickerTimer;
  StreamSubscription<List<AttendanceEvent>>? _eventsSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  Future<void> _onStarted(DashboardStarted event, Emitter<DashboardState> emit) async {
    emit(const DashboardLoading());

    _eventsSubscription?.cancel();
    _eventsSubscription = _attendanceRepository.watchAllEvents().listen((_) {
      add(const DashboardRefreshRequested());
    });

    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivityService.onStatusChanged.listen((_) {
      add(const DashboardRefreshRequested());
    });

    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      add(const DashboardTimerTicked());
    });

    await _loadDashboard(emit, forceRefresh: false);
  }

  Future<void> _onRefresh(DashboardRefreshRequested event, Emitter<DashboardState> emit) async {
    await _loadDashboard(emit, forceRefresh: true);
  }

  void _onTimerTicked(DashboardTimerTicked event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final current = state as DashboardLoaded;
      if (current.todayStatus == TodayAttendanceStatus.checkedIn && current.checkInTime != null) {
        final elapsed = _clock.now().difference(current.checkInTime!);
        emit(current.copyWith(elapsedDuration: elapsed));
      }
    }
  }

  Future<void> _loadDashboard(Emitter<DashboardState> emit, {required bool forceRefresh}) async {
    final nowUtc = _clock.now();
    final companyDate = _calendar.formatCompanyDate(nowUtc);
    final month = companyDate.substring(0, 7);
    final isOnline = await _connectivityService.isOnline;

    final employeeRes = await _employeeRepository.getEmployee(forceRefresh: forceRefresh);
    final attendanceRes = await _attendanceRepository.getAttendance(month, forceRefresh: forceRefresh);
    final balanceRes = await _leaveRepository.getBalance(forceRefresh: forceRefresh);
    final localEvents = await _attendanceRepository.getEventsForDate(companyDate);
    final allEvents = await _attendanceRepository.getAllEvents();
    final pendingCount = allEvents.where((e) => e.status == AttendanceEventStatus.pending).length;

    final employee = employeeRes is Success ? (employeeRes as Success).value : null;
    final records = attendanceRes is Success ? (attendanceRes as Success).value : <AttendanceRecord>[];
    final balance = balanceRes is Success ? (balanceRes as Success).value.availableDays : 0;

    if (employee == null && records.isEmpty && !isOnline) {
      emit(const DashboardError('No cached data available offline. Please connect to the internet.'));
      return;
    }

    final todayRecord = await _attendanceRepository.getTodayRecord(companyDate);
    final todayRecords = todayRecord != null ? [todayRecord] : <AttendanceRecord>[];

    final todayStatus = _rules.deriveTodayStatus(
      records: todayRecords,
      events: localEvents,
      companyDate: companyDate,
    );

    // Compute check-in and check-out times
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

    Duration? elapsed;
    if (todayStatus == TodayAttendanceStatus.checkedIn && checkInTime != null) {
      elapsed = nowUtc.difference(checkInTime);
    } else if (todayStatus == TodayAttendanceStatus.checkedOut && checkInTime != null && checkOutTime != null) {
      elapsed = checkOutTime.difference(checkInTime);
    }

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

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    _eventsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
