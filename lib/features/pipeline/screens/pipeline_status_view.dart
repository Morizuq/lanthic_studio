import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../domain/models/aggregated_scene.dart';

class PipelineStatusView extends StatelessWidget {
  const PipelineStatusView({
    super.key,
    required this.project,
  });

  final StoryProject project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final phases = [
      _PhaseInfo(
        number: '01',
        name: 'Storytelling',
        file: 'canonical_story.md',
        description: 'Golden canonical narrative source text',
        statusSummary: '${project.canonicalStory.length} characters',
      ),
      _PhaseInfo(
        number: '02',
        name: 'Scene Extraction',
        file: 'scenes.yaml',
        description: 'Atomic visual beats & staging decomposition',
        statusSummary: '${project.scenes.length} scenes extracted',
      ),
      _PhaseInfo(
        number: '03',
        name: 'Entity Continuity',
        file: 'continuity.yaml',
        description: 'Persistent physical identity, invariants & scene states',
        statusSummary: '${project.continuity.characters.length} characters, ${project.continuity.objects.length} objects',
      ),
      _PhaseInfo(
        number: '04',
        name: 'Visual Direction',
        file: 'visual_direction.yaml',
        description: 'Camera framing, angles, lighting & cultural context',
        statusSummary: project.visualDirection.style.isNotEmpty ? project.visualDirection.style : 'Global directives present',
      ),
      _PhaseInfo(
        number: '05',
        name: 'Prompt Synthesis',
        file: 'image_prompts.yaml',
        description: 'Compiled natural language descriptive prompts & negative constraints',
        statusSummary: '${project.scenes.where((s) => s.imagePrompt != null).length} compiled prompts',
      ),
      _PhaseInfo(
        number: '06',
        name: 'Provider Adapter',
        file: 'provider_request.yaml',
        description: 'API-specific parameter serialization & capability mapping',
        statusSummary: 'Target: ${project.manifest.provider}',
      ),
      _PhaseInfo(
        number: '07',
        name: 'Generation Dispatch',
        file: 'generation_manifest.yaml',
        description: 'Render asset version logging, seeds & execution metadata',
        statusSummary: '${project.generationManifest.records.length} asset versions rendered',
      ),
      _PhaseInfo(
        number: '08',
        name: 'Vision Validation',
        file: 'visual_validation.yaml',
        description: 'Automated multimodal audit: invariants, legibility & remediation',
        statusSummary: '${project.visualValidation.approvedCount} approved, ${project.visualValidation.rejectedCount} rejected',
      ),
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lanthic Skills Engine • Pipeline Architecture',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comprehensive health & artifact validation status across all 8 pipeline phases',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: project.projectFlags.isEmpty ? Colors.green.shade100 : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        project.projectFlags.isEmpty ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 16,
                        color: project.projectFlags.isEmpty ? Colors.green.shade900 : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        project.projectFlags.isEmpty
                            ? 'ALL SCHEMAS VALID'
                            : '${project.projectFlags.length} SCHEMA WARNINGS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: project.projectFlags.isEmpty ? Colors.green.shade900 : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Schema Flags Banner if any
            if (project.projectFlags.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schema Warning Diagnostics (Non-blocking):',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                    const SizedBox(height: 6),
                    ...project.projectFlags.map((f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• [${f.phase}] ${f.message}', style: const TextStyle(fontSize: 12)),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Pipeline Grid Cards
            ...phases.map((phase) {
              final filePath = p.join(project.rootPath, phase.file);
              final exists = File(filePath).existsSync();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            phase.number,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(phase.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(phase.description, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(phase.file, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: colorScheme.primary)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(phase.statusSummary, style: theme.textTheme.bodySmall),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: exists ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exists ? 'FOUND' : 'MISSING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: exists ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PhaseInfo {
  const _PhaseInfo({
    required this.number,
    required this.name,
    required this.file,
    required this.description,
    required this.statusSummary,
  });

  final String number;
  final String name;
  final String file;
  final String description;
  final String statusSummary;
}
