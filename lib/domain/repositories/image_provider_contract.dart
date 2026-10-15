import 'dart:typed_data';

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
}
