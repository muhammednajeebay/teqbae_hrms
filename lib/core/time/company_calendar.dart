import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CompanyCalendar {
  CompanyCalendar({String defaultTimeZone = 'Asia/Kolkata'})
      : _timeZoneName = defaultTimeZone {
    _ensureInitialized();
  }

  static bool _initialized = false;

  static void _ensureInitialized() {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }
  }

  final String _timeZoneName;

  String formatCompanyDate(DateTime instant) {
    final tzLocation = _getLocationSafe(_timeZoneName);
    final tzDateTime = tz.TZDateTime.from(instant, tzLocation);
    final year = tzDateTime.year.toString().padLeft(4, '0');
    final month = tzDateTime.month.toString().padLeft(2, '0');
    final day = tzDateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime toCompanyDateTime(DateTime instant) {
    final tzLocation = _getLocationSafe(_timeZoneName);
    return tz.TZDateTime.from(instant, tzLocation);
  }

  tz.Location _getLocationSafe(String name) {
    try {
      return tz.getLocation(name);
    } catch (_) {
      return tz.getLocation('UTC');
    }
  }
}
