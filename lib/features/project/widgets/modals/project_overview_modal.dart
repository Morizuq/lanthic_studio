import 'package:flutter/material.dart';
import '../../../../domain/models/aggregated_scene.dart';

class ProjectOverviewModal extends StatelessWidget {
  const ProjectOverviewModal({
    super.key,
    required this.project,
  });

  final StoryProject project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalScenes = project.totalScenes;
    final approved = project.approvedCount;
    final needsRegen = project.needsRegenCount;
    final pending = totalScenes - approved - needsRegen;
    final progress = totalScenes > 0 ? (approved / totalScenes) : 0.0;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B8FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dashboard_outlined, color: Color(0xFF00B8FF), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.manifest.title.isNotEmpty
                              ? project.manifest.title
                              : 'Story Project Overview',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Story ID: ${project.manifest.storyId} • Run ID: ${project.manifest.runId}',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress Bar Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Overall Completion',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).toInt()}% Approved',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00B8FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF00B8FF)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatChip('Total', '$totalScenes', colorScheme.onSurface, colorScheme),
                        _buildStatChip('Approved', '$approved', Colors.green, colorScheme),
                        _buildStatChip('Needs Regen', '$needsRegen', Colors.orange, colorScheme),
                        _buildStatChip('Pending', '$pending', colorScheme.outline, colorScheme),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Project Metadata Details
              Text('Project Specifications', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildMetaTile('Default Provider', project.manifest.provider.toUpperCase(), Icons.hub_outlined, colorScheme),
                    _buildMetaTile('Characters in Continuity', '${project.continuity.characters.length} characters tracked', Icons.people_outline, colorScheme),
                    _buildMetaTile('Continuity Objects', '${project.continuity.objects.length} world objects', Icons.category_outlined, colorScheme),
                    _buildMetaTile('World Rules', '${project.continuity.worldRules.length} narrative rules', Icons.rule_outlined, colorScheme),
                    _buildMetaTile('Visual Direction Style', project.visualDirection.style.isNotEmpty ? project.visualDirection.style : 'Cinematic Graphic Novel', Icons.palette_outlined, colorScheme),
                    _buildMetaTile('Project Location', project.rootPath, Icons.folder_outlined, colorScheme),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildMetaTile(String title, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
