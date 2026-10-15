import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../../pipeline/presentation/widgets/story_cooker_dialog.dart';
import 'studio_flow_section.dart';

class ProjectEmptyView extends ConsumerStatefulWidget {
  const ProjectEmptyView({super.key});

  @override
  ConsumerState<ProjectEmptyView> createState() => _ProjectEmptyViewState();
}

class _ProjectEmptyViewState extends ConsumerState<ProjectEmptyView> {
  bool _isDragging = false;

  Future<void> _pickDirectory() async {
    try {
      if (Platform.isMacOS) {
        await FilePicker.skipEntitlementsChecks();
      }
      final selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Lanthic Skills Project Folder',
      );

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        ref.read(projectStateNotifierProvider.notifier).openProject(selectedDirectory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker notice: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  String? _findProjectDirectory(String relativePath) {
    final cwd = Directory.current.path;
    final candidates = [
      '$cwd/$relativePath',
      '/Users/mac/Projects/lanthic_studio/$relativePath',
    ];

    try {
      var dir = File(Platform.resolvedExecutable).parent;
      for (int i = 0; i < 8; i++) {
        candidates.add('${dir.path}/$relativePath');
        dir = dir.parent;
      }
    } catch (_) {}

    for (final path in candidates) {
      if (Directory(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  void _loadSampleProject(String fixturePath) {
    final foundPath = _findProjectDirectory(fixturePath);

    if (foundPath != null) {
      ref.read(projectStateNotifierProvider.notifier).openProject(foundPath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fixture folder not found at candidate paths. Please click "Browse Project Folder..." to select your folder.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ingestion Row (Dropzone + Quick Starters)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 720;
                  if (isCompact) {
                    return Column(
                      children: [
                        _buildDropzone(theme, colorScheme),
                        const SizedBox(height: 24),
                        _buildQuickStartStories(theme, colorScheme),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildDropzone(theme, colorScheme),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: _buildQuickStartStories(theme, colorScheme),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),

              // Studio Flow Section (Mockup Bottom Deck)
              const StudioFlowSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropzone(ThemeData theme, ColorScheme colorScheme) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          ref.read(projectStateNotifierProvider.notifier).openProject(details.files.first.path);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _isDragging
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: _isDragging
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF00B8FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B8FF).withValues(alpha: 0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/lanthic_lantern_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.wb_incandescent_rounded,
                  size: 28,
                  color: Color(0xFF00B8FF),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Open Skills Engine Project',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Drop any lanthic-skills pipeline folder here,\nor browse your local file system.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => StoryCookerDialog.show(context),
                  icon: const Icon(Icons.bolt_rounded, size: 19),
                  label: const Text('Cook New Story'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00B8FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickDirectory,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Browse Project Folder...'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _buildPhaseChip('01 Story', colorScheme),
                _buildPhaseChip('02 Scenes', colorScheme),
                _buildPhaseChip('03 Continuity', colorScheme),
                _buildPhaseChip('04 Directives', colorScheme),
                _buildPhaseChip('05 Prompts', colorScheme),
                _buildPhaseChip('07 Assets', colorScheme),
                _buildPhaseChip('08 Audit', colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartStories(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick-Start Stories',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildStoryCard(
          title: 'The Signature in the Lining',
          badge: 'PIPELINE • GOLDEN MASTER',
          badgeColor: const Color(0xFFE28B47),
          description:
              'West African historical beat. Patriarch inspects the groom\'s robe, exposing Bassey\'s hidden indigo chain-stitch.',
          stats: '2 Scenes • FLUX 1.1 Pro • Vision Validated',
          buttonLabel: 'Explore Master →',
          onTap: () => _loadSampleProject('test/fixtures/the_signature_in_the_lining'),
          theme: theme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildStoryCard(
          title: 'Deep Orbit Protocol',
          badge: 'SCI-FI THRILLER',
          badgeColor: const Color(0xFF00B8FF),
          description:
              'Tactical space station stealth infiltration beat with dialogue lettering and character continuity.',
          stats: '2 Scenes • Cyberpunk • Dialogue Overlay',
          buttonLabel: 'Load Sample Project',
          onTap: () => _loadSampleProject('test/fixtures/sample_story'),
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildStoryCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required String stats,
    required String buttonLabel,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 14, color: colorScheme.primary),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.layers_outlined, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      stats,
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    buttonLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseChip(String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
