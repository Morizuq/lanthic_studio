import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/core/analytics/analytics_event.dart';
import 'package:lanthic_studio/core/analytics/analytics_service.dart';
import 'package:lanthic_studio/core/config/app_environment.dart';
import 'package:lanthic_studio/core/config/config.dart';
import 'package:lanthic_studio/core/logging/studio_logger.dart';
import 'package:lanthic_studio/core/network/app_failure.dart';
import 'package:lanthic_studio/core/network/interceptors/auth_interceptor.dart';
import 'package:lanthic_studio/core/network/interceptors/logging_interceptor.dart';
import 'package:lanthic_studio/core/storage/secure_credential_store.dart';
import 'package:lanthic_studio/core/storage/secure_storage_service.dart';
import 'package:lanthic_studio/core/storage/storage_service.dart';

class MockAnalyticsService implements AnalyticsService {
  final List<String> networkCalls = [];
  final List<String> messages = [];

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> logMetric(String name, num value, {Map<String, dynamic>? properties}) async {}

  @override
  Future<void> logNetworkCall({
    required String method,
    required String url,
    int? statusCode,
    int? durationMs,
    String? error,
  }) async {
    networkCalls.add('$method $url -> $statusCode');
  }

  @override
  void logMessage(
    StudioLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add('[${level.name}] $message');
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {}

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}

  @override
  Future<void> clearUser() async {}
}

class FakeSecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();
}

void main() {
  group('Network and Core Surgical Update', () {
    test('AuthInterceptor only attaches bearer tokens to configured internal backend', () async {
      final fakeStorage = FakeSecureStorage();
      await fakeStorage.write(AuthInterceptor.sessionTokenKey, 'secret_serverpod_jwt');

      const configWithBackend = AppConfig(
        environment: AppEnvironment.dev,
        serverpodUrl: 'http://localhost:8080',
      );

      final interceptor = AuthInterceptor(
        secureStorage: fakeStorage,
        config: configWithBackend,
      );

      // 1. External request (e.g. FLUX)
      final externalOptions = RequestOptions(path: 'https://api.bfl.ml/v1/flux-pro-1.1');
      await interceptor.onRequest(externalOptions, RequestInterceptorHandler());
      expect(externalOptions.headers.containsKey('Authorization'), isFalse);

      // 2. Internal request (Serverpod backend)
      final internalOptions = RequestOptions(
        baseUrl: 'http://localhost:8080',
        path: '/story/sync',
      );
      await interceptor.onRequest(internalOptions, RequestInterceptorHandler());
      expect(internalOptions.headers['Authorization'], 'Bearer secret_serverpod_jwt');
    });

    test('NetworkLoggingInterceptor records network calls to AnalyticsService and sanitizes headers', () async {
      final mockAnalytics = MockAnalyticsService();
      final interceptor = NetworkLoggingInterceptor(mockAnalytics);

      final reqOptions = RequestOptions(
        path: 'https://api.bfl.ml/v1/flux',
        headers: {'X-Key': 'secret_key_1234'},
      );

      interceptor.onRequest(reqOptions, RequestInterceptorHandler());
      expect(mockAnalytics.messages.any((m) => m.contains('[REDACTED]')), isTrue);
      expect(mockAnalytics.messages.any((m) => m.contains('secret_key_1234')), isFalse);

      final response = Response(
        requestOptions: reqOptions,
        statusCode: 200,
      );
      interceptor.onResponse(response, ResponseInterceptorHandler());
      expect(mockAnalytics.networkCalls, contains('GET https://api.bfl.ml/v1/flux -> 200'));
    });

    test('NetworkFailure converts DioException timeout to StudioFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final failure = NetworkFailure.fromDioException(dioException);
      expect(failure.message, contains('timed out'));
    });

    test('SecureCredentialStore stores and retrieves provider keys cleanly', () async {
      final fakeStorage = FakeSecureStorage();
      final store = SecureCredentialStore(storageService: fakeStorage);

      await store.writeApiKey('flux', 'bfl_live_key');
      final retrieved = await store.readApiKey('flux');
      expect(retrieved, 'bfl_live_key');

      await store.deleteApiKey('flux');
      final afterDelete = await store.readApiKey('flux');
      expect(afterDelete, isNull);
    });

    test('InMemoryStorageService provides resilient local preference storage', () async {
      final storage = InMemoryStorageService();
      await storage.setString('last_opened_project', '/Users/test/story');
      expect(storage.getString('last_opened_project'), '/Users/test/story');

      await storage.setBool('show_grid', true);
      expect(storage.getBool('show_grid'), isTrue);
    });

    test('SecureStorageServiceImpl gracefully falls back when macOS Keychain throws -34018', () async {
      final failingStorage = _FailingEntitlementSecureStorage();
      final resilientService = SecureStorageServiceImpl(failingStorage);

      // Should not throw PlatformException(-34018)
      await resilientService.write('test_api_key', 'hf_live_token_123');
      final retrieved = await resilientService.read('test_api_key');
      expect(retrieved, 'hf_live_token_123');

      await resilientService.delete('test_api_key');
      final afterDelete = await resilientService.read('test_api_key');
      expect(afterDelete, isNull);
    });
  });
}

class _FailingEntitlementSecureStorage extends FlutterSecureStorage {
  _FailingEntitlementSecureStorage();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw PlatformException(
      code: '-34018',
      message: 'A required entitlement is not present.',
    );
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw PlatformException(
      code: '-34018',
      message: 'A required entitlement is not present.',
    );
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw PlatformException(
      code: '-34018',
      message: 'A required entitlement is not present.',
    );
  }
}

