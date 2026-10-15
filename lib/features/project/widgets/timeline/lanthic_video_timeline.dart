import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../../core/utils/asset_file_helper.dart';
import '../../../../domain/models/aggregated_scene.dart';
import '../../providers/project_providers.dart';

class LanthicVideoTimeline extends ConsumerStatefulWidget {
  const LanthicVideoTimeline({
    super.key,
    required this.project,
    required this.activeScene,
    required this.playbackSeconds,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onSeek,
  });

  final StoryProject project;
  final AggregatedScene activeScene;
  final double playbackSeconds;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onSeek;

  @override
  ConsumerState<LanthicVideoTimeline> createState() => _LanthicVideoTimelineState();
}

class _LanthicVideoTimelineState extends ConsumerState<LanthicVideoTimeline> {
  double _zoomScale = 1.0; // 1.0 = standard, 2.0 = zoomed in
  final ScrollController _scrollController = ScrollController();

  double _getSceneDuration(AggregatedScene scene) {
    return (scene.sceneModel.description.length / 20).clamp(4.0, 15.0);
  }

  double get _totalProjectDuration {
    if (widget.project.scenes.isEmpty) return 10.0;
    return widget.project.scenes.fold<double>(0.0, (acc, s) => acc + _getSceneDuration(s));
  }

  void _skipSeconds(double delta) {
    final next = (widget.playbackSeconds + delta).clamp(0.0, _totalProjectDuration);
    widget.onSeek(next);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scenes = widget.project.scenes;
    final totalDuration = _totalProjectDuration;
    final pixelsPerSecond = 24.0 * _zoomScale;
    final totalTimelineWidth = (totalDuration * pixelsPerSecond).clamp(320.0, 4000.0);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Canva-style Timeline Action Bar (Playback controls, timecode, zoom)
          LayoutBuilder(
            builder: (context, actionConstraints) {
              final isNarrow = actionConstraints.maxWidth < 560;
              final isVeryNarrow = actionConstraints.maxWidth < 420;

              return Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    // Transport controls
                    IconButton(
                      icon: const Icon(Icons.replay_5_rounded, size: 17),
                      tooltip: 'Rewind 5s',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () => _skipSeconds(-5.0),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: const Color(0xFF00B8FF),
                        size: 24,
                      ),
                      tooltip: widget.isPlaying ? 'Pause' : 'Play Sequence',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: widget.onTogglePlay,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_5_rounded, size: 17),
                      tooltip: 'Forward 5s',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () => _skipSeconds(5.0),
                    ),
                    const SizedBox(width: 6),
                    // Split clip tool
                    if (!isVeryNarrow)
                      Tooltip(
                        message: 'Split Scene Clip at Playhead',
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Clipped scene at ${widget.playbackSeconds.toStringAsFixed(1)}s'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.content_cut_rounded, size: 14, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text('Split', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Timecode Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isNarrow
                            ? _formatTime(widget.playbackSeconds)
                            : '${_formatTime(widget.playbackSeconds)} / ${_formatTime(totalDuration)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ),
                    const Spacer(),
                    // Timeline Zoom Controls
                    if (!isNarrow) ...[
                      Icon(Icons.zoom_out, size: 14, color: colorScheme.onSurfaceVariant),
                      SizedBox(
                        width: 80,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                            trackHeight: 2,
                          ),
                          child: Slider(
                            value: _zoomScale,
                            min: 0.6,
                            max: 2.5,
                            onChanged: (v) => setState(() => _zoomScale = v),
                          ),
                        ),
                      ),
                      Icon(Icons.zoom_in, size: 14, color: colorScheme.onSurfaceVariant),
                    ],
                  ],
                ),
              );
            },
          ),

          // 2. Multi-Track Canvas with Draggable Playhead Scrubber
          SizedBox(
            height: 128,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SizedBox(
                width: totalTimelineWidth,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ruler Track with second tick marks
                        _buildRulerTrack(totalDuration, pixelsPerSecond, colorScheme),
                        const SizedBox(height: 4),
                        // Track 1: Canva-style Scene Video Clip Cards
                        _buildSceneClipsTrack(scenes, pixelsPerSecond, colorScheme),
                        const SizedBox(height: 3),
                        // Track 2: Voice & Narration Waveform Track
                        _buildWaveformTrack('Narration', const Color(0xFF00B8FF), colorScheme),
                        const SizedBox(height: 2),
                        // Track 3: Dialogue Speech Balloons Track
                        _buildDialogueTrack(scenes, pixelsPerSecond, colorScheme),
                      ],
                    ),

                    // Draggable Playhead Scrubber Line across tracks
                    Positioned(
                      left: (widget.playbackSeconds * pixelsPerSecond).clamp(0.0, totalTimelineWidth - 2),
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          final newSec = (widget.playbackSeconds + (details.delta.dx / pixelsPerSecond)).clamp(0.0, totalDuration);
                          widget.onSeek(newSec);
                        },
                        child: Container(
                          width: 14,
                          alignment: Alignment.topCenter,
                          child: Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00B8FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: const Color(0xFF00B8FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulerTrack(double totalDuration, double pixelsPerSecond, ColorScheme colorScheme) {
    final secondCount = totalDuration.ceil();
    return SizedBox(
      height: 14,
      child: Row(
        children: List.generate(secondCount + 1, (i) {
          if (i % 2 != 0 && i != secondCount) return const SizedBox.shrink();
          return Container(
            width: pixelsPerSecond * 2,
            alignment: Alignment.centerLeft,
            child: Text(
              '${i}s',
              style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSceneClipsTrack(List<AggregatedScene> scenes, double pixelsPerSecond, ColorScheme colorScheme) {
    return SizedBox(
      height: 52,
      child: Row(
        children: scenes.map((scene) {
          final isSelected = scene.sceneId == widget.activeScene.sceneId;
          final duration = _getSceneDuration(scene);
          final clipWidth = (duration * pixelsPerSecond).clamp(72.0, 600.0);
          final asset = scene.currentAssetRecord;
          final imgFile = asset != null ? File(p.join(widget.project.rootPath, asset.filePath)) : null;

          return InkWell(
            onTap: () {
              ref.read(selectedSceneIdProvider.notifier).select(scene.sceneId);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: clipWidth,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00B8FF).withValues(alpha: 0.22) : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00B8FF) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  if (AssetFileHelper.isRealRenderedAsset(imgFile))
                    Image.file(imgFile!, width: 36, height: 52, fit: BoxFit.cover)
                  else
                    Container(width: 36, height: 52, color: Colors.black26, child: const Icon(Icons.image, size: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SC ${scene.sequence.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '⏱ ${duration.toStringAsFixed(1)}s',
                          style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWaveformTrack(String label, Color color, ColorScheme colorScheme) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Icon(Icons.graphic_eq_rounded, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: List.generate(35, (index) {
                final height = ((index % 5) + 2) * 2.2;
                return Container(
                  width: 2.5,
                  height: height,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(1)),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueTrack(List<AggregatedScene> scenes, double pixelsPerSecond, ColorScheme colorScheme) {
    return SizedBox(
      height: 18,
      child: Row(
        children: scenes.map((s) {
          final width = (_getSceneDuration(s) * pixelsPerSecond).clamp(72.0, 600.0);
          final hasDialogue = s.sceneModel.dialogue.isNotEmpty;
          return Container(
            width: width,
            margin: const EdgeInsets.only(right: 3),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: hasDialogue ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
            child: hasDialogue
                ? Row(
                    children: [
                      const Icon(Icons.chat_bubble_rounded, size: 10, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.sceneModel.dialogue.first.speaker,
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(double totalSeconds) {
    final mins = (totalSeconds / 60).floor();
    final secs = (totalSeconds % 60).toStringAsFixed(1).padLeft(4, '0');
    return '${mins.toString().padLeft(2, '0')}:$secs';
  }
}
