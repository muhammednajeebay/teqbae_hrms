import 'package:flutter_test/flutter_test.dart';
import 'package:teqbae_hrms/core/time/clock.dart';
import 'package:teqbae_hrms/core/time/company_calendar.dart';

void main() {
  group('CompanyCalendar', () {
    test('converts UTC instant to company timezone date', () {
      final calendar = CompanyCalendar(defaultTimeZone: 'Asia/Kolkata');
      // 2026-11-19 20:00 UTC is 2026-11-20 01:30 IST
      final instant = DateTime.utc(2026, 11, 19, 20, 0);
      final date = calendar.formatCompanyDate(instant);
      expect(date, '2026-11-20');
    });

    test('same day when within company timezone bounds', () {
      final calendar = CompanyCalendar(defaultTimeZone: 'Asia/Kolkata');
      final instant = DateTime.utc(2026, 11, 19, 4, 30); // 10:00 IST
      final date = calendar.formatCompanyDate(instant);
      expect(date, '2026-11-19');
    });
  });

  group('Clock', () {
    test('FixedClock returns fixed UTC instant', () {
      final fixed = DateTime.utc(2026, 11, 19, 9, 30);
      final clock = FixedClock(fixed);
      expect(clock.now(), fixed);
    });

    test('SystemClock returns current UTC instant', () {
      const clock = SystemClock();
      final now = clock.now();
      expect(now.isUtc, isTrue);
    });
  });
}
