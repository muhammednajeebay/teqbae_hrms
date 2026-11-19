import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/leave/domain/leave_repository.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_bloc.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_event.dart';
import 'package:teqbae_hrms/features/leave/presentation/bloc/leave_list_state.dart';
import 'package:teqbae_hrms/features/leave/presentation/pages/leave_list_page.dart';

class MockLeaveListBloc extends MockBloc<LeaveListEvent, LeaveListState> implements LeaveListBloc {}
class MockLeaveRepository extends Mock implements LeaveRepository {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockLeaveListBloc mockLeaveListBloc;
  late MockLeaveRepository leaveRepository;
  late MockConnectivityService connectivityService;
  final clock = FixedClock(DateTime.utc(2026, 11, 19, 9, 0));
  final calendar = CompanyCalendar();

  setUp(() {
    mockLeaveListBloc = MockLeaveListBloc();
    leaveRepository = MockLeaveRepository();
    connectivityService = MockConnectivityService();
  });

  Widget buildSubject(LeaveListBloc bloc) {
    return MaterialApp(
      home: BlocProvider<LeaveListBloc>.value(
        value: bloc,
        child: LeaveListPage(
          leaveRepository: leaveRepository,
          connectivityService: connectivityService,
          clock: clock,
          calendar: calendar,
        ),
      ),
    );
  }

  testWidgets('renders LeaveListPage with balance card and request chips', (tester) async {
    final request = LeaveRequest(
      id: 'leave-1',
      type: LeaveType.casual,
      startDate: DateTime.utc(2026, 12, 10),
      endDate: DateTime.utc(2026, 12, 11),
      reason: 'Family function travel',
      status: LeaveStatus.approved,
    );

    when(() => mockLeaveListBloc.state).thenReturn(LeaveListState(
      status: LeaveListStatus.success,
      requests: [request],
      balance: LeaveBalance(availableDays: 12, updatedAt: DateTime.utc(2026, 11, 19)),
    ));

    await tester.pumpWidget(buildSubject(mockLeaveListBloc));
    await tester.pump();

    expect(find.text('Leave Requests'), findsOneWidget);
    expect(find.text('12 days'), findsOneWidget);
    expect(find.text('Casual Leave'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.byKey(const Key('apply_leave_fab')), findsOneWidget);
  });
}
