import 'package:connectivity_plus/connectivity_plus.dart';

/// An interface for checking and monitoring internet connectivity.
///
/// The interface exists so that the production implementation ([DeviceConnectivityService])
/// can be swapped out with a fake in tests without touching any business logic.
abstract interface class ConnectivityService {
  /// Returns `true` if the device currently has at least one active network
  /// connection (Wi-Fi, mobile data, ethernet, etc.).
  ///
  /// This is a one-shot check — it does not keep watching for changes.
  Future<bool> get isOnline;

  /// A stream that emits `true` when the device comes online and `false` when
  /// it goes offline.
  ///
  /// Only emits a new value when the status actually changes (uses `.distinct()`
  /// internally), so subscribers are not bombarded with repeated identical events.
  Stream<bool> get onStatusChanged;
}

/// The real implementation of [ConnectivityService] that uses the
/// `connectivity_plus` package to query the device's network state.
class DeviceConnectivityService implements ConnectivityService {
  /// Creates a [DeviceConnectivityService] using the provided [Connectivity]
  /// instance. Inject `Connectivity()` in production and a mock in tests.
  DeviceConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  /// Checks all active network interfaces. Returns `true` if at least one
  /// interface is not [ConnectivityResult.none].
  @override
  Future<bool> get isOnline async =>
      (await _connectivity.checkConnectivity())
          .any((value) => value != ConnectivityResult.none);

  /// Listens to `connectivity_plus` change events and maps each list of
  /// results to a single boolean. `.distinct()` suppresses duplicate values
  /// so subscribers only hear about genuine status changes.
  @override
  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged
          .map((values) => values.any((value) => value != ConnectivityResult.none))
          .distinct();
}
