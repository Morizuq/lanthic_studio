import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/asset_file_helper.dart';
import '../../../domain/models/aggregated_scene.dart';
import '../../../domain/models/studio_models.dart';
import '../../project/providers/project_providers.dart';
import 'image_lightbox_dialog.dart';
import 'scene_directives_panel.dart';

class SceneInspector extends ConsumerStatefulWidget {
  const SceneInspector({
    super.key,
    required this.scene,
    required this.projectRoot,
  });

  final AggregatedScene scene;
  final String projectRoot;

  @override
  ConsumerState<SceneInspector> createState() => _SceneInspectorState();
}

class _SceneInspectorState extends ConsumerState<SceneInspector> {
  late TextEditingController _promptOverrideController;
  late TextEditingController _notesController;
  bool _isRegenerating = false;
  String? _regenError;

  @override
  void initState() {
    super.initState();
    _promptOverrideController = TextEditingController(
      text: widget.scene.approval?.promptOverride ?? '',
    );
    _notesController = TextEditingController(
      text: widget.scene.approval?.reviewNotes ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant SceneInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.sceneId != widget.scene.sceneId) {
      _promptOverrideController.text = widget.scene.approval?.promptOverride ?? '';
      _notesController.text = widget.scene.approval?.reviewNotes ?? '';
      _regenError = null;
    }
  }

  @override
  void dispose() {
    _promptOverrideController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleRegenerate() async {
    setState(() {
      _isRegenerating = true;
      _regenError = null;
    });

    try {
      final project = ref.read(projectStateNotifierProvider).value;
      if (project == null) return;

      final regenService = ref.read(regenerationServiceProvider);
      final overrideText = _promptOverrideController.text.trim();

      await regenService.regenerateScene(
        project: project,
        sceneId: widget.scene.sceneId,
        promptOverride: overrideText.isNotEmpty ? overrideText : null,
      );

      await ref.read(projectStateNotifierProvider.notifier).refreshProject();
    } catch (e) {
      setState(() {
        _regenError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
  }

  Future<void> _handleSaveApproval(ApprovalStatus status) async {
    final overrideText = _promptOverrideController.text.trim();
    await ref.read(projectStateNotifierProvider.notifier).updateSceneApproval(
      sceneId: widget.scene.sceneId,
      status: status,
      promptOverride: overrideText.isNotEmpty ? overrideText : null,
      reviewNotes: _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scene = widget.scene;
    final currentAsset = scene.currentAssetRecord;

    final File? imageFile;
    if (currentAsset != null) {
      imageFile = File(p.join(widget.projectRoot, currentAsset.filePath));
    } else {
      imageFile = null;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scene Title Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scene #${scene.sequence}: ${scene.sceneId}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      scene.sceneModel.title.isNotEmpty
                          ? scene.sceneModel.title
                          : scene.sceneModel.slug,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _handleSaveApproval(ApprovalStatus.needsRegen),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Flag Regen'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _handleSaveApproval(ApprovalStatus.approved),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Approve'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Asset Preview Container
          GestureDetector(
            onTap: () {
              if (imageFile != null && imageFile.existsSync()) {
                ImageLightboxDialog.show(
                  context,
                  imageFile: imageFile,
                  title: 'Scene #${scene.sequence}: ${scene.sceneId}',
                  subtitle: scene.sceneModel.title.isNotEmpty ? scene.sceneModel.title : scene.sceneModel.slug,
                );
              }
            },
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AssetFileHelper.isRealRenderedAsset(imageFile)
                        ? Image.file(
                            imageFile!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, stackTrace) => const Center(
                              child: Text('Asset file cannot be rendered'),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_outlined, size: 48, color: colorScheme.outline),
                                const SizedBox(height: 8),
                                Text(
                                  'No generated asset for version ${scene.selectedVersion}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                if (imageFile != null && imageFile.existsSync())
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Click to zoom', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Version History Chips (Wired to version switching!)
          Row(
            children: [
              Text('Asset Versions: ', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (scene.assetVersions.isEmpty)
                Text('None generated yet', style: theme.textTheme.bodySmall)
              else
                Wrap(
                  spacing: 6,
                  children: scene.assetVersions.map((v) {
                    final isSel = v.version == scene.selectedVersion;
                    return ChoiceChip(
                      label: Text('v${v.version}'),
                      selected: isSel,
                      onSelected: (_) {
                        ref.read(projectStateNotifierProvider.notifier).updateSelectedVersion(
                          sceneId: scene.sceneId,
                          version: v.version,
                        );
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Tabs: Directives, Audit, Lettering
          SceneDirectivesPanel(
            scene: scene,
            promptController: _promptOverrideController,
            isRegenerating: _isRegenerating,
            regenError: _regenError,
            onRegenerate: _handleRegenerate,
          ),
        ],
      ),
    );
  }
}
