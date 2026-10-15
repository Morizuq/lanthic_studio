import 'dart:convert';
import 'package:dio/dio.dart';
import '../errors/failures.dart';

class NetworkFailure extends StudioFailure {
  const NetworkFailure(
    super.message, {
    this.statusCode,
    super.details,
    super.cause,
  });

  final int? statusCode;

  factory NetworkFailure.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final dynamic rawData = e.response?.data;
    String? messageFromData;

    if (rawData is Map<String, dynamic>) {
      messageFromData = (rawData['message'] ?? rawData['error'])?.toString();
    } else if (rawData is List<int> && rawData.isNotEmpty) {
      try {
        final text = utf8.decode(rawData, allowMalformed: true).trim();
        if (text.startsWith('{') && text.endsWith('}')) {
          final parsed = jsonDecode(text);
          if (parsed is Map) {
            messageFromData = (parsed['message'] ?? parsed['error'])
                ?.toString();
          }
        } else if (!text.startsWith('<')) {
          // Plain text error message
          messageFromData = text;
        }
      } catch (_) {
        // Ignored
      }
    }

    if (messageFromData != null && messageFromData.isNotEmpty) {
      return NetworkFailure(
        messageFromData,
        statusCode: statusCode,
        details: e.response?.statusMessage,
        cause: e,
      );
    }

    if (statusCode == 401) {
      return NetworkFailure(
        'Authentication required (401). Please check or configure your API token in Settings.',
        statusCode: 401,
        details: 'Invalid or missing API key',
        cause: e,
      );
    }
    if (statusCode == 403) {
      return NetworkFailure(
        'Access denied (403). Your API token does not have permission for this model.',
        statusCode: 403,
        details: e.response?.statusMessage,
        cause: e,
      );
    }
    if (statusCode == 404) {
      return NetworkFailure(
        'Model endpoint not found (404).',
        statusCode: 404,
        details: e.response?.statusMessage,
        cause: e,
      );
    }
    if (statusCode == 429) {
      return NetworkFailure(
        'Provider rate limit reached (429). Please try again shortly.',
        statusCode: 429,
        details: e.response?.statusMessage,
        cause: e,
      );
    }
    if (statusCode == 503) {
      return NetworkFailure(
        'Model is currently loading (503). Please retry in 20-30 seconds.',
        statusCode: 503,
        details: e.response?.statusMessage,
        cause: e,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkFailure(
        'Connection timed out. Please check your network connection.',
        statusCode: statusCode,
        details: e.message,
        cause: e,
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkFailure(
        'Network connection error. Please verify your internet connection.',
        statusCode: statusCode,
        details: e.message,
        cause: e,
      );
    }

    return NetworkFailure(
      'Network request failed with status $statusCode.',
      statusCode: statusCode,
      details: e.response?.statusMessage,
      cause: e,
    );
  }
}

typedef AppFailure = NetworkFailure;
