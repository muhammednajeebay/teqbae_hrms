import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_event.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_state.dart';

/// Manages the data displayed on the Leave List page.
///
/// Responsibilities:
/// - Loads leave requests and the leave balance on startup.
/// - Subscribes to the local database streams so the UI updates automatically
///   when the cache changes (e.g. after a background refresh or new submission).
/// - Triggers a re-fetch whenever the device comes back online.
class LeaveListBloc extends Bloc<LeaveListEvent, LeaveListState> {
  /// Creates a [LeaveListBloc] with all required dependencies injected.
  ///
  /// [initialState] is used in tests to skip the loading phase.
  LeaveListBloc({
    required LeaveRepository leaveRepository,
    required ConnectivityService connectivityService,
    LeaveListState initialState = const LeaveListState(),
  })  : _leaveRepository = leaveRepository,
        _connectivityService = connectivityService,
        super(initialState) {
    on<LeaveListStarted>(_onStarted);
    on<LeaveListRefreshRequested>(_onRefresh);
    on<LeaveRequestsUpdated>(_onRequestsUpdated);
    on<LeaveBalanceUpdated>(_onBalanceUpdated);
  }

  final LeaveRepository _leaveRepository;
  final ConnectivityService _connectivityService;

  /// Subscription to the leave-requests database stream.
  StreamSubscription<List<LeaveRequest>>? _requestsSub;

  /// Subscription to the leave-balance database stream.
  StreamSubscription<LeaveBalance?>? _balanceSub;

  /// Subscription to connectivity changes.
  StreamSubscription<bool>? _connectivitySub;

  /// Called once at startup. Sets up all reactive subscriptions and loads the
  /// initial data from the repository.
  Future<void> _onStarted(
    LeaveListStarted event,
    Emitter<LeaveListState> emit,
  ) async {
    emit(state.copyWith(status: LeaveListStatus.loading));

    // Listen to the local database — any cache update (from a background refresh
    // or successful submission) will push a new list here.
    _requestsSub?.cancel();
    _requestsSub = _leaveRepository.watchRequests().listen((requests) {
      add(LeaveRequestsUpdated(requests));
    });

    _balanceSub?.cancel();
    _balanceSub = _leaveRepository.watchBalance().listen((balance) {
      add(LeaveBalanceUpdated(balance));
    });

    // Trigger a full refresh whenever the device comes online.
    _connectivitySub?.cancel();
    _connectivitySub = _connectivityService.onStatusChanged.listen((isOnline) {
      if (isOnline) {
        add(const LeaveListRefreshRequested());
      }
    });

    await _fetchData(emit, forceRefresh: false);
  }

  /// Fetches fresh data from the repository (bypasses cache).
  ///
  /// Called when the user pulls to refresh or the device reconnects.
  Future<void> _onRefresh(
    LeaveListRefreshRequested event,
    Emitter<LeaveListState> emit,
  ) async {
    await _fetchData(emit, forceRefresh: true);
  }

  /// Updates the leave-request list when the database stream emits a new value.
  void _onRequestsUpdated(
    LeaveRequestsUpdated event,
    Emitter<LeaveListState> emit,
  ) {
    emit(state.copyWith(
      requests: event.requests,
      status: LeaveListStatus.success,
    ));
  }

  /// Updates the leave balance when the database stream emits a new value.
  void _onBalanceUpdated(
    LeaveBalanceUpdated event,
    Emitter<LeaveListState> emit,
  ) {
    emit(state.copyWith(
      balance: event.balance,
      status: LeaveListStatus.success,
    ));
  }

  /// Fetches leave requests and balance from the repository and emits a
  /// combined state.
  ///
  /// Uses the offline-first cache strategy from the repository layer, so this
  /// method works correctly both online and offline.
  Future<void> _fetchData(
    Emitter<LeaveListState> emit, {
    required bool forceRefresh,
  }) async {
    final isOnline = await _connectivityService.isOnline;
    final requestsRes =
        await _leaveRepository.getRequests(forceRefresh: forceRefresh);
    final balanceRes =
        await _leaveRepository.getBalance(forceRefresh: forceRefresh);

    // Use the fetched values on success; fall back to what is already in state.
    final requests = requestsRes is Success<List<LeaveRequest>>
        ? requestsRes.value
        : state.requests;
    final balance =
        balanceRes is Success<LeaveBalance> ? balanceRes.value : state.balance;

    emit(state.copyWith(
      requests: requests,
      balance: balance,
      isOffline: !isOnline,
      status: LeaveListStatus.success,
    ));
  }

  /// Cancels all stream subscriptions when the BLoC is closed.
  @override
  Future<void> close() {
    _requestsSub?.cancel();
    _balanceSub?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }
}
