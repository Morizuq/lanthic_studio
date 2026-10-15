import 'package:flutter/material.dart';

class ResizableSplitter extends StatefulWidget {
  const ResizableSplitter({
    super.key,
    required this.onDragUpdate,
    this.onDoubleTap,
    this.isVertical = true,
  });

  final void Function(double delta) onDragUpdate;
  final VoidCallback? onDoubleTap;
  final bool isVertical;

  @override
  State<ResizableSplitter> createState() => _ResizableSplitterState();
}

class _ResizableSplitterState extends State<ResizableSplitter> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final normalColor = colorScheme.outlineVariant;

    final cursor = widget.isVertical
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;

    return MouseRegion(
      cursor: cursor,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onDoubleTap,
        onHorizontalDragStart: widget.isVertical
            ? (_) => setState(() => _isDragging = true)
            : null,
        onHorizontalDragUpdate: widget.isVertical
            ? (details) => widget.onDragUpdate(details.delta.dx)
            : null,
        onHorizontalDragEnd: widget.isVertical
            ? (_) => setState(() => _isDragging = false)
            : null,
        onVerticalDragStart: !widget.isVertical
            ? (_) => setState(() => _isDragging = true)
            : null,
        onVerticalDragUpdate: !widget.isVertical
            ? (details) => widget.onDragUpdate(details.delta.dy)
            : null,
        onVerticalDragEnd: !widget.isVertical
            ? (_) => setState(() => _isDragging = false)
            : null,
        child: Container(
          width: widget.isVertical ? 12 : null,
          height: !widget.isVertical ? 12 : null,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Container(
            width: widget.isVertical ? (_isHovered || _isDragging ? 3.0 : 1.5) : null,
            height: !widget.isVertical ? (_isHovered || _isDragging ? 3.0 : 1.5) : null,
            decoration: BoxDecoration(
              color: _isDragging || _isHovered ? activeColor : normalColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: _isDragging || _isHovered
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
