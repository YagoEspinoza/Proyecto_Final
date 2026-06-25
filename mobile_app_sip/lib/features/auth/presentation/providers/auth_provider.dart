import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';

enum AuthStatus { initial, loading, authenticated, error, locked }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  AuthState({
    required this.status,
    this.errorMessage,
    this.userData,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(Map<String, dynamic> data) =>
      AuthState(status: AuthStatus.authenticated, userData: data);
  factory AuthState.error(String msg) => AuthState(status: AuthStatus.error, errorMessage: msg);
  factory AuthState.locked(String msg) => AuthState(status: AuthStatus.locked, errorMessage: msg);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());

  Future<void> login({
    String? documento,
    String? codigoEmpleado,
    required String password,
  }) async {
    state = AuthState.loading();
    final username = documento ?? codigoEmpleado ?? 'unknown';

    // 1. Check local lockout first
    final isLocked = await SecureStorageService.isUserLocked(username);
    if (isLocked) {
      final lockTime = await SecureStorageService.getLockoutTime(username);
      final remaining = lockTime != null ? lockTime.difference(DateTime.now()).inMinutes : 30;
      state = AuthState.locked(
        'Cuenta bloqueada por múltiples intentos fallidos. Intente en $remaining minutos.',
      );
      return;
    }

    try {
      final payload = {
        'documento': documento,
        'codigo_empleado': codigoEmpleado,
        'password': password,
      };

      final response = await DioClient().post('/auth/login', data: payload);
      final data = response.data as Map<String, dynamic>;
      
      final token = data['access_token'] as String;
      final user = data['usuario'] as Map<String, dynamic>;
      final role = user['rol'] as String;

      // Reset login attempts on success
      await SecureStorageService.resetLoginAttempts(username);

      // Save credentials and user data
      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveRole(role);
      await SecureStorageService.saveUserData(user);

      state = AuthState.authenticated(user);
    } on DioException catch (e) {
      // Handle login failure
      await SecureStorageService.incrementLoginAttempts(username);
      final attempts = await SecureStorageService.getLoginAttempts(username);
      
      if (attempts >= 5) {
        await SecureStorageService.lockoutUser(username);
        state = AuthState.locked(
          'Ha superado el número máximo de intentos fallidos. Cuenta bloqueada por 30 minutos.',
        );
      } else {
        final remaining = 5 - attempts;
        final errorMsg = e.response?.data['detail'] ?? 'Error de conexión';
        state = AuthState.error(
          '$errorMsg. Intentos restantes: $remaining',
        );
      }
    } catch (e) {
      state = AuthState.error('Error inesperado: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await DioClient().post('/auth/logout');
    } catch (_) {}
    await SecureStorageService.clearAll();
    state = AuthState.initial();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
