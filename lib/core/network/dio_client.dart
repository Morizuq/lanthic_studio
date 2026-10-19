import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/console_analytics_service.dart';
import '../config/config_provider.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'network_constants.dart';


/// Riverpod dependency injection provider configuring the application-wide [Dio] HTTP client.
///
/// Features:
/// - Base URL configuration derived from [configProvider].
/// - Strict network timeouts (connect, receive, and send) via [NetworkConstants].
/// - [AuthInterceptor] to safely attach bearer tokens to internal backends.
/// - [NetworkLoggingInterceptor] to stream redacted HTTP telemetry to analytics.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(configProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final analytics = ref.watch(analyticsServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.serverpodUrl ?? '',
      connectTimeout: NetworkConstants.defaultConnectTimeout,
      receiveTimeout: NetworkConstants.defaultReceiveTimeout,
      sendTimeout: NetworkConstants.defaultSendTimeout,
      headers: {
        NetworkConstants.acceptHeaderKey: NetworkConstants.jsonContentType,
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(secureStorage: secureStorage, config: config),
    NetworkLoggingInterceptor(analytics),
  ]);

  return dio;
});

