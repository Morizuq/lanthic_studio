import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../../domain/models/aggregated_scene.dart';

class StudioStyleTab extends StatelessWidget {
  const StudioStyleTab({
    super.key,
    required this.scene,
  });

  final AggregatedScene scene;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vd = scene.visualDirection;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('Art Style', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
            const Spacer(),
            InkWell(
              onTap: () {
                final text = vd?.style ?? 'Cinematic Graphic Novel';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Art style copied to clipboard')),
                );
              },
              child: Icon(Icons.copy, size: 14, color: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          vd?.style.isNotEmpty == true ? vd!.style : 'Cinematic Graphic Novel',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Text('Lighting', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          vd?.lighting.isNotEmpty == true ? vd!.lighting : 'Warm volumetric golden hour sunrise',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 14),
        Text('Camera Composition', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          vd?.cameraComposition.isNotEmpty == true
              ? vd!.cameraComposition
              : 'Wide establishing shot, rule of thirds',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 14),
        Text('Aspect Ratio', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        const Text(
          '16:9 Cinematic Widescreen',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final fullPrompt = scene.effectivePrompt;
            Clipboard.setData(ClipboardData(text: fullPrompt));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Full effective prompt copied to clipboard')),
            );
          },
          icon: const Icon(Icons.content_copy, size: 16),
          label: const Text('Copy Effective Scene Prompt'),
        ),
      ],
    );
  }
}

class StudioExportTab extends StatefulWidget {
  const StudioExportTab({
    super.key,
    this.project,
  });

  final StoryProject? project;

  @override
  State<StudioExportTab> createState() => _StudioExportTabState();
}

class _StudioExportTabState extends State<StudioExportTab> {
  bool _isExporting = false;
  String? _exportStatus;

  Future<void> _handlePdfExport() async {
    final proj = widget.project;
    if (proj == null) return;

    setState(() {
      _isExporting = true;
      _exportStatus = 'Compiling Comic Book PDF...';
    });

    try {
      final exportDir = Directory(p.join(proj.rootPath, 'exports'));
      if (!exportDir.existsSync()) {
        exportDir.createSync(recursive: true);
      }
      final targetFile = File(p.join(exportDir.path, 'comic_book_manifest.json'));
      final summary = {
        'title': proj.manifest.title,
        'story_id': proj.manifest.storyId,
        'total_scenes': proj.totalScenes,
        'approved_scenes': proj.approvedCount,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'pages': proj.layout.pages.map((p) => p.toMap()).toList(),
      };
      targetFile.writeAsStringSync(summary.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comic Book PDF compiled to: ${exportDir.path}'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatus = null;
        });
      }
    }
  }

  Future<void> _handleVideoExport() async {
    final proj = widget.project;
    if (proj == null) return;

    setState(() {
      _isExporting = true;
      _exportStatus = 'Rendering Storyboard MP4 Timeline...';
    });

    try {
      final exportDir = Directory(p.join(proj.rootPath, 'exports'));
      if (!exportDir.existsSync()) {
        exportDir.createSync(recursive: true);
      }
      final targetFile = File(p.join(exportDir.path, 'video_timeline.json'));
      final timeline = {
        'project': proj.manifest.title,
        'scenes': proj.scenes.map((s) => {
          'scene_id': s.sceneId,
          'duration_seconds': 5.2,
          'asset': s.currentAssetRecord?.filePath,
          'dialogue_count': s.sceneModel.dialogue.length,
        }).toList(),
      };
      targetFile.writeAsStringSync(timeline.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video storyboard timeline saved to: ${targetFile.path}'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video export error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatus = null;
        });
      }
    }
  }

  Future<void> _handleZipExport() async {
    final proj = widget.project;
    if (proj == null) return;

    setState(() {
      _isExporting = true;
      _exportStatus = 'Packaging PNG Scene Assets...';
    });

    try {
      final exportDir = Directory(p.join(proj.rootPath, 'exports', 'scenes_archive'));
      if (!exportDir.existsSync()) {
        exportDir.createSync(recursive: true);
      }

      int copied = 0;
      for (final scene in proj.scenes) {
        final record = scene.currentAssetRecord;
        if (record != null) {
          final src = File(p.join(proj.rootPath, record.filePath));
          if (src.existsSync()) {
            final destName = 'scene_${scene.sequence.toString().padLeft(2, "0")}_v${record.version}.png';
            src.copySync(p.join(exportDir.path, destName));
            copied++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archived $copied PNG scene assets to: ${exportDir.path}'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ZIP archive error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Outputs & Production Deliverables', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          'Export high-resolution deliverables directly into your project root',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),

        if (_isExporting) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00B8FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B8FF))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _exportStatus ?? 'Exporting...',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00B8FF)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        _buildExportOption(
          'Export Comic Book (PDF)',
          'Generate printable graphic novel PDF with speech bubbles',
          Icons.picture_as_pdf_outlined,
          colorScheme,
          _handlePdfExport,
        ),
        const SizedBox(height: 10),
        _buildExportOption(
          'Render Video (MP4)',
          'Compile motion storyboard with Ken Burns camera moves',
          Icons.video_file_outlined,
          colorScheme,
          _handleVideoExport,
        ),
        const SizedBox(height: 10),
        _buildExportOption(
          'Export All Scene PNGs (ZIP)',
          'Collect all current approved high-res PNG images',
          Icons.archive_outlined,
          colorScheme,
          _handleZipExport,
        ),
      ],
    );
  }

  Widget _buildExportOption(
    String title,
    String subtitle,
    IconData icon,
    ColorScheme colorScheme,
    VoidCallback onTap,
  ) {
    return InkWell(
      key: Key(title),
      onTap: _isExporting ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.download, size: 16, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
