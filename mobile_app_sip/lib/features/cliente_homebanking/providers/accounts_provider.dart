import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

class AccountsState {
  final List<dynamic> accounts;
  final List<dynamic> cards;
  final List<dynamic> movements;
  final bool isLoading;
  final String? error;

  AccountsState({
    required this.accounts,
    required this.cards,
    required this.movements,
    required this.isLoading,
    this.error,
  });

  factory AccountsState.initial() => AccountsState(accounts: [], cards: [], movements: [], isLoading: false);
  
  AccountsState copyWith({
    List<dynamic>? accounts,
    List<dynamic>? cards,
    List<dynamic>? movements,
    bool? isLoading,
    String? error,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      cards: cards ?? this.cards,
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AccountsNotifier extends StateNotifier<AccountsState> {
  AccountsNotifier() : super(AccountsState.initial());

  Future<void> loadHomebankingData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final accountsRes = await DioClient().get('/cliente/cuentas');
      final cardsRes = await DioClient().get('/cliente/tarjetas');
      final movementsRes = await DioClient().get('/cliente/movimientos');

      state = state.copyWith(
        accounts: accountsRes.data as List<dynamic>,
        cards: cardsRes.data as List<dynamic>,
        movements: movementsRes.data as List<dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'No se pudieron cargar los datos de homebanking.');
    }
  }

  Future<bool> executeTransfer({
    required String accountId,
    required String destinationNumber,
    required double amount,
    String? description,
  }) async {
    try {
      final payload = {
        'cuenta_origen_id': accountId,
        'cuenta_destino_numero': destinationNumber,
        'monto': amount,
        'descripcion': description,
      };
      await DioClient().post('/cliente/operaciones/transferencia', data: payload);
      // Reload details after transfer
      await loadHomebankingData();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, AccountsState>((ref) {
  return AccountsNotifier();
});
