import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';

part 'app_database.g.dart';

/// Database table for caching the employee profile locally.
///
/// Stores employee identification, company timezone, and office geofence coordinates
/// so the app can function immediately when launched offline.
@DataClassName('EmployeeCacheRow')
class EmployeeCaches extends Table {
  /// Unique employee ID from the server (e.g. 'EMP001').
  TextColumn get id => text()();

  /// Employee's full name.
  TextColumn get name => text()();

  /// Department name the employee belongs to.
  TextColumn get department => text()();

  /// Latitude of the assigned office building.
  RealColumn get officeLatitude => real()();

  /// Longitude of the assigned office building.
  RealColumn get officeLongitude => real()();

  /// Geofence radius in meters around the office.
  RealColumn get officeRadiusMeters => real()();

  /// Company's local timezone (e.g. 'Asia/Kolkata').
  TextColumn get companyTimeZone => text()();

  /// When this profile was cached locally in UTC.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Database table for storing confirmed attendance records synced from the server.
@DataClassName('AttendanceRecordRow')
class AttendanceRecords extends Table {
  /// The company-local calendar date formatted as 'yyyy-MM-dd'.
  TextColumn get companyDate => text()();

  /// UTC timestamp of the employee's check-in, or null if absent.
  DateTimeColumn get checkInAt => dateTime().nullable()();

  /// UTC timestamp of the employee's check-out, or null if not yet checked out.
  DateTimeColumn get checkOutAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {companyDate};
}

/// Database table representing the offline outbox queue for attendance events.
///
/// Check-in and check-out taps are immediately saved here with status 'pending'.
/// The sync service reads this table ordered by [sequence] to send events in strict chronological order.
@DataClassName('AttendanceEventRow')
class AttendanceEvents extends Table {
  /// Auto-incrementing sequence number ensuring strict FIFO order of events.
  IntColumn get sequence => integer().autoIncrement()();

  /// Unique client-generated UUID used for idempotent server requests.
  TextColumn get clientEventId => text().unique()();

  /// Type of attendance event ('checkIn' or 'checkOut').
  TextColumn get type => text()();

  /// The exact moment the user tapped check-in or check-out in UTC.
  DateTimeColumn get occurredAt => dateTime()();

  /// The company calendar date formatted as 'yyyy-MM-dd'.
  TextColumn get companyDate => text()();

  /// Device GPS latitude recorded at the time of the action.
  RealColumn get latitude => real()();

  /// Device GPS longitude recorded at the time of the action.
  RealColumn get longitude => real()();

  /// Horizontal accuracy in meters from GPS reading.
  RealColumn get accuracy => real().nullable()();

  /// Whether the location came from a mock/simulated GPS provider.
  BoolColumn get isMockedLocation => boolean().withDefault(const Constant(false))();

  /// Sync lifecycle status ('pending', 'synced', or 'rejected').
  TextColumn get status => text()();

  /// How many times sync has attempted to deliver this event.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Error message returned from the most recent failed sync attempt.
  TextColumn get lastError => text().nullable()();

  /// When this record was created in the local database.
  DateTimeColumn get createdAt => dateTime()();
}

/// Database table for caching submitted leave requests offline.
class LeaveRequestRows extends Table {
  /// Unique leave request identifier from the server.
  TextColumn get id => text()();

  /// Type of leave ('casual' or 'sick').
  TextColumn get type => text()();

  /// First day of the leave period.
  DateTimeColumn get startDate => dateTime()();

  /// Last day of the leave period.
  DateTimeColumn get endDate => dateTime()();

  /// Explanation reason provided by the employee.
  TextColumn get reason => text()();

  /// Current approval status ('pending', 'approved', or 'rejected').
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Database table for caching the single leave balance summary offline.
class LeaveBalanceRows extends Table {
  /// Fixed primary key of 1 to ensure only a single balance row is stored.
  IntColumn get singletonId => integer().withDefault(const Constant(1))();

  /// Available remaining leave days.
  IntColumn get availableDays => integer()();

  /// UTC timestamp of when this balance was last updated by the server.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}

/// The local Drift SQLite database for the REBS HRMS app.
///
/// Manages offline storage for:
/// - Employee profile caching.
/// - Attendance records and local outbox queue.
/// - Leave requests and available balance cache.
@DriftDatabase(tables: [EmployeeCaches, AttendanceRecords, AttendanceEvents, LeaveRequestRows, LeaveBalanceRows])
class AppDatabase extends _$AppDatabase {
  /// Creates the database backed by a persistent SQLite file on disk named 'rebs_hrms'.
  AppDatabase() : super(driftDatabase(name: 'rebs_hrms'));

  /// Creates an in-memory database instance for isolated testing.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // ── Employee Cache ────────────────────────────────────────────────────────

  /// Saves or updates the employee profile in the local cache.
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

  /// Retrieves the single cached employee profile, or `null` if the cache is empty.
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

  /// Observes changes to the cached employee profile as a live stream.
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

  // ── Attendance Events (Outbox) ─────────────────────────────────────────────

  /// Inserts a new attendance event into the outbox in an atomic transaction.
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

  /// Fetches all pending attendance events waiting to sync, ordered oldest first.
  Future<List<AttendanceEvent>> pendingEvents() async {
    final rows = await (select(attendanceEvents)
          ..where((row) => row.status.equals(AttendanceEventStatus.pending.name))
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .get();
    return rows.map(_eventFromRow).toList();
  }

  /// Observes pending attendance events as a live stream.
  Stream<List<AttendanceEvent>> watchPendingEvents() {
    return (select(attendanceEvents)
          ..where((row) => row.status.equals(AttendanceEventStatus.pending.name))
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .watch()
        .map((rows) => rows.map(_eventFromRow).toList());
  }

  /// Returns all attendance events in the outbox (pending, synced, rejected), ordered oldest first.
  Future<List<AttendanceEvent>> allEvents() async {
    final rows = await (select(attendanceEvents)
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .get();
    return rows.map(_eventFromRow).toList();
  }

  /// Observes all attendance events as a live stream.
  Stream<List<AttendanceEvent>> watchAllEvents() {
    return (select(attendanceEvents)
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .watch()
        .map((rows) => rows.map(_eventFromRow).toList());
  }

  /// Updates the sync status, error, and attempt count of a specific event by clientEventId.
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

  /// Returns all events (pending, synced, rejected) for a specific company date.
  Future<List<AttendanceEvent>> eventsForDate(String companyDate) async {
    final rows = await (select(attendanceEvents)
          ..where((row) => row.companyDate.equals(companyDate))
          ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
        .get();
    return rows.map(_eventFromRow).toList();
  }

  /// Converts an SQLite row into an [AttendanceEvent] domain model.
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

  // ── Attendance Records ─────────────────────────────────────────────────────

  /// Inserts or updates multiple confirmed attendance records in batch.
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

  /// Returns attendance records for a specific month prefix ('yyyy-MM'), newest first.
  Future<List<AttendanceRecord>> attendanceForMonth(String month) async {
    final rows = await (select(attendanceRecords)
          ..where((row) => row.companyDate.like('$month%'))
          ..orderBy([(row) => OrderingTerm.desc(row.companyDate)]))
        .get();
    return rows.map(_recordFromRow).toList();
  }

  /// Observes attendance records for a specific month as a live stream.
  Stream<List<AttendanceRecord>> watchAttendanceForMonth(String month) {
    return (select(attendanceRecords)
          ..where((row) => row.companyDate.like('$month%'))
          ..orderBy([(row) => OrderingTerm.desc(row.companyDate)]))
        .watch()
        .map((rows) => rows.map(_recordFromRow).toList());
  }

  /// Retrieves the attendance record for a specific day, or `null` if none exists.
  Future<AttendanceRecord?> todayRecord(String companyDate) async {
    final row = await (select(attendanceRecords)..where((row) => row.companyDate.equals(companyDate))).getSingleOrNull();
    return row != null ? _recordFromRow(row) : null;
  }

  /// Converts an SQLite row into an [AttendanceRecord] domain model.
  AttendanceRecord _recordFromRow(AttendanceRecordRow row) => AttendanceRecord(
        companyDate: row.companyDate,
        checkInAt: row.checkInAt,
        checkOutAt: row.checkOutAt,
      );

  // ── Leave Requests ─────────────────────────────────────────────────────────

  /// Replaces all cached leave requests with a fresh batch from the server.
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

  /// Returns all cached leave requests ordered newest first.
  Future<List<LeaveRequest>> getCachedLeaveRequests() async {
    final rows = await (select(leaveRequestRows)..orderBy([(row) => OrderingTerm.desc(row.startDate)])).get();
    return rows.map(_leaveFromRow).toList();
  }

  /// Observes cached leave requests as a live stream.
  Stream<List<LeaveRequest>> watchLeaveRequests() {
    return (select(leaveRequestRows)..orderBy([(row) => OrderingTerm.desc(row.startDate)]))
        .watch()
        .map((rows) => rows.map(_leaveFromRow).toList());
  }

  /// Converts an SQLite row into a [LeaveRequest] domain model.
  LeaveRequest _leaveFromRow(LeaveRequestRow row) => LeaveRequest(
        id: row.id,
        type: LeaveType.values.byName(row.type),
        startDate: row.startDate,
        endDate: row.endDate,
        reason: row.reason,
        status: LeaveStatus.values.byName(row.status),
      );

  // ── Leave Balance ──────────────────────────────────────────────────────────

  /// Updates the cached leave balance in the singleton row.
  Future<void> cacheLeaveBalance(LeaveBalance balance) {
    return into(leaveBalanceRows).insertOnConflictUpdate(
      LeaveBalanceRowsCompanion.insert(
        singletonId: const Value(1),
        availableDays: balance.availableDays,
        updatedAt: balance.updatedAt.toUtc(),
      ),
    );
  }

  /// Returns the cached leave balance, or `null` if not yet loaded.
  Future<LeaveBalance?> getCachedLeaveBalance() async {
    final row = await (select(leaveBalanceRows)..where((row) => row.singletonId.equals(1))).getSingleOrNull();
    if (row == null) return null;
    return LeaveBalance(availableDays: row.availableDays, updatedAt: row.updatedAt);
  }

  /// Observes the cached leave balance as a live stream.
  Stream<LeaveBalance?> watchLeaveBalance() {
    return (select(leaveBalanceRows)..where((row) => row.singletonId.equals(1))).watchSingleOrNull().map((row) {
      if (row == null) return null;
      return LeaveBalance(availableDays: row.availableDays, updatedAt: row.updatedAt);
    });
  }
}
