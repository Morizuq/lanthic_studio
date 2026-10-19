import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/domain/models/studio_models.dart';

void main() {
  group('Comic Lettering & BubbleType Model Tests', () {
    test('parses BubbleType correctly including soundFx / sfx aliases', () {
      expect(BubbleType.fromString('speech'), BubbleType.speech);
      expect(BubbleType.fromString('thought'), BubbleType.thought);
      expect(BubbleType.fromString('caption'), BubbleType.caption);
      expect(BubbleType.fromString('sound_fx'), BubbleType.soundFx);
      expect(BubbleType.fromString('sfx'), BubbleType.soundFx);
      expect(BubbleType.fromString('SOUNDFX'), BubbleType.soundFx);
      expect(BubbleType.fromString('unknown_type'), BubbleType.speech);
    });

    test('serializes and deserializes DialogueBubble with soundFx', () {
      const bubble = DialogueBubble(
        bubbleId: 'sfx_001',
        sceneId: 'sc_001',
        type: BubbleType.soundFx,
        text: 'CLASH',
        x: 0.15,
        y: 0.75,
        tailTargetX: 0.5,
        tailTargetY: 0.8,
      );

      final map = bubble.toMap();
      expect(map['bubble_id'], 'sfx_001');
      expect(map['type'], 'sound_fx');
      expect(map['text'], 'CLASH');
      expect(map['x'], 0.15);
      expect(map['y'], 0.75);

      final parsed = DialogueBubble.fromMap(map);
      expect(parsed.bubbleId, 'sfx_001');
      expect(parsed.type, BubbleType.soundFx);
      expect(parsed.text, 'CLASH');
      expect(parsed.x, 0.15);
      expect(parsed.y, 0.75);
    });

    test('StudioLetteringModel filters bubbles by sceneId correctly', () {
      const model = StudioLetteringModel(
        schemaVersion: '1.0.0',
        bubbles: [
          DialogueBubble(
            bubbleId: 'b1',
            sceneId: 'sc_001',
            type: BubbleType.speech,
            text: 'Hello',
            x: 0.1,
            y: 0.1,
          ),
          DialogueBubble(
            bubbleId: 'b2',
            sceneId: 'sc_002',
            type: BubbleType.soundFx,
            text: 'CLASH',
            x: 0.2,
            y: 0.8,
          ),
        ],
      );

      final sc1Bubbles = model.forScene('sc_001');
      expect(sc1Bubbles.length, 1);
      expect(sc1Bubbles.first.text, 'Hello');

      final sc2Bubbles = model.forScene('sc_002');
      expect(sc2Bubbles.length, 1);
      expect(sc2Bubbles.first.text, 'CLASH');
      expect(sc2Bubbles.first.type, BubbleType.soundFx);
    });
  });
}
