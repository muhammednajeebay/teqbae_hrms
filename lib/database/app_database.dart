import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

part 'app_database.g.dart';

@DataClassName('EmployeeCacheRow')
class EmployeeCaches extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get department => text()();
  RealColumn get officeLatitude => real()();
  RealColumn get officeLongitude => real()();
  RealColumn get officeRadiusMeters => real()();
  TextColumn get companyTimeZone => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AttendanceRecordRow')
class AttendanceRecords extends Table {
  TextColumn get companyDate => text()();
  DateTimeColumn get checkInAt => dateTime().nullable()();
  DateTimeColumn get checkOutAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {companyDate};
}

@DataClassName('AttendanceEventRow')
class AttendanceEvents extends Table {
  IntColumn get sequence => integer().autoIncrement()();
  TextColumn get clientEventId => text().unique()();
  TextColumn get type => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get companyDate => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real().nullable()();
  BoolColumn get isMockedLocation => boolean().withDefault(const Constant(false))();
  TextColumn get status => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class LeaveRequestRows extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get reason => text()();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LeaveBalanceRows extends Table {
  IntColumn get singletonId => integer().withDefault(const Constant(1))();
  IntColumn get availableDays => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}

@DriftDatabase(tables: [EmployeeCaches, AttendanceRecords, AttendanceEvents, LeaveRequestRows, LeaveBalanceRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'rebs_hrms'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // Employee Cache
  Future<void> cacheEmployee(Employee employee) {
    return into(employeeCaches).insertOnConflictUpdate(
      EmployeeCachesCompanion.insert(
        id: employee.id,
        name: employee.name,
        department: employee.department,
        officeLatitude: employee.officeLocation.latitude,
        officeLongitude: employee.officeLocation.longitude,
        officeRadiusMeters: employee.officeLocation.radiusMeters,
        companyTimeZone: employee.companyTimeZone,
        cachedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<Employee?> getCachedEmployee() async {
    final row = await select(employeeCaches).getSingleOrNull();
    if (row == null) return null;
    return Employee(
      id: row.id,
      name: row.name,
      department: row.department,
      officeLocation: OfficeConfig(
        latitude: row.officeLatitude,
        longitude: row.officeLongitude,
        radiusMeters: row.officeRadiusMeters,
      ),
      companyTimeZone: row.companyTimeZone,
    );
  }

  Stream<Employee?> watchCachedEmployee() {
    return select(employeeCaches).watchSingleOrNull().map((row) {
      if (row == null) return null;
      return Employee(
        id: row.id,
        name: row.name,
        department: row.department,
        officeLocation: OfficeConfig(
          latitude: row.officeLatitude,
          longitude: row.officeLongitude,
          radiusMeters: row.officeRadiusMeters,
        ),
        companyTimeZone: row.companyTimeZone,
      );
    });
  }

  // Attendance Events (Outbox)
  Future<void> saveAttendanceEvent(AttendanceEvent event) {
    return transaction(() async {
      await into(attendanceEvents).insert(AttendanceEventsCompanion.insert(
        clientEventId: event.clientEventId,
        type: event.type.name,
        occurredAt: event.occurredAt.toUtc(),
        companyDate: event.companyDate,
        latitude: event.latitude,
        longitude: event.longitude,
        accuracy: Value(event.accuracy),
        isMockedLocation: Value(event.isMockedLocation),
        status: event.status.name,
        attempts: Value(event.attempts),
        lastError: Value(event.lastError),
        createdAt: DateTime.now().toUtc(),
      ));
    });
  }

  Future<List<AttendanceEvent>> pendingEvents() async {
    final rows = await (select(attendanceEvents)
          ..where((row) => row.status.equals(AttendanceEventStatus.pending.name))
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .get();
    return rows.map(_eventFromRow).toList();
  }

  Stream<List<AttendanceEvent>> watchPendingEvents() {
    return (select(attendanceEvents)
          ..where((row) => row.status.equals(AttendanceEventStatus.pending.name))
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .watch()
        .map((rows) => rows.map(_eventFromRow).toList());
  }

  Future<List<AttendanceEvent>> allEvents() async {
    final rows = await (select(attendanceEvents)
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .get();
    return rows.map(_eventFromRow).toList();
  }

  Stream<List<AttendanceEvent>> watchAllEvents() {
    return (select(attendanceEvents)
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .watch()
        .map((rows) => rows.map(_eventFromRow).toList());
  }

  Future<void> updateEventStatus({
    required String clientEventId,
    required AttendanceEventStatus status,
    String? error,
    int? attempts,
  }) {
    return (update(attendanceEvents)..where((row) => row.clientEventId.equals(clientEventId))).write(
      AttendanceEventsCompanion(
        status: Value(status.name),
        attempts: attempts != null ? Value(attempts) : const Value.absent(),
        lastError: Value(error),
      ),
    );
  }

  Future<List<AttendanceEvent>> eventsForDate(String companyDate) async {
    final rows = await (select(attendanceEvents)
          ..where((row) => row.companyDate.equals(companyDate))
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .get();
    return rows.map(_eventFromRow).toList();
  }

  AttendanceEvent _eventFromRow(AttendanceEventRow row) => AttendanceEvent(
        sequence: row.sequence,
        clientEventId: row.clientEventId,
        type: AttendanceEventType.values.byName(row.type),
        occurredAt: row.occurredAt,
        companyDate: row.companyDate,
        latitude: row.latitude,
        longitude: row.longitude,
        accuracy: row.accuracy,
        isMockedLocation: row.isMockedLocation,
        status: AttendanceEventStatus.values.byName(row.status),
        attempts: row.attempts,
        lastError: row.lastError,
      );

  // Attendance Records
  Future<void> replaceAttendanceRecords(Iterable<AttendanceRecord> records) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        attendanceRecords,
        records.map((record) => AttendanceRecordsCompanion.insert(
              companyDate: record.companyDate,
              checkInAt: Value(record.checkInAt),
              checkOutAt: Value(record.checkOutAt),
            )),
      );
    });
  }

  Future<List<AttendanceRecord>> attendanceForMonth(String month) async {
    final rows = await (select(attendanceRecords)
          ..where((row) => row.companyDate.like('$month%'))
          ..orderBy([(row) => OrderingTerm.desc(row.companyDate)]))
        .get();
    return rows.map(_recordFromRow).toList();
  }

  Stream<List<AttendanceRecord>> watchAttendanceForMonth(String month) {
    return (select(attendanceRecords)
          ..where((row) => row.companyDate.like('$month%'))
          ..orderBy([(row) => OrderingTerm.desc(row.companyDate)]))
        .watch()
        .map((rows) => rows.map(_recordFromRow).toList());
  }

  Future<AttendanceRecord?> todayRecord(String companyDate) async {
    final row = await (select(attendanceRecords)..where((row) => row.companyDate.equals(companyDate))).getSingleOrNull();
    return row != null ? _recordFromRow(row) : null;
  }

  AttendanceRecord _recordFromRow(AttendanceRecordRow row) => AttendanceRecord(
        companyDate: row.companyDate,
        checkInAt: row.checkInAt,
        checkOutAt: row.checkOutAt,
      );

  // Leave Requests
  Future<void> replaceLeaveRequests(Iterable<LeaveRequest> requests) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        leaveRequestRows,
        requests.map((request) => LeaveRequestRowsCompanion.insert(
              id: request.id,
              type: request.type.name,
              startDate: request.startDate,
              endDate: request.endDate,
              reason: request.reason,
              status: request.status.name,
            )),
      );
    });
  }

  Future<List<LeaveRequest>> getCachedLeaveRequests() async {
    final rows = await (select(leaveRequestRows)..orderBy([(row) => OrderingTerm.desc(row.startDate)])).get();
    return rows.map(_leaveFromRow).toList();
  }

  Stream<List<LeaveRequest>> watchLeaveRequests() {
    return (select(leaveRequestRows)..orderBy([(row) => OrderingTerm.desc(row.startDate)]))
        .watch()
        .map((rows) => rows.map(_leaveFromRow).toList());
  }

  LeaveRequest _leaveFromRow(LeaveRequestRow row) => LeaveRequest(
        id: row.id,
        type: LeaveType.values.byName(row.type),
        startDate: row.startDate,
        endDate: row.endDate,
        reason: row.reason,
        status: LeaveStatus.values.byName(row.status),
      );

  // Leave Balance
  Future<void> cacheLeaveBalance(LeaveBalance balance) {
    return into(leaveBalanceRows).insertOnConflictUpdate(
      LeaveBalanceRowsCompanion.insert(
        singletonId: const Value(1),
        availableDays: balance.availableDays,
        updatedAt: balance.updatedAt.toUtc(),
      ),
    );
  }

  Future<LeaveBalance?> getCachedLeaveBalance() async {
    final row = await (select(leaveBalanceRows)..where((row) => row.singletonId.equals(1))).getSingleOrNull();
    if (row == null) return null;
    return LeaveBalance(availableDays: row.availableDays, updatedAt: row.updatedAt);
  }

  Stream<LeaveBalance?> watchLeaveBalance() {
    return (select(leaveBalanceRows)..where((row) => row.singletonId.equals(1))).watchSingleOrNull().map((row) {
      if (row == null) return null;
      return LeaveBalance(availableDays: row.availableDays, updatedAt: row.updatedAt);
    });
  }
}
