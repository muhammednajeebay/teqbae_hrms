import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_event.dart';
import 'package:teqbae_hrms/features/sync/presentation/bloc/sync_state.dart';
import 'package:teqbae_hrms/features/sync/presentation/pages/sync_status_page.dart';

class MockSyncBloc extends MockBloc<SyncEvent, SyncState> implements SyncBloc {}

void main() {
  late MockSyncBloc mockSyncBloc;

  setUp(() {
    mockSyncBloc = MockSyncBloc();
  });

  Widget buildSubject(SyncBloc syncBloc) {
    return MaterialApp(
      home: BlocProvider<SyncBloc>.value(
        value: syncBloc,
        child: const SyncStatusPage(),
      ),
    );
  }

  testWidgets('shows Pending Sync chip and pending event count when events are pending', (tester) async {
    final pendingEvent = AttendanceEvent(
      clientEventId: 'evt-test-pending',
      type: AttendanceEventType.checkIn,
      occurredAt: DateTime.utc(2026, 11, 19, 9, 30),
      companyDate: '2026-11-19',
      latitude: 9.9312,
      longitude: 76.2673,
      status: AttendanceEventStatus.pending,
      attempts: 1,
    );

    when(() => mockSyncBloc.state).thenReturn(SyncState(
      pendingCount: 1,
      allEvents: [pendingEvent],
    ));

    await tester.pumpWidget(buildSubject(mockSyncBloc));
    await tester.pump();

    expect(find.byKey(const Key('pending_sync_chip')), findsOneWidget);
    expect(find.text('Pending Events: 1'), findsOneWidget);
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Check-in'), findsOneWidget);
  });

  testWidgets('shows Synced and Rejected chips for completed events', (tester) async {
    final syncedEvent = AttendanceEvent(
      clientEventId: 'evt-synced',
      type: AttendanceEventType.checkIn,
      occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
      companyDate: '2026-11-19',
      latitude: 9.9312,
      longitude: 76.2673,
      status: AttendanceEventStatus.synced,
    );
    final rejectedEvent = AttendanceEvent(
      clientEventId: 'evt-rejected',
      type: AttendanceEventType.checkOut,
      occurredAt: DateTime.utc(2026, 11, 19, 17, 0),
      companyDate: '2026-11-19',
      latitude: 9.9312,
      longitude: 76.2673,
      status: AttendanceEventStatus.rejected,
      lastError: 'Outside geofence radius',
    );

    when(() => mockSyncBloc.state).thenReturn(SyncState(
      allEvents: [syncedEvent, rejectedEvent],
    ));

    await tester.pumpWidget(buildSubject(mockSyncBloc));
    await tester.pump();

    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Outside geofence radius'), findsOneWidget);
  });
}
