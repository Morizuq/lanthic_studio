import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanthic_studio/shared/design_system/tokens/app_spacing.dart';
import '../../../core/theme/theme_mode_notifier.dart';
import '../../../shared/design_system/widgets/lanthic_logo.dart';
import '../../pipeline/presentation/widgets/story_cooker_dialog.dart';
import '../providers/project_providers.dart';

class StudioHeaderBar extends ConsumerWidget implements PreferredSizeWidget {
  const StudioHeaderBar({
    super.key,
    required this.onOpenFolder,
    required this.onShowApiKeys,
    required this.onExport,
    this.onToggleLeftPanel,
    this.onToggleRightPanel,
    this.isLeftPanelVisible = true,
    this.isRightPanelVisible = true,
  });

  final VoidCallback onOpenFolder;
  final VoidCallback onShowApiKeys;
  final VoidCallback onExport;
  final VoidCallback? onToggleLeftPanel;
  final VoidCallback? onToggleRightPanel;
  final bool isLeftPanelVisible;
  final bool isRightPanelVisible;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectAsync = ref.watch(projectStateNotifierProvider);
    final activeViewMode = ref.watch(studioViewModeProvider);

    final windowWidth = MediaQuery.sizeOf(context).width;
    final isCompactWidth = windowWidth < 1320;
    final isVeryCompact = windowWidth < 1450;
    final isNarrow = windowWidth < 980;
    final isUltraCompact = windowWidth < 740;

    return AppBar(
      centerTitle: false,
      titleSpacing: 8,
      toolbarHeight: 56,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: colorScheme.outlineVariant, height: 1),
      ),
      leadingWidth: 68,
      leading: AppSpacing.vM,
      title: ClipRect(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LanthicLogo(size: 24, textSize: 14),
              projectAsync.maybeWhen(
                data: (project) {
                  if (project == null || isUltraCompact) {
                    return const SizedBox.shrink();
                  }
                  final title = project.manifest.title.isNotEmpty
                      ? project.manifest.title
                      : project.manifest.storyId;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          project.manifest.provider.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (projectAsync.value != null) ...[
          if (isNarrow)
            PopupMenuButton<StudioViewMode>(
              tooltip: 'Switch Studio View',
              icon: Icon(
                switch (activeViewMode) {
                  StudioViewMode.review => Icons.space_dashboard_outlined,
                  StudioViewMode.graph => Icons.hub_outlined,
                  StudioViewMode.reader => Icons.auto_stories_outlined,
                  StudioViewMode.continuity => Icons.fingerprint_outlined,
                  StudioViewMode.pipeline => Icons.account_tree_outlined,
                },
                size: 18,
                color: const Color(0xFF00E5FF),
              ),
              onSelected: (mode) {
                ref.read(studioViewModeProvider.notifier).setMode(mode);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: StudioViewMode.review,
                  child: Row(
                    children: [
                      Icon(Icons.space_dashboard_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Review Mode'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: StudioViewMode.graph,
                  child: Row(
                    children: [
                      Icon(Icons.hub_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Node Pipeline'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: StudioViewMode.reader,
                  child: Row(
                    children: [
                      Icon(Icons.auto_stories_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Reader'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: StudioViewMode.continuity,
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Continuity'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: StudioViewMode.pipeline,
                  child: Row(
                    children: [
                      Icon(Icons.account_tree_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Pipeline'),
                    ],
                  ),
                ),
              ],
            )
          else
            SegmentedButton<StudioViewMode>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                side: WidgetStateProperty.all(BorderSide.none),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.primary.withValues(alpha: 0.18);
                  }
                  return Colors.transparent;
                }),
              ),
              segments: [
                ButtonSegment(
                  value: StudioViewMode.review,
                  icon: const Icon(Icons.space_dashboard_outlined, size: 14),
                  label: isCompactWidth ? null : const Text('Review'),
                  tooltip: 'Review Mode',
                ),
                ButtonSegment(
                  value: StudioViewMode.graph,
                  icon: const Icon(Icons.hub_outlined, size: 14),
                  label: isCompactWidth ? null : const Text('Graph'),
                  tooltip: 'Node Animation Pipeline',
                ),
                ButtonSegment(
                  value: StudioViewMode.reader,
                  icon: const Icon(Icons.auto_stories_outlined, size: 14),
                  label: isCompactWidth ? null : const Text('Reader'),
                  tooltip: 'Reader Mode',
                ),
                ButtonSegment(
                  value: StudioViewMode.continuity,
                  icon: const Icon(Icons.fingerprint_outlined, size: 14),
                  label: isCompactWidth ? null : const Text('Continuity'),
                  tooltip: 'Continuity Explorer',
                ),
                ButtonSegment(
                  value: StudioViewMode.pipeline,
                  icon: const Icon(Icons.account_tree_outlined, size: 14),
                  label: isCompactWidth ? null : const Text('Pipeline'),
                  tooltip: 'Pipeline Status',
                ),
              ],
              selected: {activeViewMode},
              onSelectionChanged: (newSelection) {
                ref
                    .read(studioViewModeProvider.notifier)
                    .setMode(newSelection.first);
              },
            ),
          const SizedBox(width: 6),
          if (isUltraCompact)
            IconButton(
              tooltip: 'Export Project',
              icon: const Icon(
                Icons.file_upload_outlined,
                size: 18,
                color: Color(0xFF00B8FF),
              ),
              onPressed: onExport,
            )
          else
            FilledButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.file_upload_outlined, size: 14),
              label: const Text('Export'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00B8FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
        if (projectAsync.value != null &&
            activeViewMode == StudioViewMode.review) ...[
          IconButton(
            tooltip: isLeftPanelVisible
                ? 'Collapse Left Sidebar'
                : 'Expand Left Sidebar',
            icon: Icon(
              Icons.view_sidebar_outlined,
              size: 18,
              color: isLeftPanelVisible
                  ? const Color(0xFF00B8FF)
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: onToggleLeftPanel,
          ),
          IconButton(
            tooltip: isRightPanelVisible
                ? 'Collapse Inspector'
                : 'Expand Inspector',
            icon: Icon(
              Icons.vertical_split_outlined,
              size: 18,
              color: isRightPanelVisible
                  ? const Color(0xFF00B8FF)
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: onToggleRightPanel,
          ),
        ],
        IconButton(
          tooltip: 'Cook New Story',
          icon: const Icon(
            Icons.bolt_rounded,
            size: 19,
            color: Color(0xFF00B8FF),
          ),
          onPressed: () => StoryCookerDialog.show(context),
        ),
        if (isVeryCompact)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, size: 19),
            tooltip: 'More Options',
            color: colorScheme.surfaceContainerLow,
            onSelected: (val) {
              switch (val) {
                case 'open':
                  onOpenFolder();
                  break;
                case 'keys':
                  onShowApiKeys();
                  break;
                case 'theme':
                  ref.read(themeModeProvider.notifier).toggleTheme();
                  break;
                case 'close':
                  ref
                      .read(projectStateNotifierProvider.notifier)
                      .resetToEmpty();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.folder_open, size: 16),
                    SizedBox(width: 8),
                    Text('Open Project Folder'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'keys',
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Provider API Keys'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      theme.brightness == Brightness.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('Toggle Dark/Light Mode'),
                  ],
                ),
              ),
              if (projectAsync.value != null) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(Icons.close, size: 16, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Close Project'),
                    ],
                  ),
                ),
              ],
            ],
          )
        else ...[
          IconButton(
            tooltip: 'Open Project Folder',
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            onPressed: onOpenFolder,
          ),
          IconButton(
            tooltip: 'Provider API Keys',
            icon: const Icon(Icons.vpn_key_outlined, size: 18),
            onPressed: onShowApiKeys,
          ),
          IconButton(
            tooltip: 'Toggle Dark/Light Mode',
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 18,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          if (projectAsync.value != null)
            IconButton(
              tooltip: 'Close Project',
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => ref
                  .read(projectStateNotifierProvider.notifier)
                  .resetToEmpty(),
            ),
        ],
        const SizedBox(width: 6),
      ],
    );
  }
}
