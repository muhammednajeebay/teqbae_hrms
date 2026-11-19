import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:teqbae_hrms/core/config/app_config.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_api_client.dart';

class RebsApi implements SyncApiClient {
  RebsApi(AppConfig config, {Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.apiBaseUrl,
                connectTimeout: config.connectTimeout,
                receiveTimeout: config.receiveTimeout,
                headers: const {'content-type': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<Result<Employee>> getEmployee() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/employee/me');
      final data = response.data;
      if (data == null) {
        return const FailureResult(ServerFailure('Empty employee data received from server.'));
      }
      final officeMap = data['office'] as Map<String, dynamic>? ?? {};
      final employee = Employee(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        department: data['department'] as String? ?? '',
        companyTimeZone: data['companyTimeZone'] as String? ?? 'Asia/Kolkata',
        officeLocation: OfficeConfig(
          latitude: (officeMap['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (officeMap['longitude'] as num?)?.toDouble() ?? 0.0,
          radiusMeters: (officeMap['radiusMeters'] as num?)?.toDouble() ?? 200.0,
        ),
      );
      return Success(employee);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  Future<Result<List<AttendanceRecord>>> attendance(String month) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/attendance',
        queryParameters: {'month': month},
      );
      final records = (response.data?['records'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map((json) => AttendanceRecord(
                companyDate: json['companyDate'] as String,
                checkInAt: _date(json['checkInAt']),
                checkOutAt: _date(json['checkOutAt']),
              ))
          .toList();
      return Success(records);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  @override
  Future<Result<bool>> postAttendanceEvent(AttendanceEvent event) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/attendance/events',
        data: {
          'clientEventId': event.clientEventId,
          'type': event.type == AttendanceEventType.checkIn ? 'check_in' : 'check_out',
          'occurredAt': event.occurredAt.toUtc().toIso8601String(),
          'companyDate': event.companyDate,
          'latitude': event.latitude,
          'longitude': event.longitude,
          'accuracy': event.accuracy,
          'isMockedLocation': event.isMockedLocation,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Success(true);
      }
      return FailureResult(ServerFailure('Unexpected server response.', statusCode: response.statusCode));
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  Future<Result<LeaveBalance>> getLeaveBalance() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/leave/balance');
      final data = response.data;
      if (data == null) {
        return const FailureResult(ServerFailure('Empty leave balance data received from server.'));
      }
      final balance = LeaveBalance(
        availableDays: data['availableDays'] as int? ?? 0,
        updatedAt: _date(data['updatedAt']) ?? DateTime.now().toUtc(),
      );
      return Success(balance);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  Future<Result<List<LeaveRequest>>> getLeaveRequests() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/leave/requests');
      final requestsJson = (response.data?['requests'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final requests = requestsJson.map(_parseLeaveRequest).toList();
      return Success(requests);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  Future<Result<LeaveRequest>> postLeaveRequest({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      final formatter = DateFormat('yyyy-MM-dd');
      final response = await _dio.post<Map<String, dynamic>>(
        '/leave/requests',
        data: {
          'type': type == LeaveType.casual ? 'Casual' : 'Sick',
          'startDate': formatter.format(startDate),
          'endDate': formatter.format(endDate),
          'reason': reason,
        },
      );
      final data = response.data;
      if (data == null) {
        return const FailureResult(ServerFailure('Empty response on leave submission.'));
      }
      return Success(_parseLeaveRequest(data));
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  Future<Result<String>> getScenario() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/__scenario');
      final mode = response.data?['mode'] as String? ?? 'success';
      return Success(mode);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  Future<Result<String>> setScenario(String mode) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/__scenario', data: {'mode': mode});
      final updated = response.data?['mode'] as String? ?? mode;
      return Success(updated);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  Future<Result<void>> resetServer() async {
    try {
      await _dio.post<Map<String, dynamic>>('/__reset');
      return const Success(null);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  LeaveRequest _parseLeaveRequest(Map<String, dynamic> json) {
    final typeString = (json['type'] as String? ?? 'Casual').toLowerCase();
    final statusString = (json['status'] as String? ?? 'Pending').toLowerCase();

    final type = typeString == 'sick' ? LeaveType.sick : LeaveType.casual;
    final status = statusString == 'approved'
        ? LeaveStatus.approved
        : statusString == 'rejected'
            ? LeaveStatus.rejected
            : LeaveStatus.pending;

    return LeaveRequest(
      id: json['id'] as String? ?? '',
      type: type,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      reason: json['reason'] as String? ?? '',
      status: status,
    );
  }

  Failure _mapError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkFailure('Could not reach the server.');
    }
    final data = error.response?.data;
    final message = data is Map<String, dynamic>
        ? data['message'] as String? ?? 'Server request failed.'
        : 'Server request failed.';
    final code = data is Map<String, dynamic> ? data['code'] as String? : null;
    return ServerFailure(message, statusCode: error.response?.statusCode, code: code);
  }

  DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
