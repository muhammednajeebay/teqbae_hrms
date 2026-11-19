import 'package:geolocator/geolocator.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';

/// A GPS fix captured at the moment the user taps check-in or check-out.
///
/// This is an intermediate data-layer model. After geofence validation it is
/// embedded into an [AttendanceEvent] domain object for outbox persistence.
class AttendanceLocation {
  const AttendanceLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.isMocked = false,
  });

  /// GPS latitude in decimal degrees.
  final double latitude;

  /// GPS longitude in decimal degrees.
  final double longitude;

  /// Horizontal accuracy of the fix in metres. `null` if the device did not
  /// report accuracy (unusual but possible).
  final double? accuracy;

  /// `true` if this location was injected by the Debug Panel simulation rather
  /// than read from real device GPS.
  final bool isMocked;
}

// ── Interface ─────────────────────────────────────────────────────────────────

/// Contract for anything that can return the current GPS position.
///
/// Three implementations exist:
/// - [GeolocatorLocationService] — real device GPS.
/// - [SimulatedLocationService] — fixed test coordinates.
/// - [ConfigurableLocationService] — runtime-switchable (used by the Debug Panel).
abstract interface class LocationService {
  /// Returns the current location or a [LocationFailure] if it cannot be
  /// determined (permission denied, GPS off, hardware error).
  Future<Result<AttendanceLocation>> currentLocation();
}

// ── Real GPS ──────────────────────────────────────────────────────────────────

/// Real device GPS implementation using the `geolocator` package.
///
/// Performs the full permission check flow before reading the position:
/// 1. Check whether location services are enabled on the device.
/// 2. Check the current permission status.
/// 3. Request permission if it has not been granted yet.
/// 4. Read the position with high accuracy.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  /// Returns the current GPS position, or a [FailureResult] with a
  /// [LocationFailure] explaining exactly why the location could not be read
  /// (services off, permission denied, permission permanently denied, or a
  /// generic hardware error).
  @override
  Future<Result<AttendanceLocation>> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const FailureResult(
          LocationFailure('Location services are turned off.'));
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const FailureResult(
          LocationFailure('Location permission was denied.'));
    }
    if (permission == LocationPermission.deniedForever) {
      return const FailureResult(LocationFailure(
          'Location permission is permanently denied. Open Settings to allow it.'));
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      return Success(AttendanceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isMocked: position.isMocked,
      ));
    } on LocationServiceDisabledException {
      return const FailureResult(
          LocationFailure('Location services are turned off.'));
    } catch (_) {
      return const FailureResult(
          LocationFailure('Could not get your current location. Try again.'));
    }
  }
}

// ── Simulated (fixed) ─────────────────────────────────────────────────────────

/// A location service that always returns a fixed [location] value.
///
/// Pass `null` as the location to simulate a GPS unavailable / error state.
/// Used in unit tests where you want deterministic coordinates without touching
/// real device APIs.
class SimulatedLocationService implements LocationService {
  const SimulatedLocationService(this.location);

  /// The fixed coordinates to return. `null` simulates a GPS error.
  final AttendanceLocation? location;

  /// Returns [location] wrapped in [Success], or a [FailureResult] with a
  /// [LocationFailure] when [location] is `null`.
  @override
  Future<Result<AttendanceLocation>> currentLocation() async =>
      location == null
          ? const FailureResult(LocationFailure('Simulated location is unavailable.'))
          : Success(location!);
}

// ── Configurable (Debug Panel) ────────────────────────────────────────────────

/// A location service whose behaviour can be changed at runtime by the
/// Debug & Testing Panel without restarting the app.
///
/// When [isSimulationEnabled] is `false`, delegates to the underlying
/// [_realLocationService] (default: [GeolocatorLocationService]).
/// When `true`, returns [simulatedLocation] — or a failure if it is `null`.
class ConfigurableLocationService implements LocationService {
  /// Creates a [ConfigurableLocationService].
  ///
  /// A custom [realLocationService] can be injected for testing.
  ConfigurableLocationService({
    LocationService? realLocationService,
  }) : _realLocationService =
            realLocationService ?? const GeolocatorLocationService();

  final LocationService _realLocationService;

  /// Set to `true` to override GPS with the [simulatedLocation] preset.
  bool isSimulationEnabled = false;

  /// The coordinates to return when simulation is enabled.
  /// Setting this to `null` while simulation is enabled simulates a GPS error.
  AttendanceLocation? simulatedLocation;

  // ── Preset coordinates ────────────────────────────────────────────────────

  /// Simulates being directly at the office (within the 200 m geofence).
  static const atOffice = AttendanceLocation(
    latitude: 9.9312,
    longitude: 76.2673,
    accuracy: 5.0,
    isMocked: true,
  );

  /// Simulates being ~500 m away from the office (outside the geofence).
  static const fiveHundredMetersAway = AttendanceLocation(
    latitude: 9.9360,
    longitude: 76.2673,
    accuracy: 10.0,
    isMocked: true,
  );

  // ── LocationService ───────────────────────────────────────────────────────

  /// Returns [simulatedLocation] when simulation is enabled, otherwise
  /// delegates to [_realLocationService].
  @override
  Future<Result<AttendanceLocation>> currentLocation() async {
    if (isSimulationEnabled) {
      if (simulatedLocation == null) {
        return const FailureResult(
            LocationFailure('Simulated location is unavailable.'));
      }
      return Success(simulatedLocation!);
    }
    return _realLocationService.currentLocation();
  }
}
