import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class ConnectivityService {
  Future<bool> get isOnline;
  Stream<bool> get onStatusChanged;
}

class DeviceConnectivityService implements ConnectivityService {
  DeviceConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async => (await _connectivity.checkConnectivity()).any((value) => value != ConnectivityResult.none);

  @override
  Stream<bool> get onStatusChanged => _connectivity.onConnectivityChanged.map((values) => values.any((value) => value != ConnectivityResult.none)).distinct();
}
