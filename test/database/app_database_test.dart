import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('AppDatabase - AttendanceEvents Outbox', () {
    test('saves attendance event and retrieves pending events in sequence order', () async {
      final event1 = AttendanceEvent(
        clientEventId: 'evt-1',
        type: AttendanceEventType.checkIn,
        occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );
      final event2 = AttendanceEvent(
        clientEventId: 'evt-2',
        type: AttendanceEventType.checkOut,
        occurredAt: DateTime.utc(2026, 11, 19, 17, 30),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );

      await database.saveAttendanceEvent(event1);
      await database.saveAttendanceEvent(event2);

      final pending = await database.pendingEvents();
      expect(pending.length, 2);
      expect(pending[0].clientEventId, 'evt-1');
      expect(pending[1].clientEventId, 'evt-2');
      expect(pending[0].sequence, isNotNull);
      expect(pending[1].sequence, isNotNull);
      expect(pending[0].sequence! < pending[1].sequence!, isTrue);
    });

    test('updateEventStatus updates status, error and attempts', () async {
      final event = AttendanceEvent(
        clientEventId: 'evt-test',
        type: AttendanceEventType.checkIn,
        occurredAt: DateTime.utc(2026, 11, 19, 9, 0),
        companyDate: '2026-11-19',
        latitude: 9.9312,
        longitude: 76.2673,
        status: AttendanceEventStatus.pending,
      );

      await database.saveAttendanceEvent(event);
      await database.updateEventStatus(
        clientEventId: 'evt-test',
        status: AttendanceEventStatus.synced,
        attempts: 1,
      );

      final pending = await database.pendingEvents();
      expect(pending, isEmpty);

      final all = await database.allEvents();
      expect(all.length, 1);
      expect(all.first.status, AttendanceEventStatus.synced);
      expect(all.first.attempts, 1);
    });
  });

  group('AppDatabase - Employee Cache', () {
    test('caches employee and retrieves from database', () async {
      const employee = Employee(
        id: 'EMP-001',
        name: 'Aarav Patel',
        department: 'Engineering',
        officeLocation: OfficeConfig(
          latitude: 9.9312,
          longitude: 76.2673,
          radiusMeters: 200,
        ),
        companyTimeZone: 'Asia/Kolkata',
      );

      await database.cacheEmployee(employee);
      final cached = await database.getCachedEmployee();

      expect(cached, isNotNull);
      expect(cached!.id, 'EMP-001');
      expect(cached.name, 'Aarav Patel');
      expect(cached.officeLocation.latitude, 9.9312);
    });
  });

  group('AppDatabase - Attendance Records', () {
    test('replaces and queries attendance records by month', () async {
      final records = [
        const AttendanceRecord(
          companyDate: '2026-11-18',
          checkInAt: null,
          checkOutAt: null,
        ),
        const AttendanceRecord(
          companyDate: '2026-11-19',
          checkInAt: null,
          checkOutAt: null,
        ),
        const AttendanceRecord(
          companyDate: '2026-10-15',
          checkInAt: null,
          checkOutAt: null,
        ),
      ];

      await database.replaceAttendanceRecords(records);

      final novRecords = await database.attendanceForMonth('2026-11');
      expect(novRecords.length, 2);

      final octRecords = await database.attendanceForMonth('2026-10');
      expect(octRecords.length, 1);
    });
  });

  group('AppDatabase - Leave Cache', () {
    test('caches leave balance and requests', () async {
      final balance = LeaveBalance(
        availableDays: 14,
        updatedAt: DateTime.utc(2026, 11, 19),
      );
      final requests = [
        LeaveRequest(
          id: 'leave-1',
          type: LeaveType.casual,
          startDate: DateTime.utc(2026, 12, 1),
          endDate: DateTime.utc(2026, 12, 2),
          reason: 'Short family vacation',
          status: LeaveStatus.pending,
        ),
      ];

      await database.cacheLeaveBalance(balance);
      await database.replaceLeaveRequests(requests);

      final cachedBalance = await database.getCachedLeaveBalance();
      final cachedRequests = await database.getCachedLeaveRequests();

      expect(cachedBalance?.availableDays, 14);
      expect(cachedRequests.length, 1);
      expect(cachedRequests.first.reason, 'Short family vacation');
    });
  });
}
