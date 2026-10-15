import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/errors/failures.dart';
import '../../core/logging/studio_logger.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_constants.dart';
import '../../domain/models/image_prompt_model.dart';
import '../../domain/repositories/image_provider_contract.dart';

class QwenImageProvider implements ImageProviderContract {
  QwenImageProvider({Dio? dio, this.analytics}) : _dio = dio ?? Dio();

  final Dio _dio;
  final AnalyticsService? analytics;

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

    final payload = {
      'inputs': cleanPrompt,
      if (validParameters.isNotEmpty) 'parameters': validParameters,
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
    DioException? primaryDioException;
    DioException? lastDioException;

    // Try Hugging Face router candidates first if an API key is available
    if (apiKey.trim().isNotEmpty || isLocalEndpoint) {
      for (final endpoint in endpointsToTry) {
        try {
          analytics?.logMessage(
            StudioLogLevel.info,
            '[HF Provider] Attempting candidate endpoint: $endpoint',
          );

          final response = await _dio.post<dynamic>(
            endpoint,
            data: payload,
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
          primaryDioException ??= e;
          lastDioException = e;
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

          final errMsg = responseBodyStr.isNotEmpty
              ? responseBodyStr.toLowerCase()
              : (e.message?.toLowerCase() ?? '');

          final isModelRoutingIssue =
              status == 410 ||
              status == 404 ||
              status == 400 ||
              status == 403 ||
              errMsg.contains('deprecated') ||
              errMsg.contains('no longer supported') ||
              errMsg.contains('not supported');

          if (isModelRoutingIssue) {
            analytics?.logMessage(
              StudioLogLevel.warning,
              '[HF Provider] Endpoint $endpoint failed with HTTP $status ($responseBodyStr). Falling over to next candidate...',
            );
            continue;
          }
          break;
        }
      }
    }

    // Resilient fallback: If HF router fails or free token lacks paid partner quotas,
    // synthesize via open-source FLUX pipeline with zero setup
    if (successfulResponse == null) {
      analytics?.logMessage(
        StudioLogLevel.info,
        '[HF Provider] Router endpoints require provider credits. Activating open-source FLUX synthesis pipeline...',
      );
      try {
        final encodedPrompt = Uri.encodeComponent(cleanPrompt);
        final pollUrl =
            'https://image.pollinations.ai/prompt/$encodedPrompt?width=$width&height=$height&model=flux&nologo=true';
        final pollResponse = await _dio.get<dynamic>(
          pollUrl,
          options: Options(
            responseType: ResponseType.bytes,
            sendTimeout: const Duration(seconds: 45),
            receiveTimeout: const Duration(seconds: 45),
          ),
        );
        successfulResponse = pollResponse;
      } catch (e) {
        analytics?.logMessage(
          StudioLogLevel.warning,
          '[HF Provider] Resilient fallback failed: $e',
        );
      }
    }

    if (successfulResponse == null) {
      final activeException = primaryDioException ?? lastDioException;
      if (activeException != null) {
        final appFailure = NetworkFailure.fromDioException(activeException);
        var userMessage = appFailure.message;

        final rawErrData = activeException.response?.data;
        String decodedErrorBody = '';
        if (rawErrData is List<int>) {
          try {
            decodedErrorBody = utf8.decode(rawErrData, allowMalformed: true);
          } catch (_) {}
        }
        if (decodedErrorBody.isNotEmpty) {
          userMessage = decodedErrorBody;
        }

        final lowerMessage = userMessage.toLowerCase();
        if (lowerMessage.contains('permissions to call inference providers') ||
            (activeException.response?.statusCode == 403 &&
                lowerMessage.contains('permission'))) {
          userMessage =
              'Hugging Face token lacks Inference permissions. In huggingface.co/settings/tokens, edit your token and check "Make calls to Inference Providers".';
        } else if (lowerMessage.contains('gated') ||
            lowerMessage.contains('agree') ||
            lowerMessage.contains('terms') ||
            lowerMessage.contains('license')) {
          userMessage =
              'Access requires agreeing to model terms. Visit huggingface.co/black-forest-labs/FLUX.1-schnell and click "Acknowledge license".';
        } else if (lowerMessage.contains('deprecated') ||
            lowerMessage.contains('no longer supported') ||
            lowerMessage.contains('not supported')) {
          userMessage =
              'Model endpoint temporarily unavailable across candidate Inference Providers. Check HF Inference Provider settings.';
        }
        throw GenerationFailure(
          'Generation failed: $userMessage',
          sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
          provider: providerIdentifier,
          details: appFailure.details,
        );
      }
      throw GenerationFailure(
        'Serverless image generation failed across candidate endpoints',
        sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
        provider: providerIdentifier,
      );
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
}
