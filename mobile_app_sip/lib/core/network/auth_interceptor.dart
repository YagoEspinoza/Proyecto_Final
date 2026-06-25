import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expirado o invalido
      await SecureStorageService.delete('jwt_token');
      await SecureStorageService.delete('user_role');
      await SecureStorageService.delete('user_data');
      // Podria dispararse un evento de logout o redireccion
    }
    handler.next(err);
  }
}
