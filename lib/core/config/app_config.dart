import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.companyTimeZone,
    required this.officeLatitude,
    required this.officeLongitude,
    this.officeRadiusMeters = 200.0,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
  });

  static const String defaultApiBaseUrl = 'http://10.0.2.2:8080';
  static const String defaultCompanyTimeZone = 'Asia/Kolkata';
  static const double defaultOfficeLatitude = 9.9312;
  static const double defaultOfficeLongitude = 76.2673;
  static const double defaultOfficeRadiusMeters = 200.0;

  factory AppConfig.fromEnvironment() {
    // In Dart, String.fromEnvironment MUST be invoked with `const` to read
    // values passed via --dart-define. Without const, it always returns the default value.
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultApiBaseUrl,
    );
    const companyTimeZone = String.fromEnvironment(
      'COMPANY_TIME_ZONE',
      defaultValue: defaultCompanyTimeZone,
    );
    const latitudeStr = String.fromEnvironment('OFFICE_LATITUDE');
    const longitudeStr = String.fromEnvironment('OFFICE_LONGITUDE');
    const radiusStr = String.fromEnvironment('OFFICE_RADIUS_METERS');

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      companyTimeZone: companyTimeZone,
      officeLatitude: double.tryParse(latitudeStr) ?? defaultOfficeLatitude,
      officeLongitude: double.tryParse(longitudeStr) ?? defaultOfficeLongitude,
      officeRadiusMeters: double.tryParse(radiusStr) ?? defaultOfficeRadiusMeters,
    );
  }

  final String apiBaseUrl;
  final String companyTimeZone;
  final double officeLatitude;
  final double officeLongitude;
  final double officeRadiusMeters;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  OfficeConfig get officeLocation => OfficeConfig(
        latitude: officeLatitude,
        longitude: officeLongitude,
        radiusMeters: officeRadiusMeters,
      );

  AppConfig copyWith({
    String? apiBaseUrl,
    String? companyTimeZone,
    double? officeLatitude,
    double? officeLongitude,
    double? officeRadiusMeters,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      companyTimeZone: companyTimeZone ?? this.companyTimeZone,
      officeLatitude: officeLatitude ?? this.officeLatitude,
      officeLongitude: officeLongitude ?? this.officeLongitude,
      officeRadiusMeters: officeRadiusMeters ?? this.officeRadiusMeters,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
    );
  }
}
