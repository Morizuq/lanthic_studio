import 'package:flutter/material.dart';
import '../../../domain/models/aggregated_scene.dart';

class ContinuityExplorerView extends StatelessWidget {
  const ContinuityExplorerView({
    super.key,
    required this.project,
  });

  final StoryProject project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final continuity = project.continuity;

    return Row(
      children: [
        // Left Column: Canonical Story Markdown
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phase 01: Canonical Story (canonical_story.md)',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        project.canonicalStory.isNotEmpty
                            ? project.canonicalStory
                            : 'No canonical_story.md found in project root.',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Column: Continuity Model (Phase 03)
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fingerprint_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phase 03: Entity Continuity (continuity.yaml)',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      // Characters Section
                      Text('Characters (${continuity.characters.length})',
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (continuity.characters.isEmpty)
                        Text('No characters parsed', style: theme.textTheme.bodySmall)
                      else
                        ...continuity.characters.map((c) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            c.id,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(c.type, style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
                                      ],
                                    ),
                                    if (c.identity.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ...c.identity.entries.map((entry) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${entry.key}: ',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                Expanded(
                                                    child: Text(entry.value.toString(),
                                                        style: const TextStyle(fontSize: 12))),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ],
                                ),
                              ),
                            )),
                      const SizedBox(height: 16),

                      // Objects Section
                      Text('Objects (${continuity.objects.length})',
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (continuity.objects.isEmpty)
                        Text('No tracked objects parsed', style: theme.textTheme.bodySmall)
                      else
                        ...continuity.objects.map((o) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(o.id,
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    if (o.identity.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      ...o.identity.entries.map((entry) => Text(
                                            '${entry.key}: ${entry.value}',
                                            style: const TextStyle(fontSize: 12),
                                          )),
                                    ],
                                  ],
                                ),
                              ),
                            )),
                      const SizedBox(height: 16),

                      // Constraints Section
                      Text('Continuity Invariant Rules (${continuity.constraints.length})',
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (continuity.constraints.isEmpty)
                        Text('No explicit constraints parsed', style: theme.textTheme.bodySmall)
                      else
                        ...continuity.constraints.map((c) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.shield_outlined, size: 16, color: Colors.blueGrey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${c.entity}: ${c.rule}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
