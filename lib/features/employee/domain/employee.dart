import 'package:equatable/equatable.dart';
import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

class Employee extends Equatable {
  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.officeLocation,
    required this.companyTimeZone,
  });

  final String id;
  final String name;
  final String department;
  final OfficeConfig officeLocation;
  final String companyTimeZone;

  @override
  List<Object?> get props => [id, name, department, officeLocation, companyTimeZone];
}
