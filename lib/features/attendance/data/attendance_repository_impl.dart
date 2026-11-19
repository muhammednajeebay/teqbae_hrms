import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/core/network/connectivity_service.dart';
import 'package:teqbae_hrms/core/network/rebs_api.dart';
import 'package:teqbae_hrms/database/app_database.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl({
    required RebsApi api,
    required AppDatabase database,
    required ConnectivityService connectivity,
  })  : _api = api,
        _database = database,
        _connectivity = connectivity;

  final RebsApi _api;
  final AppDatabase _database;
  final ConnectivityService _connectivity;

  @override
  Future<Result<List<AttendanceRecord>>> getAttendance(String month, {bool forceRefresh = false}) async {
    final cached = await _database.attendanceForMonth(month);
    final isOnline = await _connectivity.isOnline;

    if (!isOnline) {
      return Success(cached);
    }

    if (!forceRefresh && cached.isNotEmpty) {
      _refreshAttendance(month);
      return Success(cached);
    }

    final result = await _api.attendance(month);
    if (result is Success<List<AttendanceRecord>>) {
      await _database.replaceAttendanceRecords(result.value);
      return result;
    } else if (cached.isNotEmpty) {
      return Success(cached);
    }
    return result;
  }

  @override
  Stream<List<AttendanceRecord>> watchAttendance(String month) => _database.watchAttendanceForMonth(month);

  @override
  Future<Result<void>> recordEvent(AttendanceEvent event) async {
    try {
      await _database.saveAttendanceEvent(event);
      return const Success(null);
    } catch (e) {
      return FailureResult(StorageFailure('Failed to save attendance event locally: $e'));
    }
  }

  @override
  Future<List<AttendanceEvent>> getPendingEvents() => _database.pendingEvents();

  @override
  Stream<List<AttendanceEvent>> watchPendingEvents() => _database.watchPendingEvents();

  @override
  Future<List<AttendanceEvent>> getAllEvents() => _database.allEvents();

  @override
  Stream<List<AttendanceEvent>> watchAllEvents() => _database.watchAllEvents();

  @override
  Future<void> updateEventStatus({
    required String clientEventId,
    required AttendanceEventStatus status,
    String? error,
    int? attempts,
  }) {
    return _database.updateEventStatus(
      clientEventId: clientEventId,
      status: status,
      error: error,
      attempts: attempts,
    );
  }

  @override
  Future<List<AttendanceEvent>> getEventsForDate(String companyDate) => _database.eventsForDate(companyDate);

  @override
  Future<AttendanceRecord?> getTodayRecord(String companyDate) => _database.todayRecord(companyDate);

  Future<void> _refreshAttendance(String month) async {
    final result = await _api.attendance(month);
    if (result is Success<List<AttendanceRecord>>) {
      await _database.replaceAttendanceRecords(result.value);
    }
  }
}
