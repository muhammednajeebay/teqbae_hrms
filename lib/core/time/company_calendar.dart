import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Converts UTC timestamps into the company's local timezone so that
/// "today" always means the same calendar date for every employee,
/// regardless of where their device is located.
///
/// For example, if the company timezone is `Asia/Kolkata` (UTC+5:30), a
/// UTC timestamp of `2024-06-15 18:30:00Z` becomes `2024-06-16` in company
/// local time — so the employee's check-in is recorded on the 16th.
///
/// The timezone database is loaded once and cached globally.
class CompanyCalendar {
  /// Creates a [CompanyCalendar] for the given IANA [defaultTimeZone].
  ///
  /// Defaults to `'Asia/Kolkata'` if no zone is provided.
  /// If the timezone name is unrecognised, falls back to `'UTC'`.
  CompanyCalendar({String defaultTimeZone = 'Asia/Kolkata'})
      : _timeZoneName = defaultTimeZone {
    _ensureInitialized();
  }

  /// Whether the global timezone database has already been loaded.
  static bool _initialized = false;

  /// Loads the timezone database exactly once per process.
  ///
  /// Calling `tz.initializeTimeZones()` multiple times is harmless but
  /// wastes work, so we guard it with [_initialized].
  static void _ensureInitialized() {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }
  }

  /// IANA name of the company's local timezone (e.g. `'Asia/Kolkata'`).
  final String _timeZoneName;

  /// Formats a UTC [instant] as a `yyyy-MM-dd` date string in the company
  /// timezone.
  ///
  /// This string is stored as the `companyDate` field on attendance events
  /// and records. It uniquely identifies which company-local calendar day an
  /// event belongs to.
  ///
  /// Example:
  /// ```dart
  /// final cal = CompanyCalendar(defaultTimeZone: 'Asia/Kolkata');
  /// cal.formatCompanyDate(DateTime.utc(2024, 6, 15, 20, 0)); // → '2024-06-16'
  /// ```
  String formatCompanyDate(DateTime instant) {
    final tzLocation = _getLocationSafe(_timeZoneName);
    final tzDateTime = tz.TZDateTime.from(instant, tzLocation);
    final year = tzDateTime.year.toString().padLeft(4, '0');
    final month = tzDateTime.month.toString().padLeft(2, '0');
    final day = tzDateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Converts a UTC [instant] into a [DateTime] expressed in the company
  /// timezone.
  ///
  /// Useful when you need the full date-and-time (not just the date string)
  /// in the company's local zone — for example, when running leave validation
  /// that needs to compare against today's company-local date.
  DateTime toCompanyDateTime(DateTime instant) {
    final tzLocation = _getLocationSafe(_timeZoneName);
    return tz.TZDateTime.from(instant, tzLocation);
  }

  /// Looks up the timezone [name] and returns UTC if the name is not found.
  ///
  /// This prevents crashes when an unrecognised timezone name is configured
  /// (e.g. a typo in a `--dart-define` flag).
  tz.Location _getLocationSafe(String name) {
    try {
      return tz.getLocation(name);
    } catch (_) {
      return tz.getLocation('UTC');
    }
  }
}
