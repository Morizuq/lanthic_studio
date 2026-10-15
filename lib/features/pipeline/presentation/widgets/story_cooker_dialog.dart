import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/widgets/lanthic_logo.dart';
import '../../../project/providers/project_providers.dart';
import '../../domain/models/pipeline_run_progress.dart';
import '../providers/pipeline_cook_provider.dart';

class StoryCookerDialog extends ConsumerStatefulWidget {
  const StoryCookerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StoryCookerDialog(),
    );
  }

  @override
  ConsumerState<StoryCookerDialog> createState() => _StoryCookerDialogState();
}

class _StoryCookerDialogState extends ConsumerState<StoryCookerDialog> {
  final _titleController = TextEditingController(text: 'The Obsidian Horizon');
  final _storyController = TextEditingController(
    text: 'A wandering mechanic in a submerged coastal megacity encounters a decommissioned lighthouse emitting a strange, electric cyan signal into the rain-soaked fog. As she reaches the upper lantern chamber, the glass casing begins to reassemble itself from ancient shattered fragments...',
  );
  String _selectedProvider = 'qwen';
  bool _showSettings = false;

  final _githubPatController = TextEditingController();
  final _githubRepoController = TextEditingController(text: 'owner/lanthic-skills');
  final _localPathController = TextEditingController(text: '/Users/mac/Projects/lanthic-skills');

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    _githubPatController.dispose();
    _githubRepoController.dispose();
    _localPathController.dispose();
    super.dispose();
  }

  void _startCooking() {
    final title = _titleController.text.trim();
    final rawStory = _storyController.text.trim();
    if (title.isEmpty || rawStory.isEmpty) return;

    ref.read(pipelineCookNotifierProvider.notifier).cookStory(
          title: title,
          rawStory: rawStory,
          provider: _selectedProvider,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = ref.watch(pipelineCookNotifierProvider);

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, progress),
              const SizedBox(height: 20),
              Expanded(
                child: progress.isRunning || progress.isCompleted || progress.isFailed
                    ? _buildRunnerView(context, progress)
                    : (_showSettings ? _buildSettingsView(context) : _buildInputForm(context)),
              ),
              const SizedBox(height: 16),
              _buildFooter(context, progress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PipelineRunProgress progress) {
    return Row(
      children: [
        const LanthicLogo(size: 26, textSize: 16),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF00B8FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'STORY COOKER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00B8FF),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Spacer(),
        if (!progress.isRunning)
          IconButton(
            icon: Icon(
              _showSettings ? Icons.edit_note_rounded : Icons.tune_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: _showSettings ? 'Back to Story' : 'Skills Engine Settings',
            onPressed: () => setState(() => _showSettings = !_showSettings),
          ),
        if (!progress.isRunning)
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () {
              ref.read(pipelineCookNotifierProvider.notifier).reset();
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }

  Widget _buildInputForm(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Story Title & Concept',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'e.g. The Signature in the Lining',
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Raw Story / Concept / Outline',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Draft prose, bullet beats, or prompt seed',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _storyController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Paste your story seed, outline, or rough dialogue here...',
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Provider',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProvider,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      dropdownColor: colorScheme.surfaceContainerLow,
                      items: [
                        for (final prov in ref.watch(availableProvidersProvider))
                          DropdownMenuItem(
                            value: prov.providerIdentifier,
                            child: Row(
                              children: [
                                Icon(
                                  prov.isFreeOpenSource ? Icons.lock_open_outlined : Icons.speed_outlined,
                                  size: 14,
                                  color: prov.isFreeOpenSource ? const Color(0xFF00E5FF) : const Color(0xFF818CF8),
                                ),
                                const SizedBox(width: 8),
                                Text(prov.displayName),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedProvider = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skills Source Status',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<String>(
                      future: ref.read(skillsRepositoryProvider).getSourceDescription(),
                      builder: (context, snapshot) {
                        final desc = snapshot.data ?? 'Detecting...';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hub_rounded, size: 16, color: Color(0xFF00B8FF)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  desc,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lanthic Skills Engine Configuration',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Connect your local lanthic-skills repository or sync directly from your private GitHub repository.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text('Local Repository Path (Fastest / Zero Setup)',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _localPathController,
                  decoration: InputDecoration(
                    hintText: '/Users/mac/Projects/lanthic-skills',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(pipelineCookNotifierProvider.notifier)
                      .setLocalSkillsDirectory(_localPathController.text.trim());
                  setState(() => _showSettings = false);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurface,
                ),
                child: const Text('Save Path'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),
          Text('Private GitHub Repository Sync',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _githubRepoController,
            decoration: InputDecoration(
              labelText: 'GitHub Repository (owner/repo)',
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _githubPatController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'GitHub Personal Access Token (PAT with "repo" scope)',
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              try {
                await ref.read(pipelineCookNotifierProvider.notifier).syncRemoteSkills(
                      githubPat: _githubPatController.text.trim(),
                      repositoryOwnerAndName: _githubRepoController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully synced skills from private GitHub repository!')),
                  );
                  setState(() => _showSettings = false);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('GitHub sync error: $e'), backgroundColor: Colors.red.shade800),
                  );
                }
              }
            },
            icon: const Icon(Icons.cloud_download_rounded, size: 18),
            label: const Text('Sync Skills From GitHub'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00B8FF),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunnerView(BuildContext context, PipelineRunProgress progress) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final phases = [
      '01 Storytelling',
      '02 Scene Extraction',
      '03 Continuity',
      '04 Visual Direction',
      '05 Prompt Synthesis',
      '06 Provider Adapter',
      '07 Asset Registry',
      '08 Vision Audit',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepper
        SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.isCompleted
                    ? '🎉 Pipeline Succeeded'
                    : (progress.isFailed ? '⚠️ Pipeline Failed' : '⚡ Cooking Story...'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progress.isCompleted ? const Color(0xFF10B981) : const Color(0xFF00B8FF),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: phases.length,
                  itemBuilder: (context, index) {
                    final phaseNum = index + 1;
                    final isDone = progress.currentPhase > phaseNum || progress.isCompleted;
                    final isCurrent = progress.currentPhase == phaseNum && progress.isRunning;

                    Color circleColor = colorScheme.surfaceContainerHighest;
                    Color textColor = colorScheme.onSurfaceVariant;
                    Widget icon = Text('$phaseNum', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold));

                    if (isDone) {
                      circleColor = const Color(0xFF10B981);
                      textColor = colorScheme.onSurface;
                      icon = const Icon(Icons.check, size: 13, color: Colors.white);
                    } else if (isCurrent) {
                      circleColor = const Color(0xFF00B8FF);
                      textColor = const Color(0xFF00B8FF);
                      icon = const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: circleColor,
                              shape: BoxShape.circle,
                            ),
                            child: icon,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              phases[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Live Log Terminal
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal_rounded, size: 15, color: Color(0xFF00B8FF)),
                    const SizedBox(width: 8),
                    const Text('Execution Logs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${progress.logs.length} events',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    itemCount: progress.logs.length,
                    reverse: true,
                    itemBuilder: (context, idx) {
                      final log = progress.logs[progress.logs.length - 1 - idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log.message,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Courier',
                            color: log.isError ? Colors.redAccent : Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, PipelineRunProgress progress) {
    if (progress.isCompleted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {
              ref.read(pipelineCookNotifierProvider.notifier).reset();
            },
            child: const Text('Cook Another'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {
              ref.read(projectStateNotifierProvider.notifier).openProject(progress.projectDirectory);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: const Text('Open in Studio Workstation →'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00B8FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      );
    }

    if (progress.isRunning) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _startCooking,
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: const Text('Cook Story (Run Pipeline)'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00B8FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
