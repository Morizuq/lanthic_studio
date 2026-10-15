import 'package:dio/dio.dart';
import '../../config/config.dart';
import '../../storage/secure_storage_service.dart';

/// Authentication interceptor scoped strictly to internal backend requests.
///
/// Prevents bearer token leakage to third-party image generation APIs
/// (e.g. FLUX, Imagen, SDXL) and avoids broken refresh loops when running
/// in local-first desktop mode without an active backend.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.secureStorage,
    required this.config,
    this.refreshDio,
  });

  final SecureStorageService secureStorage;
  final AppConfig config;
  final Dio? refreshDio;

  static const String sessionTokenKey = 'auth_session_token';
  static const String refreshTokenKey = 'auth_refresh_token';

  bool _isInternalBackend(Uri uri) {
    if (!config.hasBackend) return false;
    final backendUri = Uri.tryParse(config.serverpodUrl!);
    if (backendUri == null) return false;
    return uri.host == backendUri.host && uri.port == backendUri.port;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only attach auth tokens when targeting the configured internal backend (Serverpod)
    if (_isInternalBackend(options.uri)) {
      final token = await secureStorage.read(sessionTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (!options.headers.containsKey('Accept')) {
      options.headers['Accept'] = 'application/json';
    }

    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If not targeting our internal backend, do not attempt backend token refresh
    if (!_isInternalBackend(err.requestOptions.uri)) {
      return super.onError(err, handler);
    }

    final path = err.requestOptions.path;
    final isPublicAuth = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh');

    if (err.response?.statusCode == 401 && !isPublicAuth && refreshDio != null) {
      final refreshToken = await secureStorage.read(refreshTokenKey);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final response = await refreshDio!.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200 && response.data != null) {
            final data = response.data!['data'] as Map<String, dynamic>?;
            final newAccessToken = data?['access_token']?.toString();
            final newRefreshToken = data?['refresh_token']?.toString();

            if (newAccessToken != null) {
              await secureStorage.write(sessionTokenKey, newAccessToken);
              if (newRefreshToken != null) {
                await secureStorage.write(refreshTokenKey, newRefreshToken);
              }

              err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await refreshDio!.fetch<dynamic>(err.requestOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          // Token refresh failed silently; proceed with error
        }
      }
    }

    super.onError(err, handler);
  }
}
