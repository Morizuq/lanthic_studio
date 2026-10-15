import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../domain/models/image_prompt_model.dart';
import '../../domain/models/visual_direction_model.dart';

class Phase6Payload {
  const Phase6Payload({
    required this.sceneId,
    required this.prompt,
    required this.provider,
    required this.endpoint,
    required this.parameters,
    required this.promptHash,
  });

  final String sceneId;
  final String prompt;
  final String provider;
  final String endpoint;
  final Map<String, dynamic> parameters;
  final String promptHash;

  Map<String, dynamic> toMap() {
    return {
      'scene_id': sceneId,
      'prompt': prompt,
      'provider': provider,
      'endpoint': endpoint,
      'parameters': parameters,
    };
  }
}

class Phase6PayloadBuilder {
  const Phase6PayloadBuilder();

  static const String fluxEndpoint = 'https://api.bfl.ml/v1/flux-pro-1.1';
  static const String imagenEndpoint =
      'https://us-central1-aiplatform.googleapis.com/v1/projects/{project}/locations/us-central1/publishers/google/models/imagen-3.0-generate-002:predict';
  static const String sdxlEndpoint =
      'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image';
  static const String qwenHfEndpoint =
      'https://router.huggingface.co/fal-ai/models/black-forest-labs/FLUX.1-schnell';

  /// Sanitizes raw prompt inputs, unwrapping pseudo-serialized YAML maps
  /// like `{value: "...", source_components: ...}` into clean natural language text.
  static String sanitizePrompt(String rawPrompt) {
    var text = rawPrompt.trim();
    if (text.startsWith('{') && text.contains('value:')) {
      final idxStart = text.indexOf('value:') + 6;
      final idxEnd = text.indexOf(', source_components:');
      if (idxEnd > idxStart) {
        text = text.substring(idxStart, idxEnd).trim();
      } else if (text.endsWith('}')) {
        text = text.substring(idxStart, text.length - 1).trim();
      }
      if ((text.startsWith('"') && text.endsWith('"')) ||
          (text.startsWith("'") && text.endsWith("'"))) {
        text = text.substring(1, text.length - 1);
      }
    }
    return text.trim();
  }

  Phase6Payload build({
    required String sceneId,
    required String prompt,
    required String provider,
    String? negativePrompt,
    List<String> loraTags = const [],
    String aspectRatio = '16:9',
    VisualDirectionModel? visualDirection,
    Map<String, dynamic>? extraParameters,
  }) {
    final cleanPrompt = sanitizePrompt(prompt);
    final effectivePromptBuffer = StringBuffer(cleanPrompt);

    if (loraTags.isNotEmpty) {
      for (final tag in loraTags) {
        if (!effectivePromptBuffer.toString().contains(tag)) {
          effectivePromptBuffer.write(' $tag');
        }
      }
    }

    final fullPromptText = effectivePromptBuffer.toString().trim();
    final promptHash = md5
        .convert(utf8.encode(fullPromptText))
        .toString()
        .substring(0, 13);

    final normalizedProvider = provider.toLowerCase().trim();
    final String endpoint;
    final Map<String, dynamic> parameters;

    switch (normalizedProvider) {
      case 'flux':
        endpoint = fluxEndpoint;
        parameters = {
          'prompt': fullPromptText,
          'aspect_ratio': aspectRatio,
          'steps': extraParameters?['steps'] ?? 30,
          'guidance_scale': extraParameters?['guidance_scale'] ?? extraParameters?['guidance'] ?? 3.5,
          'output_format': extraParameters?['output_format'] ?? 'png',
          if (extraParameters?['seed'] != null) 'seed': extraParameters!['seed'],
          ...?extraParameters,
        };
        break;

      case 'qwen':
      case 'hf':
      case 'huggingface':
        endpoint = qwenHfEndpoint;
        parameters = {
          'prompt': fullPromptText,
          'aspect_ratio': aspectRatio,
          'steps': extraParameters?['steps'] ?? 4,
          'guidance_scale': extraParameters?['guidance_scale'] ?? extraParameters?['guidance'] ?? 3.5,
          'output_format': extraParameters?['output_format'] ?? 'png',
          if (extraParameters?['seed'] != null) 'seed': extraParameters!['seed'],
          ...?extraParameters,
        };
        break;

      case 'imagen':
        endpoint = imagenEndpoint;
        parameters = {
          'prompt': fullPromptText,
          'aspectRatio': aspectRatio,
          'sampleCount': extraParameters?['sampleCount'] ?? 1,
          if (negativePrompt != null && negativePrompt.isNotEmpty)
            'negativePrompt': negativePrompt,
          ...?extraParameters,
        };
        break;

      case 'sdxl':
      default:
        endpoint = sdxlEndpoint;
        parameters = {
          'prompt': fullPromptText,
          'text_prompts': [
            {'text': fullPromptText, 'weight': 1.0},
            if (negativePrompt != null && negativePrompt.isNotEmpty)
              {'text': negativePrompt, 'weight': -1.0},
          ],
          'aspect_ratio': aspectRatio,
          'cfg_scale': extraParameters?['cfg_scale'] ?? 7.0,
          'steps': extraParameters?['steps'] ?? 30,
          ...?extraParameters,
        };
        break;
    }

    return Phase6Payload(
      sceneId: sceneId,
      prompt: fullPromptText,
      provider: normalizedProvider,
      endpoint: endpoint,
      parameters: Map.unmodifiable(parameters),
      promptHash: promptHash,
    );
  }

  Phase6Payload buildFromScene({
    required String sceneId,
    required ImagePromptItem promptItem,
    required String provider,
    String? promptOverride,
    VisualDirectionModel? visualDirection,
    Map<String, dynamic>? extraParameters,
  }) {
    return build(
      sceneId: sceneId,
      prompt: promptOverride ?? promptItem.prompt,
      provider: provider,
      negativePrompt: promptItem.negativePrompt,
      loraTags: promptItem.loraTags,
      aspectRatio: promptItem.aspectRatio,
      visualDirection: visualDirection,
      extraParameters: extraParameters,
    );
  }
}
