import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

class SolicitudesState {
  final List<dynamic> solicitudes;
  final bool isLoading;
  final String? error;

  SolicitudesState({
    required this.solicitudes,
    required this.isLoading,
    this.error,
  });

  factory SolicitudesState.initial() => SolicitudesState(solicitudes: [], isLoading: false);

  SolicitudesState copyWith({
    List<dynamic>? solicitudes,
    bool? isLoading,
    String? error,
  }) {
    return SolicitudesState(
      solicitudes: solicitudes ?? this.solicitudes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SolicitudesNotifier extends StateNotifier<SolicitudesState> {
  SolicitudesNotifier() : super(SolicitudesState.initial());

  Future<void> loadSolicitudes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await DioClient().get('/cliente/solicitudes');
      state = state.copyWith(
        solicitudes: res.data as List<dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error al cargar solicitudes');
    }
  }

  Future<bool> createSolicitud({
    required String productId,
    required double amount,
    required int termMonths,
    required bool withInsurance,
    required String warranty,
    required String purpose,
    double? lat,
    double? lng,
  }) async {
    try {
      final payload = {
        'id_producto_credito': productId,
        'monto_solicitado': amount,
        'plazo_meses': termMonths,
        'con_seguro_desgravamen': withInsurance,
        'garantia': warranty,
        'destino_credito': purpose,
        'lat_captura': lat,
        'lng_captura': lng,
      };
      await DioClient().post('/cliente/solicitudes', data: payload);
      await loadSolicitudes();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final solicitudesProvider = StateNotifierProvider<SolicitudesNotifier, SolicitudesState>((ref) {
  return SolicitudesNotifier();
});
