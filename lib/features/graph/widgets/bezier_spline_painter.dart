import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/studio_graph_models.dart';

class BezierSplinePainter extends CustomPainter {
  BezierSplinePainter({
    required this.cables,
    required this.nodes,
    this.selectedNodeId,
    this.nodeWidth = 280.0,
    this.nodeHeight = 220.0,
  });

  final List<StudioGraphCable> cables;
  final Map<String, StudioGraphNode> nodes;
  final String? selectedNodeId;
  final double nodeWidth;
  final double nodeHeight;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle background coordinate grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2638).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    const gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw glowing bezier cables between nodes
    for (final cable in cables) {
      final fromNode = nodes[cable.fromNodeId];
      final toNode = nodes[cable.toNodeId];
      if (fromNode == null || toNode == null) continue;

      final isHighlighted = fromNode.id == selectedNodeId || toNode.id == selectedNodeId;

      final start = Offset(
        fromNode.position.dx + nodeWidth,
        fromNode.position.dy + (nodeHeight * 0.45),
      );
      final end = Offset(
        toNode.position.dx,
        toNode.position.dy + (nodeHeight * 0.45),
      );

      final dxDiff = math.max((end.dx - start.dx).abs() * 0.5, 60.0);
      final cp1 = Offset(start.dx + dxDiff, start.dy);
      final cp2 = Offset(end.dx - dxDiff, end.dy);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

      // Outer Neon Glow Pass
      final glowPaint = Paint()
        ..color = isHighlighted
            ? cable.color.withValues(alpha: 0.65)
            : cable.color.withValues(alpha: 0.28)
        ..strokeWidth = isHighlighted ? 8.0 : 5.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isHighlighted ? 6.0 : 3.5);
      canvas.drawPath(path, glowPaint);

      // Inner Core Cable Pass
      final corePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            cable.color,
            isHighlighted ? Colors.white : cable.color.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = isHighlighted ? 3.0 : 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, corePaint);

      // Socket Connector Terminals
      _drawSocket(canvas, start, cable.color, isHighlighted);
      _drawSocket(canvas, end, cable.color, isHighlighted);
    }
  }

  void _drawSocket(Canvas canvas, Offset position, Color color, bool isHighlighted) {
    // Halo
    final haloPaint = Paint()
      ..color = color.withValues(alpha: isHighlighted ? 0.8 : 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, isHighlighted ? 7.0 : 5.5, haloPaint);

    // Core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 2.5, corePaint);
  }

  @override
  bool shouldRepaint(covariant BezierSplinePainter oldDelegate) {
    return true;
  }
}
