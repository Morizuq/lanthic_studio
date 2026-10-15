import 'package:flutter/material.dart';
import '../../../domain/models/aggregated_scene.dart';

class SchemaFlagBadge extends StatelessWidget {
  const SchemaFlagBadge({
    super.key,
    required this.flags,
  });

  final List<SceneValidationFlag> flags;

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) return const SizedBox.shrink();

    final hasError = flags.any((f) => f.severity == FlagSeverity.error);
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = hasError ? colorScheme.errorContainer : Colors.amber.shade100;
    final fgColor = hasError ? colorScheme.onErrorContainer : Colors.amber.shade900;
    final icon = hasError ? Icons.error_outline : Icons.warning_amber_rounded;

    return Tooltip(
      message: flags.map((f) => '[${f.phase}] ${f.message}').join('\n'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: fgColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: 4),
            Text(
              '${flags.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
