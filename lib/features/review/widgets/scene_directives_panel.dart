import 'package:flutter/material.dart';
import '../../../domain/models/aggregated_scene.dart';
import '../../../domain/models/visual_validation_model.dart';

class SceneDirectivesPanel extends StatefulWidget {
  const SceneDirectivesPanel({
    super.key,
    required this.scene,
    required this.promptController,
    required this.isRegenerating,
    required this.regenError,
    required this.onRegenerate,
  });

  final AggregatedScene scene;
  final TextEditingController promptController;
  final bool isRegenerating;
  final String? regenError;
  final VoidCallback onRegenerate;

  @override
  State<SceneDirectivesPanel> createState() => _SceneDirectivesPanelState();
}

class _SceneDirectivesPanelState extends State<SceneDirectivesPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Prompt & Overrides'),
            Tab(icon: Icon(Icons.movie_filter_outlined, size: 18), text: 'Visual Direction'),
            Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: 'Vision Audit'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Lettering & Dialogue'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 380,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPromptTab(theme, colorScheme),
              _buildVisualDirectionTab(theme, colorScheme),
              _buildVisionAuditTab(theme, colorScheme),
              _buildLetteringTab(theme, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptTab(ThemeData theme, ColorScheme colorScheme) {
    final scene = widget.scene;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Base Engine Prompt (Phase 5: image_prompts.yaml)',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: SelectableText(
              scene.imagePrompt?.prompt ?? scene.sceneModel.description,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Prompt Override (Saved in studio/approvals.yaml)',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.promptController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Adjust prompt to fix details without mutating engine files...',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: widget.isRegenerating ? null : widget.onRegenerate,
                icon: widget.isRegenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(widget.isRegenerating ? 'Calling Provider...' : 'Regenerate Scene'),
              ),
              if (widget.regenError != null)
                Text(
                  widget.regenError!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualDirectionTab(ThemeData theme, ColorScheme colorScheme) {
    final scene = widget.scene;
    final sceneOverrides = scene.visualDirection?.sceneOverrides[scene.sceneId] ?? {};
    final globalStyle = scene.visualDirection?.style ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (globalStyle.isNotEmpty) ...[
            Text('Global Style / Cultural Context:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(globalStyle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
          ],
          if (sceneOverrides.isEmpty)
            Text('No specific scene overrides declared in visual_direction.yaml', style: theme.textTheme.bodySmall)
          else ...[
            Text('Scene Directives (Phase 4):', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...sceneOverrides.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildVisionAuditTab(ThemeData theme, ColorScheme colorScheme) {
    final scene = widget.scene;
    final record = scene.validationRecord;

    if (record == null) {
      return Center(
        child: Text('No Phase 8 visual validation record found for this scene.', style: theme.textTheme.bodySmall),
      );
    }

    final isPass = record.verdict == ValidationVerdict.pass;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPass ? Colors.green.shade100 : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPass ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 16,
                  color: isPass ? Colors.green.shade900 : Colors.amber.shade900,
                ),
                const SizedBox(width: 6),
                Text(
                  'VERDICT: ${record.verdict.name.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isPass ? Colors.green.shade900 : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          if (record.critique.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Critique Summary:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(record.critique, style: theme.textTheme.bodySmall),
          ],
          if (record.flags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Flags & Evaluations:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...record.flags.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Expanded(child: Text(f, style: theme.textTheme.bodySmall)),
                    ],
                  ),
                )),
          ],
          if (record.remediationGuidance != null && record.remediationGuidance!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remediation Advice:', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(record.remediationGuidance!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLetteringTab(ThemeData theme, ColorScheme colorScheme) {
    final scene = widget.scene;
    final dialogue = scene.sceneModel.dialogue;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Dialogue Lines (${dialogue.length})', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('Lettering schema: studio_lettering.yaml', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          if (dialogue.isEmpty)
            Text('No dialogue in this scene.', style: theme.textTheme.bodySmall)
          else
            ...dialogue.map((d) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            d.speaker,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text('"${d.text}"', style: theme.textTheme.bodySmall)),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
