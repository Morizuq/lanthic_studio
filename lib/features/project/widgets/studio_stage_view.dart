import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/asset_file_helper.dart';
import '../../../domain/models/aggregated_scene.dart';
import '../../review/widgets/image_lightbox_dialog.dart';
import '../providers/project_providers.dart';
import 'timeline/lanthic_video_timeline.dart';

class StudioStageView extends ConsumerStatefulWidget {
  const StudioStageView({
    super.key,
    required this.project,
    required this.activeScene,
  });

  final StoryProject project;
  final AggregatedScene activeScene;

  @override
  ConsumerState<StudioStageView> createState() => _StudioStageViewState();
}

class _StudioStageViewState extends ConsumerState<StudioStageView> {
  int _selectedTool = 0; // 0: Select, 1: Aspect/Framing, 2: Dialogue Overlay, 3: Subtitles
  double _aspectRatio = 16 / 9;
  String _aspectRatioLabel = '16:9';
  bool _showDialogueOverlay = true;
  bool _isPlaying = false;
  double _playbackSeconds = 0.0;
  Timer? _playbackTimer;
  bool _isGenerating = false;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      final totalSec = (widget.activeScene.sceneModel.description.length / 20).clamp(4.0, 15.0);
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _playbackSeconds += 0.05;
          if (_playbackSeconds >= totalSec) {
            _playbackSeconds = 0.0;
            _isPlaying = false;
            timer.cancel();
          }
        });
      });
    } else {
      _playbackTimer?.cancel();
    }
  }

  void _cycleAspectRatio() {
    setState(() {
      if (_aspectRatioLabel == '16:9') {
        _aspectRatio = 21 / 9;
        _aspectRatioLabel = '21:9';
      } else if (_aspectRatioLabel == '21:9') {
        _aspectRatio = 4 / 3;
        _aspectRatioLabel = '4:3';
      } else if (_aspectRatioLabel == '4:3') {
        _aspectRatio = 1 / 1;
        _aspectRatioLabel = '1:1';
      } else {
        _aspectRatio = 16 / 9;
        _aspectRatioLabel = '16:9';
      }
    });
  }

  Future<void> _handleDirectGenerate() async {
    setState(() => _isGenerating = true);
    try {
      final regenService = ref.read(regenerationServiceProvider);
      await regenService.regenerateScene(
        project: widget.project,
        sceneId: widget.activeScene.sceneId,
        promptOverride: widget.activeScene.imagePrompt?.prompt,
      );
      await ref.read(projectStateNotifierProvider.notifier).refreshProject();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation Notice: $e. You can configure API keys using the key icon in the top right.'),
            backgroundColor: Colors.blueGrey.shade900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scenes = widget.project.scenes;
    final activeScene = widget.activeScene;

    final asset = activeScene.currentAssetRecord;
    final imageFile = asset != null ? File(p.join(widget.project.rootPath, asset.filePath)) : null;
    final hasRealImage = AssetFileHelper.isRealRenderedAsset(imageFile);
    final renderFile = hasRealImage ? imageFile! : null;

    final seqStr = activeScene.sequence.toString().padLeft(2, '0');
    final sceneTitle = activeScene.sceneModel.title.isNotEmpty ? activeScene.sceneModel.title : activeScene.sceneModel.slug;
    final totalDuration = (activeScene.sceneModel.description.length / 20).clamp(4.0, 15.0);

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // 1. Stage Interactive Subheader Bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: colorScheme.surface,
            child: Row(
              children: [
                Icon(Icons.video_camera_back_outlined, size: 15, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Scene $seqStr',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                Flexible(
                  child: Text(
                    '  /  $sceneTitle',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 6),
                if (renderFile != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 14),
                    tooltip: 'Open in Lightbox Preview',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    onPressed: () {
                      ImageLightboxDialog.show(
                        context,
                        imageFile: renderFile,
                        title: 'Scene $seqStr: $sceneTitle',
                        subtitle: activeScene.sceneModel.description,
                      );
                    },
                  ),
                const Spacer(),
                // Aspect Ratio Switcher Button
                TextButton.icon(
                  onPressed: _cycleAspectRatio,
                  icon: const Icon(Icons.crop_16_9, size: 14),
                  label: Text(_aspectRatioLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: _showDialogueOverlay ? 'Hide Speech Overlays' : 'Show Speech Overlays',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(
                    _showDialogueOverlay ? Icons.chat_bubble : Icons.chat_bubble_outline,
                    size: 15,
                    color: _showDialogueOverlay ? const Color(0xFF00B8FF) : colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => setState(() => _showDialogueOverlay = !_showDialogueOverlay),
                ),
              ],
            ),
          ),

          // 2. Main Stage with Floating Tools
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _aspectRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (renderFile != null)
                              GestureDetector(
                                onTap: () => ImageLightboxDialog.show(
                                  context,
                                  imageFile: renderFile,
                                  title: 'Scene $seqStr: $sceneTitle',
                                  subtitle: activeScene.sceneModel.description,
                                ),
                                child: Image.file(renderFile, fit: BoxFit.cover),
                              )
                            else
                              _buildGenerativeEmptyCanvas(context, seqStr, sceneTitle, activeScene),

                            // Dialogue bubble overlay on the stage
                            if (_showDialogueOverlay && activeScene.sceneModel.dialogue.isNotEmpty)
                              Positioned(
                                top: 32,
                                left: 40,
                                right: 40,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF00B8FF).withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      '"${activeScene.sceneModel.dialogue.first.text}"',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Bottom-left title overlay
                            Positioned(
                              left: 20,
                              bottom: 20,
                              right: 90,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'SCENE $seqStr',
                                      style: const TextStyle(
                                        color: Color(0xFF00B8FF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sceneTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 2)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Bottom-right duration overlay
                            Positioned(
                              right: 20,
                              bottom: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule, size: 13, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_playbackSeconds > 0 ? _playbackSeconds.toStringAsFixed(1) : totalDuration.toStringAsFixed(1)}s',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating Toolbar (Left side)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInteractiveTool(0, Icons.near_me_outlined, 'Select Tool', colorScheme),
                          _buildInteractiveTool(1, Icons.crop_outlined, 'Cycle Aspect Ratio', colorScheme, onTap: _cycleAspectRatio),
                          _buildInteractiveTool(2, Icons.chat_bubble_outline, 'Toggle Speech Balloons', colorScheme, onTap: () {
                            setState(() => _showDialogueOverlay = !_showDialogueOverlay);
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Filmstrip Storyboard Strip
          Container(
            height: 86,
            color: colorScheme.surface,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: scenes.length,
              itemBuilder: (context, index) {
                final sc = scenes[index];
                final isSelected = sc.sceneId == activeScene.sceneId;
                final scAsset = sc.currentAssetRecord;
                final scImg = scAsset != null ? File(p.join(widget.project.rootPath, scAsset.filePath)) : null;

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedSceneIdProvider.notifier).select(sc.sceneId);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 108,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary.withValues(alpha: 0.15) : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AssetFileHelper.isRealRenderedAsset(scImg)
                        ? Image.file(scImg!, fit: BoxFit.cover)
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.movie_creation_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                const SizedBox(height: 3),
                                Text(
                                  '${(index + 1).toString().padLeft(2, '0')} ${sc.sceneModel.slug}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // 4. Canva-style Interactive Video Timeline
          LanthicVideoTimeline(
            project: widget.project,
            activeScene: activeScene,
            playbackSeconds: _playbackSeconds,
            isPlaying: _isPlaying,
            onTogglePlay: _togglePlayback,
            onSeek: (seconds) => setState(() => _playbackSeconds = seconds),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerativeEmptyCanvas(BuildContext context, String seqStr, String sceneTitle, AggregatedScene activeScene) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [
            Color(0xFF0F1E2E),
            Color(0xFF06090F),
          ],
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00B8FF).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00B8FF).withValues(alpha: 0.3), blurRadius: 16),
                  ],
                ),
                child: const Icon(Icons.wb_incandescent_rounded, size: 24, color: Color(0xFF00B8FF)),
              ),
              const SizedBox(height: 10),
              Text(
                'Scene $seqStr Ready for Generation',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  activeScene.imagePrompt?.prompt ?? activeScene.sceneModel.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _isGenerating ? null : _handleDirectGenerate,
                icon: _isGenerating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.bolt_rounded, size: 16),
                label: Text(_isGenerating ? 'Synthesizing Asset...' : 'Generate Scene Image (FLUX)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00B8FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveTool(int index, IconData icon, String tooltip, ColorScheme colorScheme, {VoidCallback? onTap}) {
    final isActive = _selectedTool == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () {
          setState(() => _selectedTool = index);
          if (onTap != null) onTap();
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
