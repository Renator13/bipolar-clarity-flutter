import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Servicio para detectar estado de conectividad
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  final _connectivityStream = StreamController<bool>.broadcast();
  bool _isOnline = true;

  /// Stream de estado de conexión (true = online, false = offline)
  Stream<bool> get onConnectivityChanged => _connectivityStream.stream;

  /// Estado actual
  bool get isOnline => _isOnline;

  /// Inicializar listener de conectividad
  Future<void> init() async {
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      _connectivityStream.add(_isOnline);
    });
    
    // Verificar estado inicial
    final initialResult = await _connectivity.checkConnectivity();
    _isOnline = initialResult != ConnectivityResult.none;
    _connectivityStream.add(_isOnline);
  }

  /// Verificar conectividad actual
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Verificar tipo de conexión
  Future<String> getConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Móvil';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
      default:
        return 'Sin conexión';
    }
  }

  /// Dispose
  void dispose() {
    _connectivityStream.close();
  }
}
