import '../logging/studio_logger.dart';
import 'analytics_event.dart';

abstract class AnalyticsService {
  Future<void> logEvent(AnalyticsEvent event);
  Future<void> logMetric(String name, num value, {Map<String, dynamic>? properties});
  Future<void> logNetworkCall({
    required String method,
    required String url,
    int? statusCode,
    int? durationMs,
    String? error,
  });
  void logMessage(
    StudioLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
  Future<void> setCurrentScreen(String screenName);
  Future<void> setUserId(String userId);
  Future<void> setUserProperty(String name, String value);
  Future<void> clearUser();
}
