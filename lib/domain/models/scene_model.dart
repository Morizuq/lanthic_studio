import 'package:meta/meta.dart';

@immutable
class DialogueLine {
  const DialogueLine({
    required this.speaker,
    required this.text,
  });

  final String speaker;
  final String text;

  factory DialogueLine.fromMap(Map<String, dynamic> map) {
    return DialogueLine(
      speaker: (map['speaker'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'speaker': speaker,
      'text': text,
    };
  }
}

@immutable
class SceneModel {
  const SceneModel({
    required this.sceneId,
    required this.sequence,
    this.slug = '',
    this.title = '',
    this.description = '',
    this.setting = '',
    this.characters = const [],
    this.dialogue = const [],
  });

  final String sceneId;
  final int sequence;
  final String slug;
  final String title;
  final String description;
  final String setting;
  final List<String> characters;
  final List<DialogueLine> dialogue;

  factory SceneModel.fromMap(Map<String, dynamic> map, [int fallbackSequence = 1]) {
    final rawCharacters = map['characters'] ?? map['entities'];
    final charList = <String>[];
    if (rawCharacters is Iterable) {
      for (final char in rawCharacters) {
        if (char is Map) {
          final id = char['id'] ?? char['name'];
          if (id != null) charList.add(id.toString());
        } else {
          charList.add(char.toString());
        }
      }
    }

    final rawDialogue = map['dialogue'];
    final dialogueList = <DialogueLine>[];
    if (rawDialogue is Iterable) {
      for (final line in rawDialogue) {
        if (line is Map) {
          dialogueList.add(DialogueLine.fromMap(Map<String, dynamic>.from(line)));
        }
      }
    }

    String description = '';
    final rawEvent = map['event'];
    if (rawEvent is Map && rawEvent['value'] != null) {
      description = rawEvent['value'].toString();
    } else if (rawEvent is String) {
      description = rawEvent;
    } else if (map['description'] != null) {
      description = map['description'].toString();
    }

    String setting = '';
    final rawLocation = map['location'];
    if (rawLocation is Map) {
      setting = (rawLocation['name'] ?? rawLocation['entity'] ?? '').toString();
    } else if (map['setting'] != null) {
      setting = map['setting'].toString();
    }

    final sceneId = (map['scene_id'] ?? map['id'] ?? '').toString();
    final title = (map['title'] ?? map['stage'] ?? map['slug'] ?? sceneId).toString();
    final slug = (map['slug'] ?? map['purpose'] ?? sceneId).toString();
    final sequence = (map['sequence'] as num?)?.toInt() ?? fallbackSequence;

    return SceneModel(
      sceneId: sceneId,
      sequence: sequence,
      slug: slug,
      title: title,
      description: description,
      setting: setting,
      characters: List.unmodifiable(charList),
      dialogue: List.unmodifiable(dialogueList),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scene_id': sceneId,
      'sequence': sequence,
      'slug': slug,
      'title': title,
      'description': description,
      'setting': setting,
      'characters': characters,
      'dialogue': dialogue.map((d) => d.toMap()).toList(),
    };
  }
}
