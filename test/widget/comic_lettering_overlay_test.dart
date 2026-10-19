import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/domain/models/studio_models.dart';
import 'package:lanthic_studio/features/project/widgets/comic_lettering_overlay.dart';

void main() {
  group('ComicLetteringOverlay Widget Tests', () {
    testWidgets('renders speech balloon with speaker attribution and tail',
        (WidgetTester tester) async {
      const bubbles = [
        DialogueBubble(
          bubbleId: 'bub_1',
          sceneId: 'sc_001',
          type: BubbleType.speech,
          speaker: 'Captain Vane',
          text: 'Confirm bearing. That signal is hostile.',
          x: 0.15,
          y: 0.20,
          tailTargetX: 0.40,
          tailTargetY: 0.50,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: ComicLetteringOverlay(
                  bubbles: bubbles,
                  canvasSize: Size(800, 600),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CAPTAIN VANE'), findsOneWidget);
      expect(find.text('Confirm bearing. That signal is hostile.'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders dynamic sound FX onomatopoeia banner (CLASH)',
        (WidgetTester tester) async {
      const bubbles = [
        DialogueBubble(
          bubbleId: 'sfx_1',
          sceneId: 'sc_001',
          type: BubbleType.soundFx,
          text: 'CLASH',
          x: 0.10,
          y: 0.70,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 800,
                child: ComicLetteringOverlay(
                  bubbles: bubbles,
                  canvasSize: Size(400, 800),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CLASH'), findsOneWidget);
      // Verify rotated transform is applied
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('renders caption and thought bubbles cleanly',
        (WidgetTester tester) async {
      const bubbles = [
        DialogueBubble(
          bubbleId: 'cap_1',
          sceneId: 'sc_001',
          type: BubbleType.caption,
          text: 'Deep within the uncharted nebula...',
          x: 0.05,
          y: 0.05,
        ),
        DialogueBubble(
          bubbleId: 'th_1',
          sceneId: 'sc_001',
          type: BubbleType.thought,
          speaker: 'Navigator',
          text: 'We may not survive this jump.',
          x: 0.50,
          y: 0.30,
          tailTargetX: 0.70,
          tailTargetY: 0.60,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: ComicLetteringOverlay(
                  bubbles: bubbles,
                  canvasSize: Size(800, 600),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deep within the uncharted nebula...'), findsOneWidget);
      expect(find.text('NAVIGATOR (THINKING)'), findsOneWidget);
      expect(find.text('We may not survive this jump.'), findsOneWidget);
    });
  });
}
