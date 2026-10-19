import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../domain/models/aggregated_scene.dart';
import '../../../domain/repositories/image_provider_contract.dart';
import '../../project/providers/project_providers.dart';
import '../../project/widgets/modals/api_keys_dialog.dart';
import '../models/studio_graph_models.dart';
import '../widgets/bezier_spline_painter.dart';
import '../widgets/graph_node_card.dart';

/// Interactive visual node-graph canvas for pipeline inspection and scene cooking.
///
/// Visualizes the narrative pipeline as a directed acyclic graph (DAG) where nodes
/// represent narrative entities (Story Root, Characters, Scenes) and edges represent
/// visual and narrative dependencies rendered via [BezierSplinePainter].
///
/// Features:
/// - 2D infinite pan and zoom canvas powered by [InteractiveViewer].
/// - Interactive node cards ([GraphNodeCard]) displaying status badges, prompt hashes,
///   and action triggers ("Cook", "Inspect", "Regenerate").
/// - Provider selection and API key management modal integration.
/// - Batch cooking orchestration across all scenes.
class StudioNodeGraphView extends ConsumerStatefulWidget {
  /// Constructs a [StudioNodeGraphView].
  ///
  /// * [project]: The active [StoryProject] whose scenes and characters populate the graph.
  const StudioNodeGraphView({super.key, required this.project});

  /// The active story project driving the node graph topology.
  final StoryProject project;

  @override
  ConsumerState<StudioNodeGraphView> createState() =>
      _StudioNodeGraphViewState();
}


class _StudioNodeGraphViewState extends ConsumerState<StudioNodeGraphView> {
  final TransformationController _transformController =
      TransformationController();
  final Map<String, StudioGraphNode> _nodes = {};
  final List<StudioGraphCable> _cables = [];
  String? _selectedNodeId;
  bool _isProcessing = false;
  bool _isCookingAll = false;
  String? _cookingNodeId;

  @override
  void initState() {
    super.initState();
    _buildGraphFromProject();
  }

  @override
  void didUpdateWidget(covariant StudioNodeGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project) {
      _buildGraphFromProject();
    }
  }

  void _buildGraphFromProject() {
    _nodes.clear();
    _cables.clear();

    final project =
        ref.read(projectStateNotifierProvider).value ?? widget.project;
    final scenes = project.scenes;
    final characters = project.continuity.characters;
    final currentDefaultModel = ref.read(activeImageProviderIdProvider);

    // 1. Root Narrative / Story Node
    const storyNodeId = 'node_story_root';
    _nodes[storyNodeId] = StudioGraphNode(
      id: storyNodeId,
      title: 'Story Narrative Root',
      subtitle: project.manifest.title,
      nodeType: GraphNodeType.story,
      position: const Offset(60, 80),
      promptText: project.canonicalStory.isNotEmpty
          ? project.canonicalStory
          : 'Canonical story script and world constraints',
    );

    // 2. Character Continuity Nodes
    final effectiveChars = characters.isNotEmpty
        ? characters
        : [
            if (scenes.isNotEmpty)
              ...scenes.first.sceneModel.characters.map((name) => (name: name)),
          ];

    int charIndex = 0;
    for (final char in effectiveChars) {
      final name = char is String ? char : (char as dynamic).name.toString();
      final charId = 'node_char_$name';
      _nodes[charId] = StudioGraphNode(
        id: charId,
        title: name,
        subtitle: 'Character Continuity Anchor',
        nodeType: GraphNodeType.character,
        position: Offset(60, 360.0 + (charIndex * 250.0)),
        characterName: name,
        promptText:
            'Visual anchor: Consistent face, wardrobe and color tokens for $name.',
      );

      _cables.add(
        StudioGraphCable(
          id: 'cable_story_char_$charIndex',
          fromNodeId: storyNodeId,
          toNodeId: charId,
          color: const Color(0xFF8B5CF6),
        ),
      );
      charIndex++;
    }

    // 3. Scene Prompt Nodes & 4. Generator Output Nodes
    int sceneIndex = 0;
    for (final scene in scenes) {
      final promptId = 'node_prompt_${scene.sceneId}';
      final genId = 'node_gen_${scene.sceneId}';
      final yPos = 80.0 + (sceneIndex * 260.0);

      // Prompt Node
      _nodes[promptId] = StudioGraphNode(
        id: promptId,
        title: 'Prompt: ${scene.sceneId}',
        subtitle: scene.sceneModel.title.isNotEmpty
            ? scene.sceneModel.title
            : 'Scene ${scene.sequence}',
        nodeType: GraphNodeType.prompt,
        position: Offset(420, yPos),
        promptText: scene.effectivePrompt,
        sceneId: scene.sceneId,
      );

      // Cable Story -> Prompt
      _cables.add(
        StudioGraphCable(
          id: 'cable_story_prompt_$sceneIndex',
          fromNodeId: storyNodeId,
          toNodeId: promptId,
          color: const Color(0xFF00E5FF),
        ),
      );

      // Cable Character -> Prompt
      for (final char in scene.sceneModel.characters) {
        final charNodeId = 'node_char_$char';
        if (_nodes.containsKey(charNodeId)) {
          _cables.add(
            StudioGraphCable(
              id: 'cable_char_${char}_${scene.sceneId}',
              fromNodeId: charNodeId,
              toNodeId: promptId,
              color: const Color(0xFFFF9500),
            ),
          );
        }
      }

      // Generator Node (defaults to active provider e.g. Qwen)
      final assetRecord = scene.currentAssetRecord;
      final fullAssetPath = assetRecord != null
          ? (p.isAbsolute(assetRecord.filePath)
                ? assetRecord.filePath
                : p.join(project.rootPath, assetRecord.filePath))
          : null;

      _nodes[genId] = StudioGraphNode(
        id: genId,
        title: 'Render: ${scene.sceneId}',
        subtitle: 'Frame Synthesis',
        nodeType: GraphNodeType.generator,
        position: Offset(780, yPos),
        imagePath: fullAssetPath,
        modelProvider: currentDefaultModel,
        status: scene.status.name,
        sceneId: scene.sceneId,
        promptText: scene.effectivePrompt,
      );

      // Cable Prompt -> Generator
      _cables.add(
        StudioGraphCable(
          id: 'cable_prompt_gen_$sceneIndex',
          fromNodeId: promptId,
          toNodeId: genId,
          color: const Color(0xFF10B981),
        ),
      );

      sceneIndex++;
    }
  }

  Future<void> _handleCookNode(StudioGraphNode node) async {
    if (node.sceneId == null || _isProcessing) return;
    ref.read(selectedSceneIdProvider.notifier).select(node.sceneId!);
    setState(() {
      _isProcessing = true;
      _cookingNodeId = node.id;
      _isCookingAll = false;
    });
    try {
      final regenService = ref.read(regenerationServiceProvider);
      final currentProject =
          ref.read(projectStateNotifierProvider).value ?? widget.project;
      final promptText =
          (node.promptText != null && node.promptText!.trim().isNotEmpty)
          ? node.promptText
          : currentProject.sceneById(node.sceneId!)?.effectivePrompt;
      await regenService.regenerateScene(
        project: currentProject,
        sceneId: node.sceneId!,
        promptOverride: promptText,
        providerOverride: node.modelProvider,
      );
      await ref.read(projectStateNotifierProvider.notifier).refreshProject();
      if (mounted) {
        setState(() {
          _buildGraphFromProject();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cooked frame for ${node.sceneId} with ${node.modelProvider.toUpperCase()}',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceFirst('GenerationFailure: ', '');
        final isAuthError =
            errText.contains('401') ||
            errText.contains('Token') ||
            errText.contains('API key') ||
            errText.contains('Authentication');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errText,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF991B1B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 6),
            action: isAuthError
                ? SnackBarAction(
                    label: 'Configure Key',
                    textColor: const Color(0xFF00E5FF),
                    onPressed: () => ApiKeysDialog.show(context),
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _cookingNodeId = null;
        });
      }
    }
  }

  Future<void> _handleCookAll() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _isCookingAll = true;
    });
    final regenService = ref.read(regenerationServiceProvider);
    final activeModel = ref.read(activeImageProviderIdProvider);
    final currentProject =
        ref.read(projectStateNotifierProvider).value ?? widget.project;
    try {
      for (final scene in currentProject.scenes) {
        if (mounted) {
          setState(() {
            _cookingNodeId = 'node_gen_${scene.sceneId}';
          });
        }
        await regenService.regenerateScene(
          project: currentProject,
          sceneId: scene.sceneId,
          providerOverride: activeModel,
        );
      }
      await ref.read(projectStateNotifierProvider.notifier).refreshProject();
      if (mounted) {
        setState(() {
          _buildGraphFromProject();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cooked all ${widget.project.scenes.length} frames using ${activeModel.toUpperCase()}',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceFirst('GenerationFailure: ', '');
        final isAuthError =
            errText.contains('401') ||
            errText.contains('Token') ||
            errText.contains('API key') ||
            errText.contains('Authentication');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errText,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF991B1B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 6),
            action: isAuthError
                ? SnackBarAction(
                    label: 'Configure Key',
                    textColor: const Color(0xFF00E5FF),
                    onPressed: () => ApiKeysDialog.show(context),
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _cookingNodeId = null;
          _isCookingAll = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableProviders = ref.watch(availableProvidersProvider);
    final availableModelIds = availableProviders
        .map((p) => p.providerIdentifier)
        .toList();

    return Column(
      children: [
        _buildHudBar(context, availableProviders),
        Expanded(
          child: Container(
            color: const Color(0xFF090D14),
            child: InteractiveViewer(
              transformationController: _transformController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(1200),
              minScale: 0.25,
              maxScale: 2.5,
              child: SizedBox(
                width: 2400,
                height: 1800,
                child: Stack(
                  children: [
                    // Bezier Splines and Grid Canvas
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BezierSplinePainter(
                          cables: _cables,
                          nodes: _nodes,
                          selectedNodeId: _selectedNodeId,
                        ),
                      ),
                    ),
                    // Interactive Node Cards
                    for (final node in _nodes.values)
                      GraphNodeCard(
                        key: ValueKey(node.id),
                        node: node,
                        isSelected: node.id == _selectedNodeId,
                        availableModelIds: availableModelIds,
                        onTap: () {
                          setState(() => _selectedNodeId = node.id);
                          if (node.sceneId != null) {
                            ref
                                .read(selectedSceneIdProvider.notifier)
                                .select(node.sceneId!);
                          }
                        },
                        onMove: (delta) {
                          setState(() {
                            node.position += delta;
                          });
                        },
                        onModelChanged: (newModel) {
                          setState(() {
                            node.modelProvider = newModel;
                          });
                        },
                        onGeneratePressed: _isProcessing
                            ? null
                            : () => _handleCookNode(node),
                        isCooking: _cookingNodeId == node.id,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHudBar(
    BuildContext context,
    List<ImageProviderContract> availableProviders,
  ) {
    final activeProviderId = ref.watch(activeImageProviderIdProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F141F),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2638))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.hub_outlined, size: 18, color: Color(0xFF00E5FF)),
            const SizedBox(width: 8),
            const Text(
              'Node Pipeline Canvas',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            _buildLegendItem('Narrative', const Color(0xFF00E5FF)),
            const SizedBox(width: 12),
            _buildLegendItem('Continuity', const Color(0xFFFF9500)),
            const SizedBox(width: 12),
            _buildLegendItem('Generation', const Color(0xFF10B981)),
            const SizedBox(width: 32),
            // Global Model Switch (dynamically populated from registered providers)
            Container(
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF161F2E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF253348)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final prov in availableProviders)
                    _buildModelChoiceChip(
                      prov.displayName,
                      prov.providerIdentifier,
                      isSelected: activeProviderId == prov.providerIdentifier,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00B8FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: _isCookingAll
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 15),
              label: Text(
                _isCookingAll ? 'Cooking Graph...' : 'Cook Graph',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _isProcessing ? null : _handleCookAll,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Reset Canvas View',
              icon: const Icon(Icons.filter_center_focus_outlined, size: 18),
              onPressed: () => _transformController.value = Matrix4.identity(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelChoiceChip(
    String label,
    String value, {
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(activeImageProviderIdProvider.notifier).selectProvider(value);
        setState(() {
          for (final n in _nodes.values) {
            if (n.nodeType == GraphNodeType.generator) {
              n.modelProvider = value;
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00B8FF).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? const Color(0xFF00E5FF)
                : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
