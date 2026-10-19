import 'dart:typed_data';
import '../models/synthesis_request.dart';

/// Represents the raw binary and accounting output of an AI image synthesis execution.
///
/// Encapsulates the generated [imageBytes] (PNG or JPEG), cryptographic [promptHash],
/// identifier of the servicing [provider], estimated API [costUsd], and end-to-end
/// latency [generationTimeMs].
class ImageGenerationResult {
  /// Constructs an [ImageGenerationResult].
  const ImageGenerationResult({
    required this.imageBytes,
    required this.promptHash,
    required this.provider,
    this.costUsd = 0.0,
    this.generationTimeMs = 0,
  });

  /// Binary bytes of the synthesized image.
  final Uint8List imageBytes;

  /// SHA-256 or truncated hash of the prompt used to verify cache validity.
  final String promptHash;

  /// Identifier slug of the provider that rendered the image (e.g. `'flux'`, `'qwen'`).
  final String provider;

  /// Estimated financial cost incurred for this synthesis call in US Dollars.
  final double costUsd;

  /// End-to-end execution time in milliseconds from HTTP dispatch to response decoding.
  final int generationTimeMs;
}

/// Abstract contract governing visual generative AI providers in Lanthic Studio.
///
/// Implementations adapt high-level narrative scene prompts and camera directives
/// into concrete HTTP REST requests against services such as Hugging Face Router,
/// Fal.ai, Replicate, Pollinations, or local Ollama/ComfyUI instances.
abstract class ImageProviderContract {
  /// Unique machine-readable identifier for this provider (e.g. `'qwen'`, `'flux'`, `'sdxl'`).
  String get providerIdentifier;

  /// Human-readable brand name displayed in studio UI dropdowns.
  String get displayName => providerIdentifier.toUpperCase();

  /// Whether this provider offers zero-auth, free-tier community inference without API keys.
  bool get isFreeOpenSource => false;

  /// Editorial summary of the provider's strengths, target style, and pricing model.
  String get description => '';

  /// Dispatches a raw text prompt and authentication key to the underlying vision model.
  ///
  /// * [prompt]: Sanitized positive narrative prompt describing the scene.
  /// * [apiKey]: User-provided secret credential (or empty string if [isFreeOpenSource] is true).
  /// * [extraParameters]: Optional provider-specific overrides (width, height, steps, seed).
  ///
  /// Returns an [ImageGenerationResult] holding the resulting image bytes and metrics.
  Future<ImageGenerationResult> generate({
    required String prompt,
    required String apiKey,
    Map<String, dynamic> extraParameters = const {},
  });

  /// High-level adapter that unpacks a structured [SynthesisRequest] into provider parameters.
  ///
  /// Extracts clean prompts, LoRA weights, aspect ratios, seeds, and negative prompts,
  /// routing them to [generate].
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

