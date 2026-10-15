import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/asset_file_helper.dart';
import '../../../domain/models/aggregated_scene.dart';
import '../../review/widgets/image_lightbox_dialog.dart';

class ComicReaderView extends StatefulWidget {
  const ComicReaderView({
    super.key,
    required this.scenes,
    required this.projectRoot,
  });

  final List<AggregatedScene> scenes;
  final String projectRoot;

  @override
  State<ComicReaderView> createState() => _ComicReaderViewState();
}

class _ComicReaderViewState extends State<ComicReaderView> {
  int _columns = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scenes = widget.scenes;

    if (scenes.isEmpty) {
      return const Center(child: Text('No scenes available to preview'));
    }

    return Column(
      children: [
        // Reader toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Text(
                'Sequential Comic Reader',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${scenes.length} PANELS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              const Text('Layout: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              IconButton(
                tooltip: '1 Column (Webtoon / Continuous)',
                icon: Icon(Icons.view_agenda_outlined, color: _columns == 1 ? colorScheme.primary : null),
                onPressed: () => setState(() => _columns = 1),
              ),
              IconButton(
                tooltip: '2 Columns (Graphic Novel Grid)',
                icon: Icon(Icons.grid_view_outlined, color: _columns == 2 ? colorScheme.primary : null),
                onPressed: () => setState(() => _columns = 2),
              ),
            ],
          ),
        ),

        // Panels Grid / List
        Expanded(
          child: _columns == 1
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  itemCount: scenes.length,
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    return _buildPanelCard(context, scene, maxWidth: 800);
                  },
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: scenes.length,
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    return _buildPanelCard(context, scene);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPanelCard(BuildContext context, AggregatedScene scene, {double? maxWidth}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentAsset = scene.currentAssetRecord;

    final File? imageFile;
    if (currentAsset != null) {
      imageFile = File(p.join(widget.projectRoot, currentAsset.filePath));
    } else {
      imageFile = null;
    }

    Widget content = Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel Image with speech bubble overlays
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (imageFile != null && imageFile.existsSync()) {
                  ImageLightboxDialog.show(
                    context,
                    imageFile: imageFile,
                    title: 'Scene #${scene.sequence}: ${scene.sceneId}',
                    subtitle: scene.sceneModel.title,
                  );
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: AssetFileHelper.isRealRenderedAsset(imageFile)
                        ? Image.file(
                            imageFile!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, size: 40, color: colorScheme.outline),
                                const SizedBox(height: 6),
                                Text('Scene #${scene.sequence} Unrendered', style: theme.textTheme.labelMedium),
                              ],
                            ),
                          ),
                  ),

                  // Panel index banner
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${scene.sequence}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // Dialogue overlay bubbles
                  if (scene.sceneModel.dialogue.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: scene.sceneModel.dialogue.map((d) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black87, fontSize: 11),
                                children: [
                                  TextSpan(
                                    text: '${d.speaker}: ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: d.text),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Panel description footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    scene.sceneModel.title.isNotEmpty ? scene.sceneModel.title : scene.sceneId,
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'v${scene.selectedVersion}',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(
            height: 480,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
