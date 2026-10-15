import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/asset_file_helper.dart';
import '../../../domain/models/aggregated_scene.dart';
import '../../../domain/models/studio_models.dart';
import '../../review/widgets/scene_directives_panel.dart';
import '../providers/project_providers.dart';
import 'modals/add_dialogue_dialog.dart';
import 'studio_inspector_tabs.dart';

class StudioInspectorView extends ConsumerStatefulWidget {
  const StudioInspectorView({
    super.key,
    required this.project,
    required this.scene,
    this.width = 330,
  });

  final StoryProject project;
  final AggregatedScene scene;
  final double width;

  @override
  ConsumerState<StudioInspectorView> createState() => _StudioInspectorViewState();
}

class _StudioInspectorViewState extends ConsumerState<StudioInspectorView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _promptOverrideController;
  late TextEditingController _notesController;
  double _zoomLevel = 1.08;
  String _cameraMovement = 'Ken Burns (zoom in)';
  double _durationSeconds = 5.2;
  bool _isPlayingNarration = false;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _promptOverrideController = TextEditingController(
      text: widget.scene.approval?.promptOverride ?? widget.scene.imagePrompt?.prompt ?? '',
    );
    _notesController = TextEditingController(
      text: widget.scene.approval?.reviewNotes ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant StudioInspectorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.sceneId != widget.scene.sceneId) {
      _promptOverrideController.text =
          widget.scene.approval?.promptOverride ?? widget.scene.imagePrompt?.prompt ?? '';
      _notesController.text = widget.scene.approval?.reviewNotes ?? '';
      _isPlayingNarration = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptOverrideController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleRegenerate() async {
    setState(() => _isRegenerating = true);
    try {
      final regenService = ref.read(regenerationServiceProvider);
      final activeProvider = ref.read(activeImageProviderIdProvider);
      final overrideText = _promptOverrideController.text.trim();
      await regenService.regenerateScene(
        project: widget.project,
        sceneId: widget.scene.sceneId,
        promptOverride: overrideText.isNotEmpty ? overrideText : null,
        providerOverride: activeProvider,
      );
      await ref.read(projectStateNotifierProvider.notifier).refreshProject();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scene ${widget.scene.sequence} regenerated successfully!'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Regeneration Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
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
    if (mounted) {
      final statusLabel = status == ApprovalStatus.approved ? 'Approved' : 'Flagged for Regen';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scene ${widget.scene.sequence} status: $statusLabel')),
      );
    }
  }

  void _showAddDialogueDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AddDialogueDialog(
        characters: widget.scene.sceneModel.characters,
        onAddDialogue: (speaker, text) {
          ref.read(projectStateNotifierProvider.notifier).addSceneDialogue(
                sceneId: widget.scene.sceneId,
                speaker: speaker,
                text: text,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dialogue added for $speaker')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scene = widget.scene;

    return Container(
      width: widget.width,
      color: colorScheme.surface,
      child: Column(
        children: [
          // 1. Inspector Tabs (Scene | Style | Export)
          TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelColor: colorScheme.primary,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(text: 'Scene'),
              Tab(text: 'Style'),
              Tab(text: 'Export'),
            ],
          ),

          // 2. Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSceneTab(theme, colorScheme, scene),
                StudioStyleTab(scene: scene),
                StudioExportTab(project: widget.project),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneTab(ThemeData theme, ColorScheme colorScheme, AggregatedScene scene) {
    final asset = scene.currentAssetRecord;
    final file = asset != null ? File(p.join(widget.project.rootPath, asset.filePath)) : null;
    final title = scene.sceneModel.title.isNotEmpty ? scene.sceneModel.title : scene.sceneModel.slug;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scene Mini Preview Card (Clean & Borderless)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AssetFileHelper.isRealRenderedAsset(file)
                      ? Image.file(file!, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        scene.sceneModel.description,
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Duration Control
          Row(
            children: [
              Text('Duration', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text('⏱ ${_durationSeconds.toStringAsFixed(1)} s', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              activeTrackColor: colorScheme.primary,
              thumbColor: colorScheme.primary,
            ),
            child: Slider(
              value: _durationSeconds,
              min: 2.0,
              max: 15.0,
              divisions: 26,
              onChanged: (val) => setState(() => _durationSeconds = val),
            ),
          ),
          const SizedBox(height: 8),

          // Camera Movement Control
          Text('Camera Movement', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          _buildDropdown(
            ['Ken Burns (zoom in)', 'Static Shot', 'Pan Right', 'Dolly In'],
            _cameraMovement,
            (val) {
              if (val != null) {
                setState(() => _cameraMovement = val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Camera set to: $val'), duration: const Duration(seconds: 1)),
                );
              }
            },
            colorScheme,
          ),
          const SizedBox(height: 12),

          // Zoom Control
          Row(
            children: [
              Text('Zoom Scale', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              const Spacer(),
              Text('${_zoomLevel.toStringAsFixed(2)}x', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              activeTrackColor: colorScheme.primary,
              thumbColor: colorScheme.primary,
            ),
            child: Slider(
              value: _zoomLevel,
              min: 1.0,
              max: 2.0,
              onChanged: (val) => setState(() => _zoomLevel = val),
            ),
          ),

          const Divider(),
          const SizedBox(height: 8),

          // Narration Section with interactive audio simulation
          Text('Narration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              scene.sceneModel.description,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.mic, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              const Text('Narrator (Voice TTS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isPlayingNarration ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  size: 22,
                ),
                color: const Color(0xFF00B8FF),
                onPressed: () {
                  setState(() => _isPlayingNarration = !_isPlayingNarration);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isPlayingNarration ? 'Playing narrator audio track...' : 'Narration paused.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          if (_isPlayingNarration) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: const LinearProgressIndicator(
                minHeight: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF00B8FF)),
              ),
            ),
          ],

          const Divider(),
          const SizedBox(height: 8),

          // Dialogue Section with functional Add Dialogue button
          Row(
            children: [
              Text('Dialogue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const Spacer(),
              Tooltip(
                message: 'Add Dialogue Line',
                child: InkWell(
                  onTap: _showAddDialogueDialog,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.add, size: 16, color: colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (scene.sceneModel.dialogue.isEmpty)
            Text('No dialogue in this scene beat.', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))
          else
            ...scene.sceneModel.dialogue.map(
              (d) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('"${d.text}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    Text('- ${d.speaker}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  ],
                ),
              ),
            ),

          const Divider(),
          const SizedBox(height: 12),

          // Review Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleSaveApproval(ApprovalStatus.needsRegen),
                  child: const Text('Flag Regen'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _handleSaveApproval(ApprovalStatus.approved),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Model Provider Selector for Scene Cooking
          Consumer(
            builder: (context, ref, _) {
              final activeProviderId = ref.watch(activeImageProviderIdProvider);
              final availableProviders = ref.watch(availableProvidersProvider);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hub_outlined, size: 14, color: Color(0xFF00B8FF)),
                    const SizedBox(width: 6),
                    Text('Model:', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: availableProviders.any((p) => p.providerIdentifier == activeProviderId)
                              ? activeProviderId
                              : (availableProviders.isNotEmpty ? availableProviders.first.providerIdentifier : 'qwen'),
                          isDense: true,
                          isExpanded: true,
                          alignment: Alignment.centerRight,
                          dropdownColor: colorScheme.surfaceContainerLow,
                          items: [
                            for (final p in availableProviders)
                              DropdownMenuItem(
                                value: p.providerIdentifier,
                                child: Text(
                                  p.displayName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(activeImageProviderIdProvider.notifier).selectProvider(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isRegenerating ? null : _handleRegenerate,
              icon: _isRegenerating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.refresh, size: 16),
              label: Text(_isRegenerating ? 'Generating...' : 'Regenerate Scene'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00B8FF),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          SceneDirectivesPanel(
            scene: scene,
            promptController: _promptOverrideController,
            isRegenerating: _isRegenerating,
            regenError: null,
            onRegenerate: _handleRegenerate,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String current, ValueChanged<String?> onChanged, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
