import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/storage/local_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class AsesorState {
  final List<dynamic> portfolio;
  final List<dynamic> syncQueue;
  final bool isOnline;
  final bool isLoading;
  final String? error;

  AsesorState({
    required this.portfolio,
    required this.syncQueue,
    required this.isOnline,
    required this.isLoading,
    this.error,
  });

  factory AsesorState.initial() => AsesorState(portfolio: [], syncQueue: [], isOnline: true, isLoading: false);

  AsesorState copyWith({
    List<dynamic>? portfolio,
    List<dynamic>? syncQueue,
    bool? isOnline,
    bool? isLoading,
    String? error,
  }) {
    return AsesorState(
      portfolio: portfolio ?? this.portfolio,
      syncQueue: syncQueue ?? this.syncQueue,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AsesorNotifier extends StateNotifier<AsesorState> {
  AsesorNotifier() : super(AsesorState.initial()) {
    // Listen for network changes
    ConnectivityService().onConnectivityChanged.listen((result) {
      final online = result != ConnectivityResult.none;
      state = state.copyWith(isOnline: online);
      if (online) {
        // Trigger auto sync
        syncOfflineData();
      }
    });
  }

  Future<void> checkConnection() async {
    final online = await ConnectivityService().isOnline;
    state = state.copyWith(isOnline: online);
  }

  Future<void> loadPortfolio() async {
    state = state.copyWith(isLoading: true, error: null);
    await checkConnection();

    if (state.isOnline) {
      try {
        final res = await DioClient().get('/fventas/cartera/hoy');
        final items = res.data as List<dynamic>;

        // Cache in SQLite
        await LocalDatabase.clearTable('local_cartera');
        for (var item in items) {
          await LocalDatabase.insert('local_cartera', {
            'id_cartera': item['id_cartera'],
            'id_asesor': item['id_asesor'],
            'id_cliente': item['id_cliente'],
            'id_solicitud': item['id_solicitud'],
            'fecha_asignacion': item['fecha_asignacion'],
            'tipo_gestion': item['tipo_gestion'],
            'prioridad': item['prioridad'],
            'score_prioridad': item['score_prioridad'],
            'estado_visita': item['estado_visita'],
            'resultado_visita': item['resultado_visita'],
            'observacion_visita': item['observacion_visita'],
            'lat_visita': item['lat_visita'] != null ? double.parse(item['lat_visita'].toString()) : null,
            'lng_visita': item['lng_visita'] != null ? double.parse(item['lng_visita'].toString()) : null,
            'timestamp_visita': item['timestamp_visita'],
          });
        }

        state = state.copyWith(portfolio: items, isLoading: false);
      } catch (e) {
        // Fallback to SQLite on failure
        final localItems = await LocalDatabase.query('local_cartera');
        state = state.copyWith(portfolio: localItems, isLoading: false, error: 'Cargada copia local.');
      }
    } else {
      // Offline: read from local SQLite
      final localItems = await LocalDatabase.query('local_cartera');
      state = state.copyWith(portfolio: localItems, isLoading: false);
    }

    await loadSyncQueue();
  }

  Future<void> loadSyncQueue() async {
    final queue = await LocalDatabase.query('local_sync_queue');
    state = state.copyWith(syncQueue: queue);
  }

  Future<Map<String, dynamic>?> getFichaCliente(String clientId) async {
    await checkConnection();
    if (state.isOnline) {
      try {
        final res = await DioClient().get('/fventas/clientes/$clientId/ficha');
        final data = res.data as Map<String, dynamic>;
        
        // Cache client data in SQLite
        final cliente = data['cliente'] as Map<String, dynamic>;
        await LocalDatabase.insert('local_clientes', {
          'id_cliente': cliente['id_cliente'],
          'documento': cliente['documento'],
          'nombres': cliente['nombres'],
          'apellidos': cliente['apellidos'],
          'telefono': cliente['telefono'],
          'correo': cliente['correo'],
          'direccion': cliente['direccion'],
          'distrito': cliente['distrito'],
          'provincia': cliente['provincia'],
          'departamento': cliente['departamento'],
          'fecha_nacimiento': cliente['fecha_nacimiento'],
          'estado_civil': cliente['estado_civil'],
          'ocupacion': cliente['ocupacion'],
          'tipo_cliente': cliente['tipo_cliente'],
          'estado': cliente['estado'],
        });
        
        return data;
      } catch (_) {
        return _getLocalFicha(clientId);
      }
    } else {
      return _getLocalFicha(clientId);
    }
  }

  Future<Map<String, dynamic>?> _getLocalFicha(String clientId) async {
    final res = await LocalDatabase.query('local_clientes', where: 'id_cliente = ?', whereArgs: [clientId]);
    if (res.isEmpty) return null;
    return {
      'cliente': res.first,
      'negocios': [] // offline negocio simplicity
    };
  }

  // Register Visit with offline support
  Future<bool> registerVisit({
    required String portfolioId,
    required String result,
    required String observation,
    required double lat,
    required double lng,
  }) async {
    final payload = {
      'id_cartera': portfolioId,
      'resultado': result,
      'observacion': observation,
      'lat': lat,
      'lng': lng,
    };

    await checkConnection();
    if (state.isOnline) {
      try {
        await DioClient().post('/fventas/visitas', data: payload);
        await loadPortfolio();
        return true;
      } catch (_) {
        await _queueOfflineVisit(portfolioId, payload);
        return true;
      }
    } else {
      await _queueOfflineVisit(portfolioId, payload);
      return true;
    }
  }

  Future<void> _queueOfflineVisit(String portfolioId, Map<String, dynamic> payload) async {
    final idVisita = const Uuid().v4();
    // 1. Save in local table
    await LocalDatabase.insert('local_visitas_pendientes', {
      'id_visita': idVisita,
      'id_cartera': portfolioId,
      'resultado': payload['resultado'],
      'observacion': payload['observacion'],
      'lat': payload['lat'],
      'lng': payload['lng'],
      'fecha_hora': DateTime.now().toIso8601String(),
    });

    // 2. Queue sync item
    await LocalDatabase.insert('local_sync_queue', {
      'id_sync': const Uuid().v4(),
      'tipo': 'VISITA',
      'entidad_id': portfolioId,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. Update local portfolio visual state
    await LocalDatabase.update(
      'local_cartera',
      {
        'estado_visita': 'REALIZADA',
        'resultado_visita': payload['resultado'],
        'observacion_visita': payload['observacion'],
        'lat_visita': payload['lat'],
        'lng_visita': payload['lng'],
        'timestamp_visita': DateTime.now().toIso8601String(),
      },
      where: 'id_cartera = ?',
      whereArgs: [portfolioId],
    );

    await loadPortfolio();
  }

  // Submit Loan Request with offline support
  Future<Map<String, dynamic>?> submitLoanRequest(Map<String, dynamic> payload) async {
    await checkConnection();
    if (state.isOnline) {
      try {
        final res = await DioClient().post('/fventas/solicitudes', data: payload);
        await loadPortfolio();
        return res.data as Map<String, dynamic>;
      } catch (_) {
        return await _queueOfflineRequest(payload);
      }
    } else {
      return await _queueOfflineRequest(payload);
    }
  }

  Future<Map<String, dynamic>> _queueOfflineRequest(Map<String, dynamic> payload) async {
    final idSol = const Uuid().v4();
    
    // Save locally
    await LocalDatabase.insert('local_solicitudes_pendientes', {
      'id_solicitud': idSol,
      'id_producto_credito': payload['id_producto_credito'],
      'monto_solicitado': payload['monto_solicitado'],
      'plazo_meses': payload['plazo_meses'],
      'con_seguro_desgravamen': payload['con_seguro_desgravamen'] == true ? 1 : 0,
      'garantia': payload['garantia'],
      'destino_credito': payload['destino_credito'],
      'lat_captura': payload['lat_captura'],
      'lng_captura': payload['lng_captura'],
      'created_at': DateTime.now().toIso8601String(),
    });

    // Queue sync item
    await LocalDatabase.insert('local_sync_queue', {
      'id_sync': const Uuid().v4(),
      'tipo': 'SOLICITUD',
      'entidad_id': idSol,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });

    await loadSyncQueue();

    // Return mockup response
    return {
      'id_solicitud': idSol,
      'numero_expediente': 'EXP-OFFLINE-${idSol.substring(0, 8).toUpperCase()}',
      'monto_solicitado': payload['monto_solicitado'],
      'plazo_meses': payload['plazo_meses'],
      'estado': 'BORRADOR',
      'cuota_estimada': (payload['monto_solicitado'] as double) / (payload['plazo_meses'] as int), // simplistic cuota
      'tea_referencial': 30.0,
      'moneda': 'PEN',
      'con_seguro_desgravamen': payload['con_seguro_desgravamen'],
      'id_cliente': 'offline',
      'id_negocio': 'offline',
      'id_producto_credito': payload['id_producto_credito'],
      'canal_origen': 'ASESOR',
      'pendiente_sync': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Run synchronization
  Future<void> syncOfflineData() async {
    await checkConnection();
    if (!state.isOnline) return;

    final queue = await LocalDatabase.query('local_sync_queue');
    if (queue.isEmpty) return;

    state = state.copyWith(isLoading: true);

    for (var item in queue) {
      final idSync = item['id_sync'] as String;
      final tipo = item['tipo'] as String;
      final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;

      try {
        if (tipo == 'VISITA') {
          await DioClient().post('/fventas/visitas', data: payload);
        } else if (tipo == 'SOLICITUD') {
          await DioClient().post('/fventas/solicitudes', data: payload);
        }
        
        // Remove from queue on success
        await LocalDatabase.delete('local_sync_queue', where: 'id_sync = ?', whereArgs: [idSync]);
      } catch (_) {
        // Stop sync on error to prevent out of order
        break;
      }
    }

    state = state.copyWith(isLoading: false);
    await loadPortfolio();
  }
}

final asesorProvider = StateNotifierProvider<AsesorNotifier, AsesorState>((ref) {
  return AsesorNotifier();
});
