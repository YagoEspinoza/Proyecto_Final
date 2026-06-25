import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

class CreditsState {
  final List<dynamic> credits;
  final List<dynamic> selectedCronograma;
  final bool isLoading;
  final String? error;

  CreditsState({
    required this.credits,
    required this.selectedCronograma,
    required this.isLoading,
    this.error,
  });

  factory CreditsState.initial() => CreditsState(credits: [], selectedCronograma: [], isLoading: false);

  CreditsState copyWith({
    List<dynamic>? credits,
    List<dynamic>? selectedCronograma,
    bool? isLoading,
    String? error,
  }) {
    return CreditsState(
      credits: credits ?? this.credits,
      selectedCronograma: selectedCronograma ?? this.selectedCronograma,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CreditsNotifier extends StateNotifier<CreditsState> {
  CreditsNotifier() : super(CreditsState.initial());

  Future<void> loadCredits() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await DioClient().get('/cliente/creditos');
      state = state.copyWith(
        credits: res.data as List<dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error al cargar créditos');
    }
  }

  Future<void> loadCronograma(String creditId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await DioClient().get('/cliente/creditos/$creditId/cronograma');
      state = state.copyWith(
        selectedCronograma: res.data as List<dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error al cargar cronograma');
    }
  }

  Future<bool> payInstallment({
    required String accountId,
    required String creditId,
    required String cuotaId,
    required double amount,
  }) async {
    try {
      final payload = {
        'cuenta_origen_id': accountId,
        'id_credito': creditId,
        'id_cuota': cuotaId,
        'monto': amount,
      };
      await DioClient().post('/cliente/operaciones/pago-credito', data: payload);
      // Reload details
      await loadCredits();
      await loadCronograma(creditId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final creditsProvider = StateNotifierProvider<CreditsNotifier, CreditsState>((ref) {
  return CreditsNotifier();
});
