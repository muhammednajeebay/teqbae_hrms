class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.companyTimeZone,
    required this.officeLatitude,
    required this.officeLongitude,
    this.officeRadiusMeters = 200,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
  });

  static const String defaultApiBaseUrl = 'http://10.0.2.2:8080';
  static const String defaultCompanyTimeZone = 'Asia/Kolkata';
  static const double defaultOfficeLatitude = 9.9312;
  static const double defaultOfficeLongitude = 76.2673;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: defaultApiBaseUrl,
      ),
      companyTimeZone: String.fromEnvironment(
        'COMPANY_TIME_ZONE',
        defaultValue: defaultCompanyTimeZone,
      ),
      officeLatitude: _environmentDouble(
        'OFFICE_LATITUDE',
        defaultOfficeLatitude,
      ),
      officeLongitude: _environmentDouble(
        'OFFICE_LONGITUDE',
        defaultOfficeLongitude,
      ),
    );
  }

  static double _environmentDouble(String name, double fallback) {
    return double.tryParse(String.fromEnvironment(name)) ?? fallback;
  }

  final String apiBaseUrl;
  final String companyTimeZone;
  final double officeLatitude;
  final double officeLongitude;
  final double officeRadiusMeters;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}
