import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/cubit/leave_form_cubit.dart';
import 'package:teqbae_hrms/features/leave/presentation/cubit/leave_form_state.dart';

class MockLeaveRepository extends Mock implements LeaveRepository {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockLeaveRepository leaveRepository;
  late MockConnectivityService connectivityService;
  final clock = FixedClock(DateTime.utc(2026, 11, 19, 9, 0));
  final calendar = CompanyCalendar();

  setUpAll(() {
    registerFallbackValue(LeaveType.casual);
    registerFallbackValue(DateTime.utc(2026, 11, 20));
  });

  setUp(() {
    leaveRepository = MockLeaveRepository();
    connectivityService = MockConnectivityService();
  });

  group('LeaveFormCubit', () {
    blocTest<LeaveFormCubit, LeaveFormState>(
      'blocks submit when offline',
      build: () {
        when(() => connectivityService.isOnline).thenAnswer((_) async => false);
        return LeaveFormCubit(
          leaveRepository: leaveRepository,
          validator: const LeaveValidator(),
          connectivityService: connectivityService,
          clock: clock,
          calendar: calendar,
        );
      },
      act: (cubit) => cubit.submit(availableDays: 12, existingRequests: const []),
      expect: () => [
        predicate<LeaveFormState>((s) => s.isOffline && s.generalError != null),
      ],
    );

    blocTest<LeaveFormCubit, LeaveFormState>(
      'validates short reason and sets reasonError',
      build: () {
        when(() => connectivityService.isOnline).thenAnswer((_) async => true);
        return LeaveFormCubit(
          leaveRepository: leaveRepository,
          validator: const LeaveValidator(),
          connectivityService: connectivityService,
          clock: clock,
          calendar: calendar,
          initialState: LeaveFormState(
            startDate: DateTime.utc(2026, 11, 25),
            endDate: DateTime.utc(2026, 11, 26),
            reason: 'short',
          ),
        );
      },
      act: (cubit) => cubit.submit(availableDays: 12, existingRequests: const []),
      expect: () => [
        predicate<LeaveFormState>((s) => s.reasonError != null),
      ],
    );

    blocTest<LeaveFormCubit, LeaveFormState>(
      'submits successfully when fields are valid and online',
      build: () {
        when(() => connectivityService.isOnline).thenAnswer((_) async => true);
        when(() => leaveRepository.applyLeave(
              type: any(named: 'type'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
              reason: any(named: 'reason'),
            )).thenAnswer((_) async => Success(LeaveRequest(
              id: 'leave-10',
              type: LeaveType.casual,
              startDate: DateTime.utc(2026, 11, 25),
              endDate: DateTime.utc(2026, 11, 26),
              reason: 'Attending relative marriage ceremony',
              status: LeaveStatus.pending,
            )));
        return LeaveFormCubit(
          leaveRepository: leaveRepository,
          validator: const LeaveValidator(),
          connectivityService: connectivityService,
          clock: clock,
          calendar: calendar,
          initialState: LeaveFormState(
            startDate: DateTime.utc(2026, 11, 25),
            endDate: DateTime.utc(2026, 11, 26),
            reason: 'Attending relative marriage ceremony',
          ),
        );
      },
      act: (cubit) => cubit.submit(availableDays: 12, existingRequests: const []),
      expect: () => [
        predicate<LeaveFormState>((s) => s.status == LeaveFormStatus.submitting),
        predicate<LeaveFormState>((s) => s.status == LeaveFormStatus.success),
      ],
    );
  });
}
