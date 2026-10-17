import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/errors/failures.dart';
import '../../core/logging/studio_logger.dart';
import '../../core/network/network_constants.dart';
import '../../domain/models/image_prompt_model.dart';
import '../../domain/models/synthesis_request.dart';
import '../../domain/repositories/image_provider_contract.dart';

class QwenImageProvider implements ImageProviderContract {
  QwenImageProvider({Dio? dio, this.analytics}) : _dio = dio ?? Dio();

  final Dio _dio;
  final AnalyticsService? analytics;

  static final Lock _pollinationsLock = Lock();
  static bool _hfCreditsDepleted = false;

  /// Resets the HF credits circuit-breaker (e.g. when user updates HF token in settings).
  static void resetHfCreditsCircuitBreaker() {
    _hfCreditsDepleted = false;
  }

  @override
  String get providerIdentifier => 'qwen';

  @override
  String get displayName => 'HF Inference (FLUX)';

  @override
  bool get isFreeOpenSource => true;

  @override
  String get description =>
      'Open-source vision generation routed via Hugging Face Inference Providers';

  static const String defaultEndpoint =
      'https://router.huggingface.co/fal-ai/models/fal-ai/flux/schnell';

  static const List<String> serverlessEndpoints = [
    'https://router.huggingface.co/fal-ai/models/fal-ai/flux/schnell',
    'https://router.huggingface.co/wavespeed/models/wavespeed-ai/flux-schnell',
    'https://router.huggingface.co/hf-inference/models/stabilityai/stable-diffusion-3-medium-diffusers',
  ];

  @override
  Future<ImageGenerationResult> generateFromRequest({
    required SynthesisRequest request,
    required String apiKey,
    Map<String, dynamic> extraParameters = const {},
  }) {
    final dims = request.aspectRatio.toDimensions(ModelArch.flux);
    return generate(
      prompt: request.cleanPrompt,
      apiKey: apiKey,
      extraParameters: {
        'scene_id': request.sceneId,
        'width': dims.width,
        'height': dims.height,
        'seed': request.seed,
        'aspect_ratio': request.aspectRatio.label,
        ...extraParameters,
      },
    );
  }

  @override
  Future<ImageGenerationResult> generate({
    required String prompt,
    required String apiKey,
    Map<String, dynamic> extraParameters = const {},
  }) async {
    final customEndpoint = extraParameters['custom_endpoint']?.toString();
    final isLocalEndpoint =
        customEndpoint != null &&
        (customEndpoint.contains('localhost') ||
            customEndpoint.contains('127.0.0.1'));

    final cleanPrompt = ImagePromptItem.sanitizePrompt(prompt);
    if (cleanPrompt.isEmpty) {
      throw GenerationFailure(
        'Prompt cannot be empty for image generation.',
        sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
        provider: providerIdentifier,
      );
    }

    final startTime = DateTime.now();
    final promptHash = md5
        .convert(utf8.encode(cleanPrompt))
        .toString()
        .substring(0, 13);

    // Hugging Face router Text-to-Image requires integer dimensions (width & height),
    // rejecting raw string parameters like 'aspect_ratio': '16:9'.
    final validParameters = <String, dynamic>{};
    final ar = extraParameters['aspect_ratio']?.toString() ?? '16:9';
    final int width;
    final int height;
    switch (ar) {
      case '16:9':
        width = 1024;
        height = 576;
        break;
      case '9:16':
        width = 576;
        height = 1024;
        break;
      case '1:1':
        width = 1024;
        height = 1024;
        break;
      case '4:3':
        width = 1024;
        height = 768;
        break;
      case '21:9':
        width = 1344;
        height = 576;
        break;
      default:
        width = 1024;
        height = 576;
        break;
    }
    validParameters['width'] = width;
    validParameters['height'] = height;

    if (extraParameters['steps'] != null) {
      validParameters['num_inference_steps'] = extraParameters['steps'];
    }

    final hfPayload = <String, dynamic>{
      'inputs': cleanPrompt,
    };

    final endpointsToTry = customEndpoint != null && customEndpoint.isNotEmpty
        ? [customEndpoint, ...serverlessEndpoints]
        : serverlessEndpoints;

    analytics?.logMessage(
      StudioLogLevel.info,
      '[HF Provider] Starting synthesis for scene "${extraParameters['scene_id'] ?? 'unknown'}"\n'
      'Prompt: "$cleanPrompt" (hash: $promptHash)\n'
      'Candidate endpoints (${endpointsToTry.length}): $endpointsToTry',
    );

    Response<dynamic>? successfulResponse;

    // Try Hugging Face router candidates first if an API key is available and circuit-breaker is not engaged
    if (_hfCreditsDepleted) {
      analytics?.logMessage(
        StudioLogLevel.info,
        '[HF Provider] HF credits circuit-breaker is active. Skipping candidate endpoints and routing directly to Pollinations...',
      );
    } else if (apiKey.trim().isNotEmpty || isLocalEndpoint) {
      for (final endpoint in endpointsToTry) {
        try {
          analytics?.logMessage(
            StudioLogLevel.info,
            '[HF Provider] Attempting candidate endpoint: $endpoint',
          );

          final response = await _dio.post<dynamic>(
            endpoint,
            data: hfPayload,
            options: Options(
              sendTimeout: NetworkConstants.generationTimeout,
              receiveTimeout: NetworkConstants.generationTimeout,
              responseType: ResponseType.bytes,
              headers: {
                if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
                'Accept': 'image/png, image/jpeg, */*',
                'x-wait-for-model': 'true',
                NetworkConstants.contentTypeHeaderKey:
                    NetworkConstants.jsonContentType,
              },
            ),
          );
          successfulResponse = response;
          break;
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          String responseBodyStr = '';
          final resData = e.response?.data;
          if (resData is List<int>) {
            try {
              responseBodyStr = utf8.decode(resData, allowMalformed: true);
            } catch (_) {
              responseBodyStr = String.fromCharCodes(resData);
            }
          } else if (resData != null) {
            responseBodyStr = resData.toString();
          }

          // If HF returns 402 (Payment Required / No remaining credits), engage circuit-breaker
          if (status == 402 ||
              responseBodyStr.toLowerCase().contains('no remaining credits')) {
            _hfCreditsDepleted = true;
            analytics?.logMessage(
              StudioLogLevel.warning,
              '[HF Provider] HF credits depleted (HTTP 402: $responseBodyStr). Engaging circuit-breaker for this session.',
            );
            break;
          }

          analytics?.logMessage(
            StudioLogLevel.warning,
            '[HF Provider] Endpoint $endpoint failed with HTTP $status ($responseBodyStr). Falling over to next candidate...',
          );
          continue;
        } catch (e) {
          analytics?.logMessage(
            StudioLogLevel.warning,
            '[HF Provider] Endpoint $endpoint unexpected error: $e. Falling over to next candidate...',
          );
          continue;
        }
      }
    }

    // Guaranteed fallback: If all HF router endpoints fail or token lacks paid quotas,
    // immediately synthesize via zero-auth Pollinations FLUX generator
    if (successfulResponse == null) {
      analytics?.logMessage(
        StudioLogLevel.warning,
        '[WARNING] All HF endpoints failed, executing Pollinations FLUX fallback...',
      );

      try {
        final fallbackSeed = extraParameters['seed'] is int
            ? extraParameters['seed'] as int
            : null;

        final imageBytes = await _generateWithPollinationsFallback(
          cleanPrompt: cleanPrompt,
          width: width,
          height: height,
          seed: fallbackSeed,
        );

        final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
        analytics?.logMessage(
          StudioLogLevel.info,
          '[HF Provider] Successfully rendered fallback image frame (${imageBytes.lengthInBytes} bytes) in ${elapsedMs}ms for scene "${extraParameters['scene_id'] ?? 'unknown'}"',
        );

        return ImageGenerationResult(
          imageBytes: imageBytes,
          promptHash: promptHash,
          provider: 'qwen',
          costUsd: 0.0,
          generationTimeMs: elapsedMs,
        );
      } catch (fallbackError) {
        analytics?.logMessage(
          StudioLogLevel.error,
          '[HF Provider] Pollinations fallback also failed: $fallbackError',
        );
        throw GenerationFailure(
          'Generation failed: $fallbackError',
          sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
          provider: providerIdentifier,
          details: fallbackError.toString(),
        );
      }
    }

    try {
      final dynamic responseData = successfulResponse.data;
      final Uint8List imageBytes;
      if (responseData is List<int> && responseData.length > 100) {
        imageBytes = Uint8List.fromList(responseData);
      } else {
        // Fallback for possible JSON string or map
        String? b64;
        try {
          final decoded = jsonDecode(utf8.decode(responseData as List<int>));
          if (decoded is Map<String, dynamic>) {
            b64 =
                decoded['b64_json'] ??
                (decoded['images'] as List?)?.firstOrNull?['b64_json'] ??
                (decoded['data'] as List?)?.firstOrNull?['b64_json'] ??
                decoded['image'];
          }
        } catch (_) {}

        if (b64 != null && b64.isNotEmpty) {
          imageBytes = base64Decode(
            b64.contains(',') ? b64.split(',').last : b64,
          );
        } else {
          throw GenerationFailure(
            'Image provider returned empty or non-image response payload',
            sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
            provider: providerIdentifier,
          );
        }
      }

      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

      analytics?.logMessage(
        StudioLogLevel.info,
        '[HF Provider] Successfully rendered image frame (${imageBytes.lengthInBytes} bytes) in ${elapsedMs}ms for scene "${extraParameters['scene_id'] ?? 'unknown'}"',
      );

      return ImageGenerationResult(
        imageBytes: imageBytes,
        promptHash: promptHash,
        provider: 'qwen',
        costUsd: 0.0,
        generationTimeMs: elapsedMs,
      );
    } catch (e) {
      if (e is StudioFailure) rethrow;
      throw GenerationFailure(
        'Unexpected image parsing error: $e',
        sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
        provider: providerIdentifier,
        details: e.toString(),
      );
    }
  }

  Future<Uint8List> _generateWithPollinationsFallback({
    required String cleanPrompt,
    int width = 1024,
    int height = 576,
    int? seed,
  }) async {
    return await _pollinationsLock.synchronized(() async {
      final effectiveSeed =
          seed ?? (DateTime.now().millisecondsSinceEpoch % 1000000);
      final encodedPrompt = Uri.encodeComponent(cleanPrompt);
      final url =
          'https://image.pollinations.ai/prompt/$encodedPrompt?width=$width&height=$height&seed=$effectiveSeed&model=flux&nologo=true';

      const int maxAttempts = 3;
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          final response = await _dio.get<List<int>>(
            url,
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 90),
              headers: {
                'Accept': 'image/jpeg, image/png, image/*',
              },
            ),
          );

          if (response.statusCode == 200 &&
              response.data != null &&
              response.data!.isNotEmpty) {
            return Uint8List.fromList(response.data!);
          }
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode;
          // Handle Pollinations 402 FREE_LIMIT or 429 Too Many Requests
          if ((statusCode == 402 || statusCode == 429) && attempt < maxAttempts) {
            int waitSeconds = 15; // Safe default if regex doesn't match
            try {
              final rawData = e.response?.data;
              String bodyStr = '';
              if (rawData is List<int>) {
                bodyStr = utf8.decode(rawData, allowMalformed: true);
              } else if (rawData != null) {
                bodyStr = rawData.toString();
              }
              final match = RegExp(r'Retry after (\d+)s', caseSensitive: false)
                  .firstMatch(bodyStr);
              if (match != null) {
                waitSeconds = (int.tryParse(match.group(1)!) ?? 10) + 2;
              } else {
                waitSeconds = 46; // Full IP window reset
              }
            } catch (_) {
              waitSeconds = 20;
            }

            // Cap wait time at 48 seconds max
            waitSeconds = waitSeconds.clamp(2, 48);
            final logMsg =
                '[LanthicAnalytics] [INFO] Pollinations rate limit hit (attempt $attempt/$maxAttempts). '
                'Waiting ${waitSeconds}s for IP cooldown before automatic retry...';
            debugPrint(logMsg);
            analytics?.logMessage(StudioLogLevel.warning, logMsg);
            await Future.delayed(Duration(seconds: waitSeconds));
            continue;
          }
          rethrow;
        }
      }
      throw Exception('Pollinations synthesis exhausted all retry attempts.');
    });
  }
}
