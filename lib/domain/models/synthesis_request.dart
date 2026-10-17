enum ModelArch { flux, sdxl }

enum StudioAspectRatio {
  widescreen16x9('16:9'),
  square1x1('1:1'),
  portrait9x16('9:16'),
  cinema21x9('21:9');

  final String label;
  const StudioAspectRatio(this.label);

  /// Deterministic dimensions divisible by 16/64 for Diffusers & ComfyUI
  ({int width, int height}) toDimensions(ModelArch arch) {
    return switch (this) {
      StudioAspectRatio.widescreen16x9 => (width: 1024, height: 576),
      StudioAspectRatio.square1x1 => (width: 1024, height: 1024),
      StudioAspectRatio.portrait9x16 => (width: 576, height: 1024),
      StudioAspectRatio.cinema21x9 => (width: 1152, height: 512),
    };
  }
}

class LoraTag {
  final String name;
  final double weight;
  const LoraTag({required this.name, required this.weight});
}

class SynthesisRequest {
  final String sceneId;
  final String cleanPrompt;
  final String? negativePrompt;
  final List<LoraTag> extractedLoras;
  final StudioAspectRatio aspectRatio;
  final int seed;

  const SynthesisRequest({
    required this.sceneId,
    required this.cleanPrompt,
    this.negativePrompt,
    this.extractedLoras = const [],
    this.aspectRatio = StudioAspectRatio.widescreen16x9,
    required this.seed,
  });

  /// Factory that unwraps nested YAML maps and extracts <lora:name:weight> tags
  factory SynthesisRequest.fromRawYaml({
    required String sceneId,
    required dynamic rawPromptField,
    String? rawAspectRatio,
    int? seed,
  }) {
    // 1. Unwrap nested {value: "..."} maps if present
    String rawString = '';
    if (rawPromptField is String) {
      rawString = rawPromptField;
    } else if (rawPromptField is Map && rawPromptField.containsKey('value')) {
      rawString = rawPromptField['value'].toString();
    } else {
      rawString = rawPromptField.toString();
    }

    // 2. Extract <lora:model_name:0.8> tags into structured metadata
    final loraRegex = RegExp(r'<lora:([^:>]+):([0-9.]+)>');
    final loras = <LoraTag>[];
    for (final match in loraRegex.allMatches(rawString)) {
      loras.add(
        LoraTag(
          name: match.group(1)!,
          weight: double.tryParse(match.group(2)!) ?? 1.0,
        ),
      );
    }

    // 3. Clean prompt for standard REST endpoints
    final cleaned = rawString
        .replaceAll(loraRegex, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final ratio = StudioAspectRatio.values.firstWhere(
      (e) => e.label == rawAspectRatio,
      orElse: () => StudioAspectRatio.widescreen16x9,
    );

    return SynthesisRequest(
      sceneId: sceneId,
      cleanPrompt: cleaned,
      extractedLoras: loras,
      aspectRatio: ratio,
      seed: seed ?? (DateTime.now().millisecondsSinceEpoch % 1000000000),
    );
  }
}
