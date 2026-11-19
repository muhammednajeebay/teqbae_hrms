import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

abstract interface class AttendanceRepository {
  Future<Result<List<AttendanceRecord>>> getAttendance(String month, {bool forceRefresh = false});
  Stream<List<AttendanceRecord>> watchAttendance(String month);
  Future<Result<void>> recordEvent(AttendanceEvent event);
  Future<List<AttendanceEvent>> getPendingEvents();
  Stream<List<AttendanceEvent>> watchPendingEvents();
  Future<List<AttendanceEvent>> getAllEvents();
  Stream<List<AttendanceEvent>> watchAllEvents();
  Future<void> updateEventStatus({
    required String clientEventId,
    required AttendanceEventStatus status,
    String? error,
    int? attempts,
  });
  Future<List<AttendanceEvent>> getEventsForDate(String companyDate);
  Future<AttendanceRecord?> getTodayRecord(String companyDate);
}
