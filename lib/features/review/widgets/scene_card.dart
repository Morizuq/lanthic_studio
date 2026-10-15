import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/asset_file_helper.dart';
import '../../../domain/models/aggregated_scene.dart';
import '../../../domain/models/studio_models.dart';
import '../../../domain/models/visual_validation_model.dart';
import 'schema_flag_badge.dart';

class SceneCard extends StatelessWidget {
  const SceneCard({
    super.key,
    required this.scene,
    required this.projectRoot,
    required this.isSelected,
    required this.onTap,
  });

  final AggregatedScene scene;
  final String projectRoot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentAsset = scene.currentAssetRecord;

    final File? imageFile;
    if (currentAsset != null) {
      imageFile = File(p.join(projectRoot, currentAsset.filePath));
    } else {
      imageFile = null;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isSelected ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail preview
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 90,
                  height: 60,
                  color: colorScheme.surfaceContainerHighest,
                  child: AssetFileHelper.isRealRenderedAsset(imageFile)
                      ? Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => const Icon(Icons.broken_image, size: 24),
                        )
                      : const Center(
                          child: Icon(Icons.image_outlined, size: 28, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Scene info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${scene.sequence} ${scene.sceneId}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        _buildStatusPill(scene.status, colorScheme),
                        if (scene.flags.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          SchemaFlagBadge(flags: scene.flags),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scene.sceneModel.title.isNotEmpty
                          ? scene.sceneModel.title
                          : scene.sceneModel.slug,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scene.effectivePrompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (scene.validationRecord != null)
                          _buildVerdictTag(scene.validationRecord!.verdict),
                        const Spacer(),
                        Text(
                          'v${scene.selectedVersion} (${scene.assetVersions.length} revs)',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(ApprovalStatus status, ColorScheme colorScheme) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ApprovalStatus.approved:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = 'APPROVED';
        break;
      case ApprovalStatus.needsRegen:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        label = 'REGEN';
        break;
      case ApprovalStatus.rejected:
        bg = colorScheme.errorContainer;
        fg = colorScheme.onErrorContainer;
        label = 'REJECTED';
        break;
      case ApprovalStatus.pending:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildVerdictTag(ValidationVerdict verdict) {
    Color fg;
    IconData icon;
    switch (verdict) {
      case ValidationVerdict.pass:
        fg = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case ValidationVerdict.warn:
        fg = Colors.amber.shade800;
        icon = Icons.info_outline;
        break;
      case ValidationVerdict.fail:
        fg = Colors.red;
        icon = Icons.cancel_outlined;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 3),
        Text(
          verdict.name.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
        ),
      ],
    );
  }
}
