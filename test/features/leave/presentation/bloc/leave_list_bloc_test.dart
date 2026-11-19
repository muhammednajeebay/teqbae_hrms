import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_bloc.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_event.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_state.dart';

class MockLeaveRepository extends Mock implements LeaveRepository {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockLeaveRepository leaveRepository;
  late MockConnectivityService connectivityService;

  setUp(() {
    leaveRepository = MockLeaveRepository();
    connectivityService = MockConnectivityService();
    when(() => leaveRepository.watchRequests()).thenAnswer((_) => const Stream.empty());
    when(() => leaveRepository.watchBalance()).thenAnswer((_) => const Stream.empty());
    when(() => connectivityService.onStatusChanged).thenAnswer((_) => const Stream.empty());
  });

  group('LeaveListBloc', () {
    final testRequests = [
      LeaveRequest(
        id: 'leave-1',
        type: LeaveType.casual,
        startDate: DateTime.utc(2026, 12, 10),
        endDate: DateTime.utc(2026, 12, 11),
        reason: 'Family function travel',
        status: LeaveStatus.pending,
      ),
    ];
    final testBalance = LeaveBalance(
      availableDays: 12,
      updatedAt: DateTime.utc(2026, 11, 19),
    );

    blocTest<LeaveListBloc, LeaveListState>(
      'loads requests and balance on LeaveListStarted when online',
      build: () {
        when(() => connectivityService.isOnline).thenAnswer((_) async => true);
        when(() => leaveRepository.getRequests(forceRefresh: false))
            .thenAnswer((_) async => Success(testRequests));
        when(() => leaveRepository.getBalance(forceRefresh: false))
            .thenAnswer((_) async => Success(testBalance));
        return LeaveListBloc(
          leaveRepository: leaveRepository,
          connectivityService: connectivityService,
        );
      },
      act: (bloc) => bloc.add(const LeaveListStarted()),
      expect: () => [
        predicate<LeaveListState>((s) => s.status == LeaveListStatus.loading),
        predicate<LeaveListState>((s) =>
            s.status == LeaveListStatus.success &&
            s.requests.length == 1 &&
            s.balance?.availableDays == 12 &&
            !s.isOffline),
      ],
    );

    blocTest<LeaveListBloc, LeaveListState>(
      'reflects offline status when disconnected',
      build: () {
        when(() => connectivityService.isOnline).thenAnswer((_) async => false);
        when(() => leaveRepository.getRequests(forceRefresh: false))
            .thenAnswer((_) async => Success(testRequests));
        when(() => leaveRepository.getBalance(forceRefresh: false))
            .thenAnswer((_) async => Success(testBalance));
        return LeaveListBloc(
          leaveRepository: leaveRepository,
          connectivityService: connectivityService,
        );
      },
      act: (bloc) => bloc.add(const LeaveListStarted()),
      expect: () => [
        predicate<LeaveListState>((s) => s.status == LeaveListStatus.loading),
        predicate<LeaveListState>((s) =>
            s.status == LeaveListStatus.success &&
            s.requests.length == 1 &&
            s.isOffline),
      ],
    );
  });
}
