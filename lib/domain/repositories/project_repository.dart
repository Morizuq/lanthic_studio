import '../models/aggregated_scene.dart';
import '../models/studio_models.dart';

/// Contract defining persistence operations for a Lanthic visual narrative project.
///
/// In Clean Architecture, this boundary decouples application orchestrators and UI
/// controllers from the concrete persistence mechanism (e.g., local disk YAML files,
/// cloud object storage, or SQLite).
///
/// Implementations must guarantee:
/// 1. Non-destructive asset writes (never overwrite previous versioned images).
/// 2. Atomic disk writes for manifest and studio files to guard against corruption.
/// 3. Cross-phase reconciliation by joining records keyed on `scene_id`.
abstract class ProjectRepository {
  /// Loads and synthesizes the complete [StoryProject] aggregate root from disk.
  ///
  /// Traverses and validates all 8 pipeline YAML files, loading assets and
  /// studio configurations located within [projectDirectoryPath].
  ///
  /// Throws [ProjectLoadFailure] if the project directory does not exist or if
  /// essential project manifest configurations cannot be parsed.
  Future<StoryProject> loadProject(String projectDirectoryPath);

  /// Persists director approval decisions, status changes, and prompt overrides
  /// to `studio/approvals.yaml` inside [projectDirectoryPath].
  Future<void> saveApprovals(String projectDirectoryPath, StudioApprovalsModel approvals);

  /// Persists comic page layout definitions and panel geometries to
  /// `studio/layout.yaml` inside [projectDirectoryPath].
  Future<void> saveLayout(String projectDirectoryPath, StudioLayoutModel layout);

  /// Persists dialogue lettering and balloon placements to
  /// `studio/lettering.yaml` inside [projectDirectoryPath].
  Future<void> saveLettering(String projectDirectoryPath, StudioLetteringModel lettering);

  /// Persists newly synthesized image bytes for [sceneId] using monotonic versioning.
  ///
  /// Saves the file to `assets/scenes/{sceneId}/scene_v{N}.{extension}` without
  /// overwriting existing versions, and returns the absolute or relative saved file path.
  Future<String> saveNewAssetVersion({
    required String projectDirectoryPath,
    required String sceneId,
    required List<int> imageBytes,
    required String extension,
  });

  /// Updates or appends an asset cooking record in `generation_manifest.yaml`.
  ///
  /// Ensures that version [version], [relativeFilePath], [promptHash], and [provider]
  /// metadata are atomically committed with write-locking to prevent race conditions.
  Future<void> recordAssetInManifest({
    required String projectDirectoryPath,
    required String sceneId,
    required int version,
    required String relativeFilePath,
    required String promptHash,
    required String provider,
    double costUsd = 0.0,
  });
}

