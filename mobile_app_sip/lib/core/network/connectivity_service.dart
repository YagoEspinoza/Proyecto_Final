import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ConnectivityService {
  static final ConnectivityService _singleton = ConnectivityService._internal();
  final _connectivity = Connectivity();
  
  factory ConnectivityService() => _singleton;
  ConnectivityService._internal();

  Future<bool> get isOnline async {
    try {
      if (kIsWeb) return true; // Web default
      final result = await _connectivity.checkConnectivity();
      if (result is List) {
        if (result.isEmpty) return false;
        return result.first != ConnectivityResult.none;
      }
      // Fallback for older package version signature
      return (result as dynamic) != ConnectivityResult.none;
    } catch (_) {
      return true; // Web/error fallback: assume online
    }
  }

  Stream<ConnectivityResult> get onConnectivityChanged {
    try {
      return _connectivity.onConnectivityChanged.map((list) {
        if (list is List) {
          if (list.isEmpty) return ConnectivityResult.none;
          return list.first;
        }
        // Fallback for older package version signature
        return list as ConnectivityResult;
      }).handleError((_) => ConnectivityResult.none);
    } catch (_) {
      return Stream.value(ConnectivityResult.wifi);
    }
  }
}
