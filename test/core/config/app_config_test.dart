import 'package:flutter_test/flutter_test.dart';
import 'package:teqbae_hrms/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('fromEnvironment uses defaults when no flags provided', () {
      final config = AppConfig.fromEnvironment();
      expect(config.apiBaseUrl, AppConfig.defaultApiBaseUrl);
      expect(config.companyTimeZone, AppConfig.defaultCompanyTimeZone);
      expect(config.officeLatitude, AppConfig.defaultOfficeLatitude);
      expect(config.officeLongitude, AppConfig.defaultOfficeLongitude);
      expect(config.officeRadiusMeters, 200.0);
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.receiveTimeout, const Duration(seconds: 10));
      expect(config.officeLocation.latitude, AppConfig.defaultOfficeLatitude);
      expect(config.officeLocation.radiusMeters, 200.0);
    });

    test('copyWith creates modified config', () {
      final config = AppConfig.fromEnvironment();
      final updated = config.copyWith(apiBaseUrl: 'http://localhost:8080', officeRadiusMeters: 500);

      expect(updated.apiBaseUrl, 'http://localhost:8080');
      expect(updated.officeRadiusMeters, 500.0);
      expect(updated.companyTimeZone, config.companyTimeZone);
    });
  });
}
