import 'package:dio/dio.dart';
import '../../analytics/analytics_service.dart';
import '../../logging/studio_logger.dart';

class NetworkLoggingInterceptor extends Interceptor {
  NetworkLoggingInterceptor(this._analyticsService);

  final AnalyticsService _analyticsService;
  final Map<int, DateTime> _requestTimestamps = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestTimestamps[options.hashCode] = DateTime.now();

    _analyticsService.logMessage(
      StudioLogLevel.info,
      'REQUEST [${options.method}] => URL: ${options.uri}\n'
      'HEADERS: ${_sanitizeHeaders(options.headers)}\n'
      'DATA: ${options.data}',
    );

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = _requestTimestamps.remove(
      response.requestOptions.hashCode,
    );
    final durationMs = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : null;

    _analyticsService.logNetworkCall(
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      statusCode: response.statusCode,
      durationMs: durationMs,
    );

    final dataSummary = response.data is List<int>
        ? 'Binary (${(response.data as List<int>).length} bytes)'
        : response.data.toString();

    _analyticsService.logMessage(
      StudioLogLevel.info,
      'RESPONSE [${response.statusCode}] (${durationMs ?? 0}ms) <= URL: ${response.requestOptions.uri}\n'
      'DATA: $dataSummary',
    );

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = _requestTimestamps.remove(err.requestOptions.hashCode);
    final durationMs = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : null;

    _analyticsService.logNetworkCall(
      method: err.requestOptions.method,
      url: err.requestOptions.uri.toString(),
      statusCode: err.response?.statusCode,
      durationMs: durationMs,
      error: err.message,
    );

    String? responseBody;
    final resData = err.response?.data;
    if (resData is List<int>) {
      try {
        responseBody = String.fromCharCodes(resData);
      } catch (_) {
        responseBody = 'Binary (${resData.length} bytes)';
      }
    } else if (resData != null) {
      responseBody = resData.toString();
    }

    _analyticsService.logMessage(
      StudioLogLevel.error,
      'ERROR [${err.response?.statusCode ?? 'N/A'}] (${durationMs ?? 0}ms) <= URL: ${err.requestOptions.uri}\n'
      'MESSAGE: ${err.message}\n'
      'RESPONSE BODY: ${responseBody ?? 'None'}',
      error: err,
      stackTrace: err.stackTrace,
    );

    super.onError(err, handler);
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = 'Bearer [REDACTED]';
    }
    if (sanitized.containsKey('X-Key')) {
      sanitized['X-Key'] = '[REDACTED]';
    }
    return sanitized;
  }
}

typedef AppLoggingInterceptor = NetworkLoggingInterceptor;
