import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../core/network/app_failure.dart';
import '../../core/network/network_constants.dart';
import '../../domain/repositories/image_provider_contract.dart';

class FluxImageProvider implements ImageProviderContract {
  FluxImageProvider({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

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
  Future<ImageGenerationResult> generate({
    required String prompt,
    required String apiKey,
    Map<String, dynamic> extraParameters = const {},
  }) async {
    final startTime = DateTime.now();
    final promptHash = md5.convert(utf8.encode(prompt)).toString().substring(0, 13);

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
            NetworkConstants.contentTypeHeaderKey: NetworkConstants.jsonContentType,
          },
        ),
      );

      final dynamic responseData = response.data;
      Uint8List imageBytes;

      if (responseData is Map<String, dynamic>) {
        final sampleUrl = responseData['result']?['sample'] ?? responseData['sample'];
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
    } on DioException catch (e, stack) {
      final failure = NetworkFailure.fromDioException(e);
      throw GenerationFailure(
        'FLUX generation failed: ${failure.message}',
        sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
        provider: providerIdentifier,
        details: failure.details,
        cause: stack,
      );
    } catch (e, stack) {
      if (e is StudioFailure) rethrow;
      throw GenerationFailure(
        'FLUX unexpected error: $e',
        sceneId: extraParameters['scene_id']?.toString() ?? 'unknown',
        provider: providerIdentifier,
        details: e.toString(),
        cause: stack,
      );
    }
  }
}
