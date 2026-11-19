import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_event.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_state.dart';

class LeaveListBloc extends Bloc<LeaveListEvent, LeaveListState> {
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

  StreamSubscription<List<LeaveRequest>>? _requestsSub;
  StreamSubscription<LeaveBalance?>? _balanceSub;
  StreamSubscription<bool>? _connectivitySub;

  Future<void> _onStarted(LeaveListStarted event, Emitter<LeaveListState> emit) async {
    emit(state.copyWith(status: LeaveListStatus.loading));

    _requestsSub?.cancel();
    _requestsSub = _leaveRepository.watchRequests().listen((requests) {
      add(LeaveRequestsUpdated(requests));
    });

    _balanceSub?.cancel();
    _balanceSub = _leaveRepository.watchBalance().listen((balance) {
      add(LeaveBalanceUpdated(balance));
    });

    _connectivitySub?.cancel();
    _connectivitySub = _connectivityService.onStatusChanged.listen((isOnline) {
      if (isOnline) {
        add(const LeaveListRefreshRequested());
      }
    });

    await _fetchData(emit, forceRefresh: false);
  }

  Future<void> _onRefresh(LeaveListRefreshRequested event, Emitter<LeaveListState> emit) async {
    await _fetchData(emit, forceRefresh: true);
  }

  void _onRequestsUpdated(LeaveRequestsUpdated event, Emitter<LeaveListState> emit) {
    emit(state.copyWith(
      requests: event.requests,
      status: LeaveListStatus.success,
    ));
  }

  void _onBalanceUpdated(LeaveBalanceUpdated event, Emitter<LeaveListState> emit) {
    emit(state.copyWith(
      balance: event.balance,
      status: LeaveListStatus.success,
    ));
  }

  Future<void> _fetchData(Emitter<LeaveListState> emit, {required bool forceRefresh}) async {
    final isOnline = await _connectivityService.isOnline;
    final requestsRes = await _leaveRepository.getRequests(forceRefresh: forceRefresh);
    final balanceRes = await _leaveRepository.getBalance(forceRefresh: forceRefresh);

    final requests = requestsRes is Success<List<LeaveRequest>> ? requestsRes.value : state.requests;
    final balance = balanceRes is Success<LeaveBalance> ? balanceRes.value : state.balance;

    emit(state.copyWith(
      requests: requests,
      balance: balance,
      isOffline: !isOnline,
      status: LeaveListStatus.success,
    ));
  }

  @override
  Future<void> close() {
    _requestsSub?.cancel();
    _balanceSub?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }
}
