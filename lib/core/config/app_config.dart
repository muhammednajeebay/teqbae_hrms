import 'package:teqbae_hrms/features/attendance/domain/attendance.dart';

/// Holds every piece of configuration the app needs at runtime.
///
/// Values are either baked in at build time via `--dart-define` flags or fall
/// back to safe defaults so the app always runs even without any flags set.
///
/// Usage:
/// ```
/// final config = AppConfig.fromEnvironment();
/// ```
class AppConfig {
  /// Creates a fully specified [AppConfig].
  ///
  /// All fields are required except [connectTimeout] and [receiveTimeout] which
  /// default to 10 seconds each.
  const AppConfig({
    required this.apiBaseUrl,
    required this.companyTimeZone,
    required this.officeLatitude,
    required this.officeLongitude,
    this.officeRadiusMeters = 200.0,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
  });

  // ── Build-time defaults ──────────────────────────────────────────────────

  /// Default API base URL — points to the Android emulator loopback address.
  static const String defaultApiBaseUrl = 'http://10.0.2.2:8080';

  /// Default company timezone used to determine calendar date boundaries.
  static const String defaultCompanyTimeZone = 'Asia/Kolkata';

  /// Default office latitude (Ernakulam, Kerala).
  static const double defaultOfficeLatitude = 9.9312;

  /// Default office longitude (Ernakulam, Kerala).
  static const double defaultOfficeLongitude = 76.2673;

  /// Default geofence radius — employees must be within this many metres.
  static const double defaultOfficeRadiusMeters = 200.0;

  // ── Factory: read from --dart-define ────────────────────────────────────

  /// Builds an [AppConfig] by reading `--dart-define` flags at compile time.
  ///
  /// **Important:** `String.fromEnvironment` must be called with `const` to
  /// capture `--dart-define` values. Without `const`, Dart always returns the
  /// default value regardless of what was passed on the command line.
  ///
  /// Supported flags:
  /// - `API_BASE_URL` — full base URL of the REBS API server.
  /// - `COMPANY_TIME_ZONE` — IANA timezone name (e.g. `Asia/Kolkata`).
  /// - `OFFICE_LATITUDE` — office GPS latitude as a decimal string.
  /// - `OFFICE_LONGITUDE` — office GPS longitude as a decimal string.
  /// - `OFFICE_RADIUS_METERS` — geofence radius in metres as a decimal string.
  factory AppConfig.fromEnvironment() {
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
      officeRadiusMeters:
          double.tryParse(radiusStr) ?? defaultOfficeRadiusMeters,
    );
  }

  // ── Fields ───────────────────────────────────────────────────────────────

  /// Full base URL for the REBS API (e.g. `http://10.0.2.2:8080`).
  final String apiBaseUrl;

  /// IANA timezone name used for company-local date calculations.
  final String companyTimeZone;

  /// GPS latitude of the office building.
  final double officeLatitude;

  /// GPS longitude of the office building.
  final double officeLongitude;

  /// Radius in metres within which employees may check in or out.
  final double officeRadiusMeters;

  /// Maximum time to wait while establishing a TCP connection to the server.
  final Duration connectTimeout;

  /// Maximum time to wait for the server to send back a response.
  final Duration receiveTimeout;

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Builds an [OfficeConfig] domain object from the stored lat/lon/radius.
  ///
  /// Used by the geofence rule to know where the office is.
  OfficeConfig get officeLocation => OfficeConfig(
    latitude: officeLatitude,
    longitude: officeLongitude,
    radiusMeters: officeRadiusMeters,
  );

  /// Returns a copy of this config with any supplied fields replaced.
  ///
  /// Useful in tests to swap out just the API URL without touching everything else.
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
