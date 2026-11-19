import 'package:geolocator/geolocator.dart';
import 'package:teqbae_hrms/core/failure/failure.dart';

class AttendanceLocation {
  const AttendanceLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.isMocked = false,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final bool isMocked;
}

abstract interface class LocationService {
  Future<Result<AttendanceLocation>> currentLocation();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<Result<AttendanceLocation>> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const FailureResult(LocationFailure('Location services are turned off.'));
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const FailureResult(LocationFailure('Location permission was denied.'));
    }
    if (permission == LocationPermission.deniedForever) {
      return const FailureResult(LocationFailure('Location permission is permanently denied. Open Settings to allow it.'));
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
      return const FailureResult(LocationFailure('Location services are turned off.'));
    } catch (_) {
      return const FailureResult(LocationFailure('Could not get your current location. Try again.'));
    }
  }
}

class SimulatedLocationService implements LocationService {
  const SimulatedLocationService(this.location);

  final AttendanceLocation? location;

  @override
  Future<Result<AttendanceLocation>> currentLocation() async =>
      location == null ? const FailureResult(LocationFailure('Simulated location is unavailable.')) : Success(location!);
}

class ConfigurableLocationService implements LocationService {
  ConfigurableLocationService({
    LocationService? realLocationService,
  }) : _realLocationService = realLocationService ?? const GeolocatorLocationService();

  final LocationService _realLocationService;
  bool isSimulationEnabled = false;
  AttendanceLocation? simulatedLocation;

  static const atOffice = AttendanceLocation(
    latitude: 9.9312,
    longitude: 76.2673,
    accuracy: 5.0,
    isMocked: true,
  );

  static const fiveHundredMetersAway = AttendanceLocation(
    latitude: 9.9360,
    longitude: 76.2673,
    accuracy: 10.0,
    isMocked: true,
  );

  @override
  Future<Result<AttendanceLocation>> currentLocation() async {
    if (isSimulationEnabled) {
      if (simulatedLocation == null) {
        return const FailureResult(LocationFailure('Simulated location is unavailable.'));
      }
      return Success(simulatedLocation!);
    }
    return _realLocationService.currentLocation();
  }
}
