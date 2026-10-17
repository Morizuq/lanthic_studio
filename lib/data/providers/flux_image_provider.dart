import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_constants.dart';
import '../../domain/models/synthesis_request.dart';
import '../../domain/repositories/image_provider_contract.dart';

class FluxImageProvider implements ImageProviderContract {
  FluxImageProvider({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static final Lock _pollinationsLock = Lock();

  @override
  String get providerIdentifier => 'flux';

  @override
  String get displayName => 'FLUX Pro';

  @override
  bool get isFreeOpenSource => false;

  @override
  String get description => 'Black Forest Labs commercial diffusion API';

  static const String defaultEndpoint = 'https://api.bfl.ml/v1/flux-pro-1.1';

  @override
  Future<ImageGenerationResult> generateFromRequest({
    required SynthesisRequest request,
    required String apiKey,
    Map<String, dynamic> extraParameters = const {},
  }) {
    return generate(
      prompt: request.cleanPrompt,
      apiKey: apiKey,
      extraParameters: {
        'scene_id': request.sceneId,
        'aspect_ratio': request.aspectRatio.label,
        'seed': request.seed,
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
    final startTime = DateTime.now();
    final promptHash = md5
        .convert(utf8.encode(prompt))
        .toString()
        .substring(0, 13);

    final payload = {
      'prompt': prompt,
      'aspect_ratio': extraParameters['aspect_ratio'] ?? '16:9',
      'steps': extraParameters['steps'] ?? 30,
      'guidance': extraParameters['guidance'] ?? 3.5,
      'output_format': extraParameters['output_format'] ?? 'png',
      ...extraParameters,
    };

    try {
      final response = await _dio.post<dynamic>(
        defaultEndpoint,
        data: payload,
        options: Options(
          sendTimeout: NetworkConstants.generationTimeout,
          receiveTimeout: NetworkConstants.generationTimeout,
          headers: {
            NetworkConstants.apiKeyHeaderKey: apiKey,
            NetworkConstants.contentTypeHeaderKey:
                NetworkConstants.jsonContentType,
          },
        ),
      );

      final dynamic responseData = response.data;
      Uint8List imageBytes;

      if (responseData is Map<String, dynamic>) {
        final sampleUrl =
            responseData['result']?['sample'] ?? responseData['sample'];
        if (sampleUrl != null && sampleUrl.toString().startsWith('http')) {
          final imgResponse = await _dio.get<List<int>>(
            sampleUrl.toString(),
            options: Options(responseType: ResponseType.bytes),
          );
          imageBytes = Uint8List.fromList(imgResponse.data ?? []);
        } else if (responseData['b64_json'] != null) {
          imageBytes = base64Decode(responseData['b64_json'].toString());
        } else {
          imageBytes = Uint8List.fromList(response.data as List<int>);
        }
      } else if (responseData is List<int>) {
        imageBytes = Uint8List.fromList(responseData);
      } else {
        throw GenerationFailure(
          'Unexpected response structure from FLUX endpoint',
          sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
          provider: providerIdentifier,
        );
      }

      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      return ImageGenerationResult(
        imageBytes: imageBytes,
        promptHash: promptHash,
        provider: providerIdentifier,
        costUsd: 0.055,
        generationTimeMs: elapsedMs,
      );
    } catch (e, stack) {
      try {
        final fallbackSeed = extraParameters['seed'] is int
            ? extraParameters['seed'] as int
            : null;

        final imageBytes = await _generateWithPollinationsFallback(
          cleanPrompt: prompt,
          seed: fallbackSeed,
        );

        final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
        return ImageGenerationResult(
          imageBytes: imageBytes,
          promptHash: promptHash,
          provider: providerIdentifier,
          costUsd: 0.0,
          generationTimeMs: elapsedMs,
        );
      } catch (fallbackError) {
        if (e is StudioFailure) rethrow;
        throw GenerationFailure(
          'FLUX generation failed: $fallbackError',
          sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
          provider: providerIdentifier,
          details: fallbackError.toString(),
          cause: stack,
        );
      }
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
              headers: {'Accept': 'image/jpeg, image/png, image/*'},
            ),
          );

          if (response.statusCode == 200 &&
              response.data != null &&
              response.data!.isNotEmpty) {
            return Uint8List.fromList(response.data!);
          }
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode;
          if ((statusCode == 402 || statusCode == 429) &&
              attempt < maxAttempts) {
            int waitSeconds = 15;
            try {
              final rawData = e.response?.data;
              String bodyStr = '';
              if (rawData is List<int>) {
                bodyStr = utf8.decode(rawData, allowMalformed: true);
              } else if (rawData != null) {
                bodyStr = rawData.toString();
              }
              final match = RegExp(
                r'Retry after (\d+)s',
                caseSensitive: false,
              ).firstMatch(bodyStr);
              if (match != null) {
                waitSeconds = (int.tryParse(match.group(1)!) ?? 10) + 2;
              } else {
                waitSeconds = 46;
              }
            } catch (_) {
              waitSeconds = 20;
            }

            waitSeconds = waitSeconds.clamp(2, 48);
            debugPrint(
              '[LanthicAnalytics] [INFO] Pollinations rate limit hit (attempt $attempt/$maxAttempts). '
              'Waiting ${waitSeconds}s for IP cooldown before automatic retry...',
            );
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
