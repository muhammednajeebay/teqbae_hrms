import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:teqbae_hrms/core/config/app_config.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';
import 'package:teqbae_hrms/features/employee/domain/employee.dart';
import 'package:teqbae_hrms/features/leave/domain/leave.dart';
import 'package:teqbae_hrms/features/sync/domain/sync_api_client.dart';

/// HTTP client that talks to the REBS API (or the Shelf mock server during
/// development).
///
/// Every public method returns a [Result] — it never throws. Network and HTTP
/// errors are caught and mapped to typed [Failure] subclasses so the calling
/// code does not need try/catch blocks.
///
/// [RebsApi] also implements [SyncApiClient] so the [SyncService] only depends
/// on the narrow interface it actually needs.
class RebsApi implements SyncApiClient {
  /// Creates a [RebsApi] configured with the given [AppConfig].
  ///
  /// A custom [Dio] instance can be passed for testing (e.g. with a mock
  /// adapter). If omitted, a default Dio client is created with the base URL
  /// and timeouts from [config].
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

  // ── Employee ─────────────────────────────────────────────────────────────

  /// Fetches the profile of the currently authenticated employee.
  ///
  /// `GET /employee/me`
  ///
  /// Returns a [Success] with the [Employee] on HTTP 200, or a
  /// [FailureResult] with a [ServerFailure] if the response body is empty.
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

  // ── Attendance ───────────────────────────────────────────────────────────

  /// Fetches attendance records for the given [month] (format: `yyyy-MM`).
  ///
  /// `GET /attendance?month=yyyy-MM`
  ///
  /// Returns a list of [AttendanceRecord] objects. The list may be empty if the
  /// employee had no activity in that month.
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

  /// Sends a single attendance event (check-in or check-out) to the server.
  ///
  /// `POST /attendance/events`
  ///
  /// The server uses [AttendanceEvent.clientEventId] to detect duplicates.
  /// If the same event is sent twice, the server returns HTTP 200 with
  /// `duplicate: true` — the app treats both 200 and 201 as success.
  ///
  /// This method is part of the [SyncApiClient] interface used by [SyncService].
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

  // ── Leave ────────────────────────────────────────────────────────────────

  /// Fetches the employee's current leave balance.
  ///
  /// `GET /leave/balance`
  ///
  /// Returns a [LeaveBalance] with the number of available leave days.
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

  /// Fetches all leave requests submitted by the employee.
  ///
  /// `GET /leave/requests`
  ///
  /// Returns a list of [LeaveRequest] objects in the order the server provides
  /// them (typically newest first).
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

  /// Submits a new leave request to the server.
  ///
  /// `POST /leave/requests`
  ///
  /// Dates are formatted as `yyyy-MM-dd` strings.
  /// The server validates the request and returns HTTP 422 with an error
  /// message if any server-side rule is violated.
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

  // ── Debug / Mock-server control endpoints ────────────────────────────────

  /// Reads the currently active mock server scenario.
  ///
  /// `GET /__scenario`
  ///
  /// Returns the scenario mode string (e.g. `'success'`, `'timeout'`).
  /// Only meaningful when talking to the Shelf mock server.
  Future<Result<String>> getScenario() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/__scenario');
      final mode = response.data?['mode'] as String? ?? 'success';
      return Success(mode);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  /// Switches the mock server to the given failure [mode].
  ///
  /// `POST /__scenario` with body `{"mode": "<mode>"}`
  ///
  /// Valid modes: `success`, `slow`, `timeout`, `accept_then_timeout`,
  /// `server_error`, `duplicate_conflict`, `leave_rejected`.
  Future<Result<String>> setScenario(String mode) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/__scenario', data: {'mode': mode});
      final updated = response.data?['mode'] as String? ?? mode;
      return Success(updated);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  /// Resets all mock server state back to its initial seed data.
  ///
  /// `POST /__reset`
  ///
  /// Clears all submitted leave requests, attendance events, and returns the
  /// scenario to `'success'` mode.
  Future<Result<void>> resetServer() async {
    try {
      await _dio.post<Map<String, dynamic>>('/__reset');
      return const Success(null);
    } on DioException catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Parses a leave request JSON map into a [LeaveRequest] domain object.
  ///
  /// Applies safe defaults for any missing or unrecognised field values.
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

  /// Converts a [DioException] into a typed [Failure].
  ///
  /// - Connection, receive, and send timeouts → [NetworkFailure]
  /// - Connection errors (no route to host) → [NetworkFailure]
  /// - Everything else (4xx / 5xx) → [ServerFailure] with the HTTP status code
  ///   and the `message` / `code` fields from the JSON response body.
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

  /// Parses an ISO 8601 date string into a UTC [DateTime], or returns `null`
  /// if the value is not a valid date string.
  DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
