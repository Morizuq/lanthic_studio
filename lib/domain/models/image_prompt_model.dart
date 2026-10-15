import 'package:meta/meta.dart';

@immutable
class ImagePromptItem {
  const ImagePromptItem({
    required this.sceneId,
    required this.prompt,
    this.negativePrompt = '',
    this.loraTags = const [],
    this.aspectRatio = '16:9',
  });

  final String sceneId;
  final String prompt;
  final String negativePrompt;
  final List<String> loraTags;
  final String aspectRatio;

  factory ImagePromptItem.fromMap(Map<String, dynamic> map) {
    final rawLoras = map['lora_tags'];
    final loras = <String>[];
    if (rawLoras is Iterable) {
      for (final tag in rawLoras) {
        loras.add(tag.toString());
      }
    }

    String promptText = '';
    final descriptivePrompt = map['descriptive_prompt'];
    if (descriptivePrompt is Map && descriptivePrompt['compiled_prompt'] != null) {
      promptText = descriptivePrompt['compiled_prompt'].toString();
    } else if (map['prompt'] is Map) {
      final pMap = map['prompt'] as Map;
      promptText = (pMap['value'] ?? pMap['compiled_prompt'] ?? pMap['text'] ?? '').toString();
    } else if (map['prompt'] != null) {
      promptText = map['prompt'].toString();
    }
    promptText = sanitizePrompt(promptText);

    String negativePromptText = '';
    final negativeConstraints = map['negative_constraints'];
    if (negativeConstraints is Iterable && negativeConstraints.isNotEmpty) {
      final parts = <String>[];
      for (final c in negativeConstraints) {
        if (c is Map && c['value'] != null) {
          parts.add(c['value'].toString());
        } else if (c is String) {
          parts.add(c);
        }
      }
      negativePromptText = parts.join(', ');
    } else if (map['negative_prompt'] != null) {
      negativePromptText = map['negative_prompt'].toString();
    }

    return ImagePromptItem(
      sceneId: (map['scene_id'] ?? '').toString(),
      prompt: promptText,
      negativePrompt: negativePromptText,
      loraTags: List.unmodifiable(loras),
      aspectRatio: (map['aspect_ratio'] ?? '16:9').toString(),
    );
  }

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

  Map<String, dynamic> toMap() {
    return {
      'scene_id': sceneId,
      'prompt': prompt,
      'negative_prompt': negativePrompt,
      'lora_tags': loraTags,
      'aspect_ratio': aspectRatio,
    };
  }

  ImagePromptItem copyWith({
    String? prompt,
    String? negativePrompt,
    List<String>? loraTags,
    String? aspectRatio,
  }) {
    return ImagePromptItem(
      sceneId: sceneId,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      loraTags: loraTags ?? this.loraTags,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }
}

@immutable
class ImagePromptsModel {
  const ImagePromptsModel({
    this.prompts = const [],
  });

  final List<ImagePromptItem> prompts;

  factory ImagePromptsModel.fromMap(Map<String, dynamic> map) {
    final rawList = map['scenes'] ?? map['prompts'];
    final items = <ImagePromptItem>[];
    if (rawList is Iterable) {
      for (final item in rawList) {
        if (item is Map) {
          items.add(ImagePromptItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return ImagePromptsModel(prompts: List.unmodifiable(items));
  }

  Map<String, dynamic> toMap() {
    return {
      'prompts': prompts.map((p) => p.toMap()).toList(),
    };
  }
}
