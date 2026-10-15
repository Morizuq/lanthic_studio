import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/asset_file_helper.dart';
import '../../../domain/models/aggregated_scene.dart';
import '../providers/project_providers.dart';
import 'modals/add_scene_dialog.dart';
import 'modals/asset_gallery_modal.dart';
import 'modals/audio_studio_modal.dart';
import 'modals/narrative_beats_modal.dart';
import 'modals/project_overview_modal.dart';

class StudioLeftNav extends ConsumerWidget {
  const StudioLeftNav({
    super.key,
    required this.project,
    required this.selectedSceneId,
    this.width = 240,
    this.onOpenSettings,
  });

  final StoryProject project;
  final String? selectedSceneId;
  final double width;
  final VoidCallback? onOpenSettings;

  void _showOverview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ProjectOverviewModal(project: project),
    );
  }

  void _showBeats(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => NarrativeBeatsModal(
        project: project,
        onSelectScene: (id) {
          ref
              .read(studioViewModeProvider.notifier)
              .setMode(StudioViewMode.review);
          ref.read(selectedSceneIdProvider.notifier).select(id);
        },
      ),
    );
  }

  void _showAssets(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AssetGalleryModal(
        project: project,
        onSelectScene: (id) {
          ref
              .read(studioViewModeProvider.notifier)
              .setMode(StudioViewMode.review);
          ref.read(selectedSceneIdProvider.notifier).select(id);
        },
      ),
    );
  }

  void _showAudio(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AudioStudioModal(project: project),
    );
  }

  void _showAddScene(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AddSceneDialog(
        nextSequence: project.scenes.length + 1,
        onAddScene:
            ({required title, required description, required setting}) async {
              await ref
                  .read(projectStateNotifierProvider.notifier)
                  .addSceneDraft(
                    title: title,
                    description: description,
                    setting: setting,
                  );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewMode = ref.watch(studioViewModeProvider);
    final isCompact = width < 150;

    return Container(
      width: width,
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Project Identity Card (Clickable to open Project Overview)
          _buildIdentityCard(context, colorScheme, isCompact),

          // 2. Navigation Categories (Functional and mapped to views/modals)
          _buildNavItem(
            icon: Icons.dashboard_outlined,
            title: 'Overview',
            isActive: false,
            badge: null,
            colorScheme: colorScheme,
            isCompact: isCompact,
            onTap: () => _showOverview(context),
          ),
          _buildNavItem(
            icon: Icons.auto_stories_outlined,
            title: 'Story',
            isActive: viewMode == StudioViewMode.reader,
            badge: null,
            colorScheme: colorScheme,
            isCompact: isCompact,
            onTap: () => ref
                .read(studioViewModeProvider.notifier)
                .setMode(StudioViewMode.reader),
          ),
          _buildNavItem(
            icon: Icons.group_outlined,
            title: 'Characters',
            isActive: viewMode == StudioViewMode.continuity,
            badge: '${project.continuity.characters.length}',
            colorScheme: colorScheme,
            isCompact: isCompact,
            onTap: () => ref
                .read(studioViewModeProvider.notifier)
                .setMode(StudioViewMode.continuity),
          ),
          _buildNavItem(
            icon: Icons.view_timeline_outlined,
            title: 'Beats',
            isActive: false,
            badge: null,
            colorScheme: colorScheme,
            isCompact: isCompact,
            onTap: () => _showBeats(context, ref),
          ),
          _buildNavItem(
            icon: Icons.movie_creation_outlined,
            title: 'Scenes',
            isActive: viewMode == StudioViewMode.review,
            badge: '${project.totalScenes}',
            colorScheme: colorScheme,
            isCompact: isCompact,
            onTap: () => ref
                .read(studioViewModeProvider.notifier)
                .setMode(StudioViewMode.review),
          ),
          _buildNavItem(
            icon: Icons.hub_outlined,
            title: 'Node Graph',
            isActive: viewMode == StudioViewMode.graph,
            badge: null,
            colorScheme: colorScheme,
            isCompact: isCompact,
            onTap: () => ref
                .read(studioViewModeProvider.notifier)
                .setMode(StudioViewMode.graph),
          ),
          _buildNavItem(
            icon: Icons.photo_library_outlined,
            title: 'Assets',
            isActive: false,
            badge: null,
            colorScheme: colorScheme,
            isCompact: isCompact,
            onTap: () => _showAssets(context, ref),
          ),
          _buildNavItem(
            icon: Icons.graphic_eq_outlined,
            title: 'Audio',
            isActive: false,
            badge: null,
            colorScheme: colorScheme,
            isCompact: isCompact,
            onTap: () => _showAudio(context),
          ),
          _buildNavItem(
            icon: Icons.tune_outlined,
            title: 'Settings',
            isActive: false,
            badge: null,
            colorScheme: colorScheme,
            isCompact: isCompact,
            onTap: () {
              if (onOpenSettings != null) {
                onOpenSettings!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Settings available via header bar gear icon.',
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // 3. Scene List Header with functional Add Scene action
          if (!isCompact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Scenes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: 'Add New Scene Beat',
                    child: InkWell(
                      onTap: () => _showAddScene(context, ref),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 4. Compact Scene Thumbnails List (Clickable, reactive selection)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              itemCount: project.scenes.length,
              itemBuilder: (context, index) {
                final scene = project.scenes[index];
                final isSelected = scene.sceneId == selectedSceneId;
                return _buildSceneListItem(
                  context,
                  ref,
                  scene,
                  isSelected,
                  colorScheme,
                  isCompact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isCompact,
  ) {
    if (isCompact) {
      return Tooltip(
        message:
            'Project: ${project.manifest.title.isNotEmpty ? project.manifest.title : "Active Story"}',
        child: InkWell(
          onTap: () => _showOverview(context),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildProjectThumbnail(project),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: InkWell(
        onTap: () => _showOverview(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildProjectThumbnail(project),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROJECT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Active Story Project',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.info_outline,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectThumbnail(StoryProject project) {
    if (project.scenes.isNotEmpty) {
      final firstAsset = project.scenes.first.currentAssetRecord;
      if (firstAsset != null) {
        final file = File(p.join(project.rootPath, firstAsset.filePath));
        if (AssetFileHelper.isRealRenderedAsset(file)) {
          return Image.file(file, fit: BoxFit.cover);
        }
      }
    }
    return const Icon(
      Icons.wb_incandescent_outlined,
      size: 16,
      color: Color(0xFF00B8FF),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required bool isActive,
    required String? badge,
    required ColorScheme colorScheme,
    required bool isCompact,
    required VoidCallback onTap,
  }) {
    if (isCompact) {
      return Tooltip(
        message: badge != null ? '$title ($badge)' : title,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSceneListItem(
    BuildContext context,
    WidgetRef ref,
    AggregatedScene scene,
    bool isSelected,
    ColorScheme colorScheme,
    bool isCompact,
  ) {
    final asset = scene.currentAssetRecord;
    final file = asset != null
        ? File(p.join(project.rootPath, asset.filePath))
        : null;

    final seqStr = scene.sequence.toString().padLeft(2, '0');
    final title = scene.sceneModel.title.isNotEmpty
        ? scene.sceneModel.title
        : scene.sceneModel.slug;

    if (isCompact) {
      return Tooltip(
        message: '$seqStr $title',
        child: InkWell(
          onTap: () {
            ref
                .read(studioViewModeProvider.notifier)
                .setMode(StudioViewMode.review);
            ref.read(selectedSceneIdProvider.notifier).select(scene.sceneId);
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(color: const Color(0xFF00B8FF), width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                seqStr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF00B8FF)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () {
          ref
              .read(studioViewModeProvider.notifier)
              .setMode(StudioViewMode.review);
          ref.read(selectedSceneIdProvider.notifier).select(scene.sceneId);
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Row(
            children: [
              if (isSelected)
                Container(
                  width: 3,
                  height: 18,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B8FF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Container(
                width: 40,
                height: 25,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.antiAlias,
                child: AssetFileHelper.isRealRenderedAsset(file)
                    ? Image.file(file!, fit: BoxFit.cover)
                    : Icon(Icons.image, size: 12, color: colorScheme.outline),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$seqStr $title',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
