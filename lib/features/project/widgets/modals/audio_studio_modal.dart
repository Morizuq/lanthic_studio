import 'package:flutter/material.dart';
import '../../../../domain/models/aggregated_scene.dart';

class AudioStudioModal extends StatefulWidget {
  const AudioStudioModal({
    super.key,
    required this.project,
  });

  final StoryProject project;

  @override
  State<AudioStudioModal> createState() => _AudioStudioModalState();
}

class _AudioStudioModalState extends State<AudioStudioModal> {
  String? _currentlyPlayingSceneId;
  String _selectedVoice = 'Narrator (Male - Deep)';

  final _voices = const [
    'Narrator (Male - Deep)',
    'Narrator (Female - Warm)',
    'Narrator (Neutral - British)',
    'Dramatic (Cinema Trailer)',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scenes = widget.project.scenes;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B8FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.graphic_eq_outlined, color: Color(0xFF00B8FF), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Audio & Voice Narration Studio', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('TTS narration synthesizer and dialogue clips', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Voice Model Picker
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.record_voice_over, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    const Text('Voice Profile:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedVoice,
                          isExpanded: true,
                          items: _voices.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedVoice = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scene Audio List
              Text('Scene Narration Tracks', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: scenes.length,
                  separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    final isPlaying = _currentlyPlayingSceneId == scene.sceneId;
                    final seq = scene.sequence.toString().padLeft(2, '0');
                    final narrationText = scene.sceneModel.description;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: isPlaying ? Border.all(color: const Color(0xFF00B8FF), width: 1.5) : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                              color: const Color(0xFF00B8FF),
                              size: 32,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentlyPlayingSceneId = isPlaying ? null : scene.sceneId;
                              });
                              if (!isPlaying) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Simulating audio playback: Scene $seq with $_selectedVoice'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Scene $seq', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Text(
                                      isPlaying ? 'Playing • 0:05' : '⏱ 5.2s est.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isPlaying ? const Color(0xFF00B8FF) : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  narrationText,
                                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isPlaying) ...[
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: const LinearProgressIndicator(
                                      minHeight: 3,
                                      valueColor: AlwaysStoppedAnimation(Color(0xFF00B8FF)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
}
