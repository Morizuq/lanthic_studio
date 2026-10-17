import 'dart:typed_data';
import '../models/synthesis_request.dart';

class ImageGenerationResult {
  const ImageGenerationResult({
    required this.imageBytes,
    required this.promptHash,
    required this.provider,
    this.costUsd = 0.0,
    this.generationTimeMs = 0,
  });

  final Uint8List imageBytes;
  final String promptHash;
  final String provider;
  final double costUsd;
  final int generationTimeMs;
}

abstract class ImageProviderContract {
  String get providerIdentifier;
  String get displayName => providerIdentifier.toUpperCase();
  bool get isFreeOpenSource => false;
  String get description => '';

  Future<ImageGenerationResult> generate({
    required String prompt,
    required String apiKey,
    Map<String, dynamic> extraParameters = const {},
  });

  /// Adapts a canonical [SynthesisRequest] into provider-specific payloads.
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
        'loras': request.extractedLoras.map((l) => {'name': l.name, 'weight': l.weight}).toList(),
        if (request.negativePrompt != null) 'negative_prompt': request.negativePrompt,
        ...extraParameters,
      },
    );
  }
}
