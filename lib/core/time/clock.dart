/// A simple clock interface so the rest of the app never calls
/// `DateTime.now()` directly.
///
/// By depending on this interface instead of `DateTime.now()`, tests can
/// inject a [FixedClock] and control exactly what time the code thinks it is —
/// making time-sensitive tests fast, deterministic, and reliable.
abstract interface class Clock {
  /// Returns the current moment in time as a UTC [DateTime].
  DateTime now();
}

/// The real clock that reads the actual system time.
///
/// Use this in production. It simply forwards to `DateTime.now().toUtc()`.
class SystemClock implements Clock {
  const SystemClock();

  /// Returns the current UTC time from the host device.
  @override
  DateTime now() => DateTime.now().toUtc();
}

/// A clock frozen at a specific [fixedTime], used only in tests.
///
/// Inject a [FixedClock] wherever a [Clock] is expected to make tests
/// independent of the actual wall-clock time.
///
/// Example:
/// ```dart
/// final clock = FixedClock(DateTime.utc(2024, 6, 15, 9, 0, 0));
/// expect(clock.now(), DateTime.utc(2024, 6, 15, 9, 0, 0));
/// ```
class FixedClock implements Clock {
  const FixedClock(this.fixedTime);

  /// The time that this clock will always return.
  final DateTime fixedTime;

  /// Always returns [fixedTime] as UTC, regardless of when it is called.
  @override
  DateTime now() => fixedTime.toUtc();
}
