import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../continuity/screens/continuity_explorer_view.dart';
import '../../graph/screens/studio_node_graph_view.dart';
import '../../pipeline/screens/pipeline_status_view.dart';
import '../../reader/screens/comic_reader_view.dart';
import '../providers/project_providers.dart';
import '../../../shared/design_system/widgets/resizable_splitter.dart';
import '../widgets/modals/api_keys_dialog.dart';
import '../widgets/project_empty_view.dart';
import '../widgets/studio_header_bar.dart';
import '../widgets/studio_inspector_view.dart';
import '../widgets/studio_left_nav.dart';
import '../widgets/studio_stage_view.dart';

class ProjectShellScreen extends ConsumerStatefulWidget {
  const ProjectShellScreen({super.key});

  @override
  ConsumerState<ProjectShellScreen> createState() => _ProjectShellScreenState();
}

class _ProjectShellScreenState extends ConsumerState<ProjectShellScreen> {
  double _leftPanelWidth = 240.0;
  double _rightPanelWidth = 330.0;
  bool _isLeftPanelVisible = true;
  bool _isRightPanelVisible = true;

  Future<void> _handleOpenFolder() async {
    try {
      if (Platform.isMacOS) {
        await FilePicker.skipEntitlementsChecks();
      }
      final selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Skills Engine Project Folder',
      );

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        ref.read(projectStateNotifierProvider.notifier).openProject(selectedDirectory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker notice: $e')),
        );
      }
    }
  }

  void _showApiKeysDialog() {
    ApiKeysDialog.show(context);
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export menu opened. Select PDF, MP4, or ZIP archive from the Inspector Export tab.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectAsync = ref.watch(projectStateNotifierProvider);
    final activeViewMode = ref.watch(studioViewModeProvider);
    final selectedSceneId = ref.watch(selectedSceneIdProvider);

    return Scaffold(
      appBar: StudioHeaderBar(
        onOpenFolder: _handleOpenFolder,
        onShowApiKeys: _showApiKeysDialog,
        onExport: _handleExport,
        isLeftPanelVisible: _isLeftPanelVisible,
        isRightPanelVisible: _isRightPanelVisible,
        onToggleLeftPanel: () => setState(() => _isLeftPanelVisible = !_isLeftPanelVisible),
        onToggleRightPanel: () => setState(() => _isRightPanelVisible = !_isRightPanelVisible),
      ),
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 12),
                Text('Failed to Load Project', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(err.toString(), textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => ref.read(projectStateNotifierProvider.notifier).refreshProject(),
                      child: const Text('Retry'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _handleOpenFolder,
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: const Text('Open Folder'),
                    ),
                    TextButton(
                      onPressed: () => ref.read(projectStateNotifierProvider.notifier).resetToEmpty(),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        data: (project) {
          if (project == null) {
            return const ProjectEmptyView();
          }

          final scenes = project.scenes;
          final currentSelectedId =
              selectedSceneId ?? (scenes.isNotEmpty ? scenes.first.sceneId : null);
          final activeScene = currentSelectedId != null ? project.sceneById(currentSelectedId) : null;

          return LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final isCompactWindow = totalWidth < 1080;
              final isNarrowWindow = totalWidth < 760;

              // In compact viewports, if left nav is at default 240px, adapt to compact icon dock (56px)
              final effectiveLeftWidth = (isCompactWindow && _leftPanelWidth == 240.0)
                  ? 56.0
                  : _leftPanelWidth;

              // In review mode, show right inspector if enabled and space permits
              final isReviewMode = activeViewMode == StudioViewMode.review;
              final showRightPanel = isReviewMode &&
                  _isRightPanelVisible &&
                  activeScene != null &&
                  (!isNarrowWindow || !_isLeftPanelVisible);

              final maxLeftDrag = (totalWidth - (showRightPanel ? 220.0 : 0.0) - 280.0).clamp(56.0, 480.0);
              final maxRightDrag = (totalWidth - (_isLeftPanelVisible ? effectiveLeftWidth : 0.0) - 280.0).clamp(220.0, 560.0);

              Widget centerContent;
              switch (activeViewMode) {
                case StudioViewMode.graph:
                  centerContent = StudioNodeGraphView(
                    project: project,
                  );
                case StudioViewMode.reader:
                  centerContent = ComicReaderView(
                    scenes: project.scenes,
                    projectRoot: project.rootPath,
                  );
                case StudioViewMode.continuity:
                  centerContent = ContinuityExplorerView(
                    project: project,
                  );
                case StudioViewMode.pipeline:
                  centerContent = PipelineStatusView(
                    project: project,
                  );
                case StudioViewMode.review:
                  centerContent = activeScene != null
                      ? StudioStageView(
                          project: project,
                          activeScene: activeScene,
                        )
                      : const Center(child: Text('Select a scene to review'));
              }

              return Row(
                children: [
                  // Persistent Left Navigation Pane (Collapsible & Resizable across all studio modes)
                  if (_isLeftPanelVisible) ...[
                    StudioLeftNav(
                      project: project,
                      selectedSceneId: currentSelectedId,
                      width: effectiveLeftWidth.clamp(56.0, maxLeftDrag),
                      onOpenSettings: _showApiKeysDialog,
                    ),
                    ResizableSplitter(
                      isVertical: true,
                      onDragUpdate: (delta) {
                        setState(() {
                          _leftPanelWidth = (_leftPanelWidth + delta).clamp(56.0, maxLeftDrag);
                        });
                      },
                      onDoubleTap: () {
                        setState(() {
                          _isLeftPanelVisible = !_isLeftPanelVisible;
                        });
                      },
                    ),
                  ],
                  // Center Content Area (Dynamic: Review Stage, Comic Reader, Continuity, Pipeline)
                  Expanded(
                    child: centerContent,
                  ),
                  // Right Inspector Panel (Active in Review Mode)
                  if (showRightPanel) ...[
                    ResizableSplitter(
                      isVertical: true,
                      onDragUpdate: (delta) {
                        setState(() {
                          _rightPanelWidth = (_rightPanelWidth - delta).clamp(220.0, maxRightDrag);
                        });
                      },
                      onDoubleTap: () {
                        setState(() {
                          _isRightPanelVisible = !_isRightPanelVisible;
                        });
                      },
                    ),
                    StudioInspectorView(
                      project: project,
                      scene: activeScene,
                      width: _rightPanelWidth.clamp(220.0, maxRightDrag),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
