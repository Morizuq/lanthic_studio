import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/studio_logger.dart';
import 'analytics_event.dart';
import 'analytics_service.dart';

class ConsoleAnalyticsService implements AnalyticsService {
  const ConsoleAnalyticsService({this.tag = 'LanthicAnalytics'});

  final String tag;

  void _printToConsole(String formatted) {
    dev.log(formatted, name: tag);
    debugPrint('[$tag] $formatted');
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    final timestamp = DateTime.now().toIso8601String();
    _printToConsole('[$timestamp] [EVENT] ${event.name} ${event.parameters ?? {}}');
  }

  @override
  Future<void> logMetric(String name, num value, {Map<String, dynamic>? properties}) async {
    final timestamp = DateTime.now().toIso8601String();
    _printToConsole('[$timestamp] [METRIC] $name = $value ${properties ?? {}}');
  }

  @override
  Future<void> logNetworkCall({
    required String method,
    required String url,
    int? statusCode,
    int? durationMs,
    String? error,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final statusStr = statusCode != null ? 'HTTP $statusCode' : (error != null ? 'FAILED' : 'PENDING');
    final durationStr = durationMs != null ? ' (${durationMs}ms)' : '';
    final errorStr = error != null ? ' - Error: $error' : '';

    _printToConsole('[$timestamp] [NETWORK] $method $url -> $statusStr$durationStr$errorStr');
  }

  @override
  void logMessage(
    StudioLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final errorSuffix = error != null ? '\nError: $error' : '';
    _printToConsole('[$timestamp] [${level.name.toUpperCase()}] $message$errorSuffix');
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    dev.log('[SCREEN] $screenName', name: tag);
  }

  @override
  Future<void> setUserId(String userId) async {
    dev.log('[USER_ID] $userId', name: tag);
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    dev.log('[USER_PROP] $name = $value', name: tag);
  }

  @override
  Future<void> clearUser() async {
    dev.log('[USER_CLEAR]', name: tag);
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const ConsoleAnalyticsService();
});
