import 'dart:developer' as developer;
import '../analytics/analytics_service.dart';

enum StudioLogLevel { debug, info, warning, error }

abstract class StudioLogger {
  void log(StudioLogLevel level, String message, {Object? error, StackTrace? stackTrace});
  void debug(String message);
  void info(String message);
  void warning(String message, [Object? error]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

class ConsoleStudioLogger implements StudioLogger {
  const ConsoleStudioLogger({this.tag = 'LanthicStudio'});

  final String tag;

  @override
  void log(StudioLogLevel level, String message, {Object? error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    developer.log(
      '[$timestamp] [${level.name.toUpperCase()}] $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void debug(String message) => log(StudioLogLevel.debug, message);

  @override
  void info(String message) => log(StudioLogLevel.info, message);

  @override
  void warning(String message, [Object? error]) =>
      log(StudioLogLevel.warning, message, error: error);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      log(StudioLogLevel.error, message, error: error, stackTrace: stackTrace);
}

class AnalyticsStudioLogger implements StudioLogger {
  const AnalyticsStudioLogger(this._analyticsService);

  final AnalyticsService _analyticsService;

  @override
  void log(StudioLogLevel level, String message, {Object? error, StackTrace? stackTrace}) {
    _analyticsService.logMessage(level, message, error: error, stackTrace: stackTrace);
  }

  @override
  void debug(String message) => log(StudioLogLevel.debug, message);

  @override
  void info(String message) => log(StudioLogLevel.info, message);

  @override
  void warning(String message, [Object? error]) =>
      log(StudioLogLevel.warning, message, error: error);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      log(StudioLogLevel.error, message, error: error, stackTrace: stackTrace);
}
