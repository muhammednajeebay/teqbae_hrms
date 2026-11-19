abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

class FixedClock implements Clock {
  const FixedClock(this.fixedTime);

  final DateTime fixedTime;

  @override
  DateTime now() => fixedTime.toUtc();
}
