import 'package:meta/meta.dart';

@immutable
class VisualDirectionModel {
  const VisualDirectionModel({
    this.style = '',
    this.colorPalette = const [],
    this.lighting = '',
    this.cameraComposition = '',
    this.sceneOverrides = const {},
  });

  final String style;
  final List<String> colorPalette;
  final String lighting;
  final String cameraComposition;
  final Map<String, Map<String, String>> sceneOverrides;

  factory VisualDirectionModel.fromMap(Map<String, dynamic> map) {
    final globalDir = map['global_direction'] is Map ? map['global_direction'] as Map : null;
    final globalCtx = map['global_visual_context'] is Map ? map['global_visual_context'] as Map : null;

    final rawPalette = map['color_palette'] ?? globalDir?['color_palette'];
    final palette = <String>[];
    if (rawPalette is Iterable) {
      for (final color in rawPalette) {
        palette.add(color.toString());
      }
    }

    final rawOverrides = map['scene_overrides'];
    final overrides = <String, Map<String, String>>{};
    if (rawOverrides is Map) {
      for (final entry in rawOverrides.entries) {
        if (entry.value is Map) {
          final inner = <String, String>{};
          for (final innerEntry in (entry.value as Map).entries) {
            inner[innerEntry.key.toString()] = innerEntry.value.toString();
          }
          overrides[entry.key.toString()] = Map.unmodifiable(inner);
        }
      }
    }

    final rawScenes = map['scenes'];
    if (rawScenes is Iterable) {
      for (final item in rawScenes) {
        if (item is Map) {
          final sId = item['scene_id']?.toString();
          if (sId != null && sId.isNotEmpty) {
            final inner = overrides.containsKey(sId)
                ? Map<String, String>.from(overrides[sId]!)
                : <String, String>{};
            for (final entry in item.entries) {
              final key = entry.key.toString();
              if (key == 'scene_id') continue;
              if (entry.value is Map) {
                final mapVal = entry.value as Map;
                inner[key] = (mapVal['value'] ?? mapVal['entity'] ?? mapVal.toString()).toString();
              } else {
                inner[key] = entry.value.toString();
              }
            }
            overrides[sId] = Map.unmodifiable(inner);
          }
        }
      }
    }

    final style = (map['style'] ?? globalDir?['art_style'] ?? globalCtx?['cultural_context'] ?? '').toString();
    final lighting = (map['lighting'] ?? globalDir?['lighting_philosophy'] ?? '').toString();
    final camera = (map['camera_composition'] ?? globalDir?['camera_philosophy'] ?? '').toString();

    return VisualDirectionModel(
      style: style,
      colorPalette: List.unmodifiable(palette),
      lighting: lighting,
      cameraComposition: camera,
      sceneOverrides: Map.unmodifiable(overrides),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'style': style,
      'color_palette': colorPalette,
      'lighting': lighting,
      'camera_composition': cameraComposition,
      if (sceneOverrides.isNotEmpty) 'scene_overrides': sceneOverrides,
    };
  }
}
