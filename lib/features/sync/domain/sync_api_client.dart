import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

abstract interface class SyncApiClient {
  Future<Result<bool>> postAttendanceEvent(AttendanceEvent event);
}
