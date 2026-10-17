import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/utils/asset_file_helper.dart';
import '../models/studio_graph_models.dart';

class GraphNodeCard extends StatelessWidget {
  const GraphNodeCard({
    super.key,
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.onMove,
    this.onModelChanged,
    this.onGeneratePressed,
    this.availableModelIds = const ['qwen', 'flux'],
    this.cardWidth = 280.0,
    this.cardHeight = 220.0,
    this.isCooking = false,
  });

  final StudioGraphNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMove;
  final ValueChanged<String>? onModelChanged;
  final VoidCallback? onGeneratePressed;
  final List<String> availableModelIds;
  final double cardWidth;
  final double cardHeight;
  final bool isCooking;

  Color get _headerColor {
    switch (node.nodeType) {
      case GraphNodeType.story:
        return const Color(0xFF8B5CF6);
      case GraphNodeType.character:
        return const Color(0xFFFF9500);
      case GraphNodeType.prompt:
        return const Color(0xFF00B8FF);
      case GraphNodeType.generator:
        return const Color(0xFF10B981);
    }
  }

  IconData get _typeIcon {
    switch (node.nodeType) {
      case GraphNodeType.story:
        return Icons.auto_stories_outlined;
      case GraphNodeType.character:
        return Icons.person_outline;
      case GraphNodeType.prompt:
        return Icons.psychology_outlined;
      case GraphNodeType.generator:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGenerator = node.nodeType == GraphNodeType.generator;
    final isQwen = node.modelProvider == 'qwen';

    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (details) => onMove(details.delta),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF141923),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF232D3F),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.4),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _headerColor.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: _headerColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_typeIcon, size: 16, color: _headerColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        node.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _headerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        node.nodeType.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _headerColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(child: _buildBodyContent(context)),
                      if (isGenerator) ...[
                        const SizedBox(height: 6),
                        _buildGeneratorFooter(context, isQwen),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    if (node.nodeType == GraphNodeType.generator && node.imagePath != null) {
      final file = File(node.imagePath!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AssetFileHelper.isRealRenderedAsset(file)
            ? Image.file(
                file,
                key: ValueKey(
                  '${file.path}_${file.existsSync() ? file.lastModifiedSync().millisecondsSinceEpoch : 0}',
                ),
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : _buildImagePlaceholder(),
      );
    }

    if (node.promptText != null && node.promptText!.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F131C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1E2638)),
        ),
        child: SingleChildScrollView(
          child: Text(
            node.promptText!,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Color(0xFFCBD5E1),
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          node.characterName ?? 'Graph Anchor Node',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFF0F131C),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 22, color: Color(0xFF00E5FF)),
            SizedBox(height: 4),
            Text(
              'Ready to Render',
              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratorFooter(BuildContext context, bool isQwen) {
    final currentIndex = availableModelIds.indexOf(
      node.modelProvider.toLowerCase(),
    );
    final nextModel = availableModelIds.isNotEmpty
        ? availableModelIds[(currentIndex + 1) % availableModelIds.length]
        : (isQwen ? 'flux' : 'qwen');

    final displayLabel = isQwen
        ? 'HF Inference (FLUX)'
        : (node.modelProvider.toLowerCase() == 'flux'
              ? 'FLUX Pro'
              : node.modelProvider.toUpperCase());

    return Row(
      children: [
        // Model Tag
        Expanded(
          child: InkWell(
            onTap: onModelChanged != null
                ? () => onModelChanged!(nextModel)
                : null,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isQwen
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                    : const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isQwen
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF6366F1),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isQwen ? Icons.lock_open_outlined : Icons.speed_outlined,
                    size: 11,
                    color: isQwen
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF818CF8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      displayLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isQwen
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF818CF8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Action Button
        SizedBox(
          height: 26,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              backgroundColor: const Color(0xFF1E293B),
            ),
            onPressed: isCooking ? null : onGeneratePressed,
            child: isCooking
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Cooking...',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  )
                : const Text('Cook', style: TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }
}
