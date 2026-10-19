import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lanthic_studio/domain/models/studio_models.dart';

/// Renders comic speech balloons, thought clouds, narration captions,
/// and dynamic onomatopoeia action sound-effect banners (e.g. "CLASH")
/// accurately over a scene canvas using normalized (0.0 to 1.0) coordinates.
class ComicLetteringOverlay extends StatelessWidget {
  const ComicLetteringOverlay({
    super.key,
    required this.bubbles,
    required this.canvasSize,
  });

  final List<DialogueBubble> bubbles;
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    if (bubbles.isEmpty || canvasSize.width <= 0 || canvasSize.height <= 0) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Vector Tail Layer for Speech & Thought Balloons
        CustomPaint(
          size: canvasSize,
          painter: _ComicBalloonTailsPainter(
            bubbles: bubbles,
            canvasSize: canvasSize,
          ),
        ),

        // 2. Lettering Bubble Cards & SFX Badges
        ...bubbles.map((bubble) {
          final maxBubbleWidth = math.min(canvasSize.width * 0.45, 280.0).clamp(140.0, 360.0);
          final rawLeft = bubble.x * canvasSize.width;
          final rawTop = bubble.y * canvasSize.height;

          // Clamp within canvas bounds with safe padding
          final clampedLeft = rawLeft.clamp(12.0, math.max(12.0, canvasSize.width - maxBubbleWidth - 12.0)).toDouble();
          final clampedTop = rawTop.clamp(12.0, math.max(12.0, canvasSize.height - 80.0)).toDouble();

          return Positioned(
            left: clampedLeft,
            top: clampedTop,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: _buildBubbleContent(bubble),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBubbleContent(DialogueBubble bubble) {
    switch (bubble.type) {
      case BubbleType.soundFx:
        return _buildSfxBadge(bubble.text);
      case BubbleType.caption:
        return _buildCaptionBox(bubble.text);
      case BubbleType.thought:
        return _buildThoughtBubble(bubble.text, bubble.speaker);
      case BubbleType.speech:
        return _buildSpeechBalloon(bubble.text, bubble.speaker);
    }
  }

  /// Dynamic action onomatopoeia sound-effect banner (like the "CLASH" badge)
  Widget _buildSfxBadge(String text) {
    return Transform.rotate(
      angle: -0.07,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE68A), // Comic parchment amber
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF0F172A), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0F172A),
              offset: Offset(3.5, 3.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF991B1B), // Dark comic crimson
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  /// Classic comic speech balloon
  Widget _buildSpeechBalloon(String text, String speaker) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F172A), width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(2, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (speaker.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                speaker.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF4338CA),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  /// Classic narrator caption box
  Widget _buildCaptionBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF08A),
        border: Border.all(color: const Color(0xFF0F172A), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A000000),
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          height: 1.2,
        ),
      ),
    );
  }

  /// Thought balloon with cloud styling
  Widget _buildThoughtBubble(String text, String speaker) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF475569), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(2, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (speaker.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '$speaker (thinking)'.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vector painter that renders pointer tails connecting balloons toward their target characters.
class _ComicBalloonTailsPainter extends CustomPainter {
  const _ComicBalloonTailsPainter({
    required this.bubbles,
    required this.canvasSize,
  });

  final List<DialogueBubble> bubbles;
  final Size canvasSize;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final bubble in bubbles) {
      if (bubble.type != BubbleType.speech && bubble.type != BubbleType.thought) {
        continue;
      }

      // Check if a valid target is configured
      if (bubble.tailTargetX <= 0.0 && bubble.tailTargetY <= 0.0) {
        continue;
      }

      final startX = (bubble.x * size.width + 30.0).clamp(16.0, size.width - 16.0).toDouble();
      final startY = (bubble.y * size.height + 40.0).clamp(16.0, size.height - 16.0).toDouble();

      final targetX = (bubble.tailTargetX * size.width).clamp(10.0, size.width - 10.0).toDouble();
      final targetY = (bubble.tailTargetY * size.height).clamp(10.0, size.height - 10.0).toDouble();

      if (bubble.type == BubbleType.speech) {
        // Draw triangular comic pointer tail
        final dx = targetX - startX;
        final dy = targetY - startY;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance > 24.0) {
          final normalX = -dy / distance;
          final normalY = dx / distance;
          const baseHalfWidth = 7.0;

          final p1 = Offset(startX + normalX * baseHalfWidth, startY + normalY * baseHalfWidth);
          final p2 = Offset(startX - normalX * baseHalfWidth, startY - normalY * baseHalfWidth);
          final tip = Offset(
            startX + (dx * 0.75).clamp(-distance, distance).toDouble(),
            startY + (dy * 0.75).clamp(-distance, distance).toDouble(),
          );

          final tailPath = Path()
            ..moveTo(p1.dx, p1.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(p2.dx, p2.dy)
            ..close();

          canvas.drawPath(tailPath, fillPaint);
          canvas.drawPath(tailPath, strokePaint);
        }
      } else if (bubble.type == BubbleType.thought) {
        // Draw trailing thought circles
        final dx = targetX - startX;
        final dy = targetY - startY;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance > 20.0) {
          final t1 = Offset(startX + dx * 0.35, startY + dy * 0.35);
          final t2 = Offset(startX + dx * 0.65, startY + dy * 0.65);

          canvas.drawCircle(t1, 6.0, fillPaint);
          canvas.drawCircle(t1, 6.0, strokePaint);

          canvas.drawCircle(t2, 3.5, fillPaint);
          canvas.drawCircle(t2, 3.5, strokePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ComicBalloonTailsPainter oldDelegate) {
    return oldDelegate.bubbles != bubbles || oldDelegate.canvasSize != canvasSize;
  }
}
