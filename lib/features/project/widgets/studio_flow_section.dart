import 'package:flutter/material.dart';

class StudioFlowSection extends StatelessWidget {
  const StudioFlowSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand & Tagline Header (Minimalist & Powered by Lanthic Lantern)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF00B8FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B8FF).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/lanthic_lantern_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.wb_incandescent_rounded,
                  size: 30,
                  color: Color(0xFF00B8FF),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Lanthic',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: const Color(0xFF00B8FF),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Studio',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'v0.1 BETA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From story to screen.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Text(
                      'A desktop storytelling studio that turns AI-generated stories into comics, videos and more. Built for creators, writers and dreamers.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),

        // 4-Step Pipeline Flow (Clean & Minimalist)
        Text(
          'THE FLOW',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;
            if (isNarrow) {
              return Column(
                children: [
                  _buildFlowStep(context, '1', 'Generate with Lanthic Skills', 'Get your story, beats, scenes and scene images.'),
                  const SizedBox(height: 12),
                  _buildFlowStep(context, '2', 'Open in Studio', 'Edit, organise and shape your project.'),
                  const SizedBox(height: 12),
                  _buildFlowStep(context, '3', 'Create Your Output', 'Make comics, videos, or both.'),
                  const SizedBox(height: 12),
                  _buildFlowStep(context, '4', 'Export & Share', 'Download your final creation in high quality.'),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFlowStep(context, '1', 'Generate with Lanthic Skills', 'Get your story, beats, scenes and scene images.')),
                _buildFlowArrow(colorScheme),
                Expanded(child: _buildFlowStep(context, '2', 'Open in Studio', 'Edit, organise and shape your project.')),
                _buildFlowArrow(colorScheme),
                Expanded(child: _buildFlowStep(context, '3', 'Create Your Output', 'Make comics, videos, or both.')),
                _buildFlowArrow(colorScheme),
                Expanded(child: _buildFlowStep(context, '4', 'Export & Share', 'Download your final creation in high quality.')),
              ],
            );
          },
        ),
        const SizedBox(height: 36),

        // Features & Future Columns (Clean, No Box-Within-Box Borders)
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key Features
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Features (v0.1)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildCheckItem(context, 'Project-based storytelling workspace'),
                    _buildCheckItem(context, 'Storyboard editor with scene management'),
                    _buildCheckItem(context, 'Comic layout & editing tools'),
                    _buildCheckItem(context, 'Video compositor (basic)'),
                    _buildCheckItem(context, 'Audio, narration and music integration'),
                    _buildCheckItem(context, 'Export to PDF (comics) and MP4 (video)'),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Future Roadmap
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Future',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildFutureItem(Icons.video_camera_back_outlined, 'Full video editor', colorScheme),
                    _buildFutureItem(Icons.auto_fix_high_outlined, 'Animation tools', colorScheme),
                    _buildFutureItem(Icons.group_outlined, 'Team collaboration', colorScheme),
                    _buildFutureItem(Icons.cloud_queue_outlined, 'Cloud rendering & storage', colorScheme),
                    _buildFutureItem(Icons.mic_none_outlined, 'Voice generation', colorScheme),
                    _buildFutureItem(Icons.file_download_outlined, 'More export formats', colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Footer Brand Links
        Center(
          child: Text(
            'Lanthic  •  Stories  •  Comics  •  Videos  •  More',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.5,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowStep(BuildContext context, String number, String title, String description) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildFlowArrow(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Icon(Icons.arrow_forward, size: 15, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
    );
  }

  Widget _buildCheckItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_rounded, size: 15, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureItem(IconData icon, String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
