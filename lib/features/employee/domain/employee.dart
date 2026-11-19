import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

/// The domain model for a single employee.
///
/// Loaded from the server on first launch and cached locally in the SQLite
/// database so the dashboard can display the employee's name, department, and
/// office location even when the device is offline.
class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.officeLocation,
    required this.companyTimeZone,
  });

  /// Unique identifier assigned by the server (e.g. `'EMP001'`).
  final String id;

  /// Full display name of the employee (e.g. `'Jane Smith'`).
  final String name;

  /// Department or team the employee belongs to (e.g. `'Engineering'`).
  final String department;

  /// GPS coordinates and geofence radius of the employee's assigned office.
  /// Used by [GeofenceRule] to validate check-in / check-out distance.
  final OfficeConfig officeLocation;

  /// IANA timezone name of the company (e.g. `'Asia/Kolkata'`).
  /// Stored here so the app can apply the correct timezone even if the
  /// [AppConfig] was built with different defaults.
  final String companyTimeZone;

  @override
  List<Object?> get props => [id, name, department, officeLocation, companyTimeZone];
}
