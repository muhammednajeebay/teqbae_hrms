import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

/// Common JSON response headers including Cross-Origin Resource Sharing (CORS) support.
const _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
  'access-control-allow-origin': '*',
};

/// Default office GPS latitude (Kochi office).
const _officeLatitude = 9.9312;

/// Default office GPS longitude (Kochi office).
const _officeLongitude = 76.2673;

/// Maximum allowed distance from office in meters (200m).
const _officeRadiusMeters = 200.0;

/// The singleton in-memory mock database store.
final _store = _MockStore();

/// Starts the REBS HRMS mock backend server on port 8080.
///
/// Sets up:
/// - REST endpoints for employee, attendance, and leave.
/// - Testing scenario endpoints (`/__scenario`, `/__reset`).
/// - Request logging and CORS middleware.
Future<void> main() async {
  final router = Router()
    ..get('/employee/me', _getEmployee)
    ..get('/attendance', _getAttendance)
    ..post('/attendance/events', _postAttendanceEvent)
    ..get('/leave/balance', _getLeaveBalance)
    ..get('/leave/requests', _getLeaveRequests)
    ..post('/leave/requests', _postLeaveRequest)
    ..get('/__scenario', _getScenario)
    ..post('/__scenario', _setScenario)
    ..post('/__reset', _reset);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors)
      .addHandler(router.call);
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
  stdout.writeln(
    'REBS HRMS mock API listening on http://${server.address.host}:${server.port}',
  );
}

/// Middleware that handles CORS pre-flight OPTIONS requests and attaches CORS headers to responses.
Middleware get _cors => (innerHandler) {
  return (request) async {
    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: _jsonHeaders);
    }
    final response = await innerHandler(request);
    return response.change(headers: _jsonHeaders);
  };
};

/// Endpoint handler for `GET /employee/me`. Returns the current employee profile.
Future<Response> _getEmployee(Request request) async {
  final blocked = await _applyScenario();
  return blocked ?? _json(200, _store.employee);
}

/// Endpoint handler for `GET /attendance?month=yyyy-MM`. Returns attendance records for a month.
Future<Response> _getAttendance(Request request) async {
  final blocked = await _applyScenario();
  if (blocked != null) return blocked;
  final month = request.url.queryParameters['month'];
  final records = month == null
      ? _store.attendanceRecords
      : _store.attendanceRecords
            .where(
              (record) => (record['companyDate'] as String).startsWith(month),
            )
            .toList();
  return _json(200, {'records': records});
}

/// Endpoint handler for `POST /attendance/events`. Records a check-in or check-out event.
///
/// Enforces:
/// - Idempotency via `clientEventId`: duplicate events return HTTP 200 with `duplicate: true`.
/// - Single check-in per day (rejects duplicate same-type events with HTTP 409).
/// - Sequence order: check-out requires prior check-in (HTTP 422).
/// - Geofence validation: coordinates must be within 200m radius of the office (HTTP 422).
Future<Response> _postAttendanceEvent(Request request) async {
  final payload = await _readJson(request);
  if (payload == null) {
    return _error(400, 'INVALID_JSON', 'Request body must be JSON.');
  }
  final validation = _validateAttendancePayload(payload);
  if (validation != null) return validation;

  final eventId = payload['clientEventId'] as String;
  final existing = _store.eventsById[eventId];
  if (existing != null) {
    // Return existing event without creating duplicate records.
    return _json(200, {'duplicate': true, 'event': existing});
  }

  final scenarioResponse = await _applyScenario();
  if (scenarioResponse != null) return scenarioResponse;

  final type = payload['type'] as String;
  final companyDate = payload['companyDate'] as String;
  final sameDayEvents = _store.eventsById.values
      .where((event) => event['companyDate'] == companyDate)
      .toList();
  final hasCheckIn = sameDayEvents.any((event) => event['type'] == 'check_in');
  final hasSameType = sameDayEvents.any((event) => event['type'] == type);
  if (hasSameType) {
    return _error(
      409,
      'ALREADY_EXISTS',
      'This attendance action already exists.',
    );
  }
  if (type == 'check_out' && !hasCheckIn) {
    return _error(
      422,
      'INVALID_ORDER',
      'Check-in is required before check-out.',
    );
  }

  final distance = _distanceMeters(
    (payload['latitude'] as num).toDouble(),
    (payload['longitude'] as num).toDouble(),
    _officeLatitude,
    _officeLongitude,
  );
  if (distance > _officeRadiusMeters) {
    return _error(
      422,
      'OUTSIDE_RADIUS',
      'Attendance is allowed only within 200 metres of the office.',
    );
  }

  final event = <String, dynamic>{
    ...payload,
    'distanceMeters': distance.round(),
  };
  _store.eventsById[eventId] = event;
  _store.updateRecord(event);
  if (_store.scenario == 'accept_then_timeout') {
    // Save record first, then delay response to simulate network drop after server commit.
    await Future<void>.delayed(const Duration(seconds: 15));
  }
  return _json(201, {'duplicate': false, 'event': event});
}

/// Endpoint handler for `GET /leave/balance`. Returns remaining leave days.
Future<Response> _getLeaveBalance(Request request) async {
  final blocked = await _applyScenario();
  return blocked ?? _json(200, _store.leaveBalance);
}

/// Endpoint handler for `GET /leave/requests`. Returns all leave requests.
Future<Response> _getLeaveRequests(Request request) async {
  final blocked = await _applyScenario();
  return blocked ?? _json(200, {'requests': _store.leaveRequests});
}

/// Endpoint handler for `POST /leave/requests`. Submits a new leave request.
///
/// Enforces:
/// - Valid date range (start <= end) and reason length (>= 10 chars).
/// - Insufficient balance check against available days.
/// - Overlap check against existing non-rejected leave requests.
Future<Response> _postLeaveRequest(Request request) async {
  final payload = await _readJson(request);
  if (payload == null) {
    return _error(400, 'INVALID_JSON', 'Request body must be JSON.');
  }
  final blocked = await _applyScenario();
  if (blocked != null) return blocked;
  if (_store.scenario == 'leave_rejected') {
    return _error(
      422,
      'LEAVE_REJECTED',
      'The leave request was rejected by the scenario.',
    );
  }
  final start = _parseDate(payload['startDate']);
  final end = _parseDate(payload['endDate']);
  final reason = payload['reason'];
  if (start == null ||
      end == null ||
      end.isBefore(start) ||
      reason is! String ||
      reason.trim().length < 10) {
    return _error(
      422,
      'INVALID_LEAVE',
      'The leave request contains invalid fields.',
    );
  }
  final requestedDays = end.difference(start).inDays + 1;
  if (requestedDays > (_store.leaveBalance['availableDays'] as int)) {
    return _error(
      422,
      'INSUFFICIENT_BALANCE',
      'Requested days exceed the available leave balance.',
    );
  }
  final overlaps = _store.leaveRequests.any((leave) {
    if (leave['status'] == 'Rejected') return false;
    final existingStart = DateTime.parse(leave['startDate'] as String);
    final existingEnd = DateTime.parse(leave['endDate'] as String);
    return !start.isAfter(existingEnd) && !end.isBefore(existingStart);
  });
  if (overlaps) {
    return _error(
      422,
      'OVERLAPPING_LEAVE',
      'The requested dates overlap an existing request.',
    );
  }

  final leave = <String, dynamic>{
    'id': 'leave-${_store.leaveRequests.length + 1}',
    ...payload,
    'status': 'Pending',
    'requestedDays': requestedDays,
  };
  _store.leaveRequests.add(leave);
  return _json(201, leave);
}

/// Endpoint handler for `GET /__scenario`. Returns the current failure simulation scenario mode.
Future<Response> _getScenario(Request request) async =>
    _json(200, {'mode': _store.scenario});

/// Endpoint handler for `POST /__scenario`. Switches the mock failure simulation mode.
Future<Response> _setScenario(Request request) async {
  final payload = await _readJson(request);
  final mode = payload?['mode'];
  if (mode is! String || !_MockStore.scenarios.contains(mode)) {
    return _error(
      400,
      'INVALID_SCENARIO',
      'Choose one of: ${_MockStore.scenarios.join(', ')}.',
    );
  }
  _store.scenario = mode;
  return _json(200, {'mode': mode});
}

/// Endpoint handler for `POST /__reset`. Clears all dynamic data and resets mock store to initial state.
Future<Response> _reset(Request request) async {
  _store.reset();
  return _json(200, {'reset': true, 'mode': _store.scenario});
}

/// Simulates artificial network delays or HTTP error codes based on the active scenario.
Future<Response?> _applyScenario() async {
  if (_store.scenario == 'slow') {
    await Future<void>.delayed(const Duration(seconds: 4));
  }
  if (_store.scenario == 'timeout') {
    await Future<void>.delayed(const Duration(seconds: 15));
  }
  if (_store.scenario == 'server_error') {
    return _error(500, 'SERVER_ERROR', 'Mock server scenario failure.');
  }
  if (_store.scenario == 'duplicate_conflict') {
    return _error(409, 'ALREADY_EXISTS', 'Mock duplicate conflict scenario.');
  }
  return null;
}

/// Safely decodes a JSON request body into a Map, returning `null` on format error.
Future<Map<String, dynamic>?> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Checks that an attendance event payload contains all required fields and valid types.
Response? _validateAttendancePayload(Map<String, dynamic> payload) {
  const required = [
    'clientEventId',
    'type',
    'occurredAt',
    'companyDate',
    'latitude',
    'longitude',
  ];
  if (required.any((field) => payload[field] == null)) {
    return _error(
      422,
      'MISSING_FIELD',
      'Attendance event is missing a required field.',
    );
  }
  if (payload['type'] != 'check_in' && payload['type'] != 'check_out') {
    return _error(
      422,
      'INVALID_TYPE',
      'Attendance type must be check_in or check_out.',
    );
  }
  if (payload['clientEventId'] is! String ||
      payload['companyDate'] is! String ||
      payload['occurredAt'] is! String ||
      payload['latitude'] is! num ||
      payload['longitude'] is! num ||
      DateTime.tryParse(payload['occurredAt'] as String) == null) {
    return _error(
      422,
      'INVALID_EVENT',
      'Attendance event contains invalid field values.',
    );
  }
  return null;
}

/// Builds an HTTP response with JSON body and proper headers.
Response _json(int status, Object body) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

/// Builds a structured JSON error response with status code, error code, and human-readable message.
Response _error(int status, String code, String message) =>
    _json(status, {'code': code, 'message': message});

/// Safely parses an ISO date string into a DateTime, returning `null` if invalid.
DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Calculates the surface distance in meters between two GPS coordinates using the Haversine formula.
double _distanceMeters(
  double latitude1,
  double longitude1,
  double latitude2,
  double longitude2,
) {
  const earthRadius = 6371000.0;
  final latDelta = _radians(latitude2 - latitude1);
  final lonDelta = _radians(longitude2 - longitude1);
  final a =
      math.sin(latDelta / 2) * math.sin(latDelta / 2) +
      math.cos(_radians(latitude1)) *
          math.cos(_radians(latitude2)) *
          math.sin(lonDelta / 2) *
          math.sin(lonDelta / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Converts degrees to radians.
double _radians(double degrees) => degrees * math.pi / 180;

/// In-memory storage holding mock server state (employee, records, events, balance, requests).
class _MockStore {
  /// All supported scenario modes for testing.
  static const scenarios = <String>[
    'success',
    'slow',
    'timeout',
    'accept_then_timeout',
    'server_error',
    'duplicate_conflict',
    'leave_rejected',
  ];

  /// Currently active scenario mode.
  String scenario = 'success';

  /// Preconfigured employee profile data.
  late Map<String, dynamic> employee;

  /// Aggregated daily attendance records.
  late List<Map<String, dynamic>> attendanceRecords;

  /// Map of all attendance events by clientEventId to guarantee idempotency.
  late Map<String, Map<String, dynamic>> eventsById;

  /// Leave balance information.
  late Map<String, dynamic> leaveBalance;

  /// List of submitted leave requests.
  late List<Map<String, dynamic>> leaveRequests;

  /// Creates a mock store initialized with default seed data.
  _MockStore() {
    reset();
  }

  /// Resets all mock data back to default values.
  void reset() {
    scenario = 'success';
    employee = {
      'id': 'EMP-001',
      'name': 'Ananya Nair',
      'department': 'Operations',
      'companyTimeZone': 'Asia/Kolkata',
      'office': {
        'name': 'Kochi Office',
        'latitude': _officeLatitude,
        'longitude': _officeLongitude,
        'radiusMeters': _officeRadiusMeters,
      },
    };
    attendanceRecords = <Map<String, dynamic>>[];
    eventsById = <String, Map<String, dynamic>>{};
    leaveBalance = {
      'availableDays': 12,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    leaveRequests = <Map<String, dynamic>>[
      {
        'id': 'leave-1',
        'type': 'Casual',
        'startDate': '2026-12-10',
        'endDate': '2026-12-11',
        'reason': 'Family function travel',
        'status': 'Pending',
      },
      {
        'id': 'leave-2',
        'type': 'Sick',
        'startDate': '2026-10-04',
        'endDate': '2026-10-05',
        'reason': 'Medical recovery and rest',
        'status': 'Approved',
      },
      {
        'id': 'leave-3',
        'type': 'Casual',
        'startDate': '2026-09-22',
        'endDate': '2026-09-22',
        'reason': 'Personal appointment leave',
        'status': 'Rejected',
      },
    ];
  }

  /// Updates or inserts a daily attendance record when a check-in or check-out event occurs.
  void updateRecord(Map<String, dynamic> event) {
    final date = event['companyDate'] as String;
    final index = attendanceRecords.indexWhere(
      (record) => record['companyDate'] == date,
    );
    final record = index == -1
        ? <String, dynamic>{'companyDate': date}
        : attendanceRecords[index];
    record[event['type'] == 'check_in' ? 'checkInAt' : 'checkOutAt'] =
        event['occurredAt'];
    if (index == -1) attendanceRecords.add(record);
  }
}
