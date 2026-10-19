import 'package:meta/meta.dart';
import 'continuity_model.dart';
import 'generation_manifest_model.dart';
import 'image_prompt_model.dart';
import 'project_manifest.dart';
import 'scene_model.dart';
import 'studio_models.dart';
import 'visual_direction_model.dart';
import 'visual_validation_model.dart';

/// Represents a diagnostic anomaly or structural observation flagged during
/// schema validation, YAML ingestion, or cross-phase continuity checks.
///
/// Flags are surfaced within the Studio UI to guide directors and writers on
/// pipeline inconsistencies (e.g. mismatched character outfits, missing prompts).
@immutable
class SceneValidationFlag {
  /// Constructs a [SceneValidationFlag].
  ///
  /// * [phase]: The pipeline phase identifier (e.g. `'visual_direction'`, `'scenes'`).
  /// * [message]: Human-readable description of the validation issue or notice.
  /// * [severity]: The impact level of the issue. Defaults to [FlagSeverity.warning].
  const SceneValidationFlag({
    required this.phase,
    required this.message,
    this.severity = FlagSeverity.warning,
  });

  /// The pipeline phase or schema category that originated this flag.
  final String phase;

  /// The diagnostic message explaining the condition.
  final String message;

  /// The severity classification determining UI rendering and pipeline blocking behavior.
  final FlagSeverity severity;
}

/// Categorizes the impact level of a [SceneValidationFlag].
enum FlagSeverity {
  /// Indicates non-fatal drift, optional metadata omissions, or visual warnings.
  warning,

  /// Indicates an invalid schema structure, missing required file, or unparseable syntax.
  error,

  /// Informational advisory with no negative operational impact.
  info,
}

/// Central Aggregate Root representing a unified scene across all narrative pipeline phases.
///
/// In Lanthic Studio, a story project is serialized across 8 decoupled YAML specifications
/// (Script, Beats, Visual Direction, Prompts, Manifest, Validation, Continuity, Approvals).
/// [AggregatedScene] joins these disparate domain fragments into a coherent, immutable entity
/// keyed by [sceneId].
///
/// ### Prompt Cascade
/// The [effectivePrompt] getter implements the studio's authoritative prompt cascade:
/// 1. If director approval has a manual [SceneApprovalItem.promptOverride], that override is used.
/// 2. Otherwise, the compiled [ImagePromptItem.prompt] is utilized.
/// 3. If no prompt item exists, fallback to [SceneModel.description].
/// In all cases, the prompt is cleaned by [ImagePromptItem.sanitizePrompt] to strip incompatible LoRA syntax.
@immutable
class AggregatedScene {
  /// Constructs an immutable [AggregatedScene] aggregate.
  const AggregatedScene({
    required this.sceneId,
    required this.sequence,
    required this.sceneModel,
    this.imagePrompt,
    this.visualDirection,
    this.validationRecord,
    this.approval,
    this.assetVersions = const [],
    this.flags = const [],
    this.dialogueBubbles = const [],
  });

  /// The canonical unique identifier for this scene (e.g., `'sc_001'`, `'sc_002'`).
  final String sceneId;

  /// Ordinal chronological index of the scene within the story timeline (1-indexed).
  final int sequence;

  /// Phase 1 & 2 Script and Narrative Beat specification (slugline, action, dialogue).
  final SceneModel sceneModel;

  /// Phase 4 compiled text prompt and provider-specific tuning parameters.
  final ImagePromptItem? imagePrompt;

  /// Phase 3 cinematography parameters (focal length, lighting, camera angle, color palette).
  final VisualDirectionModel? visualDirection;

  /// Phase 7 validation scores evaluating character continuity, style coherence, and composition.
  final VisualValidationRecord? validationRecord;

  /// Studio director sign-off status, prompt overrides, and review notes.
  final SceneApprovalItem? approval;

  /// Chronological history of generated visual assets for this scene on disk.
  final List<AssetVersionRecord> assetVersions;

  /// Accumulated diagnostic and schema flags associated with this scene.
  final List<SceneValidationFlag> flags;

  /// Lettering dialogue bubbles positioned over this scene's canvas.
  final List<DialogueBubble> dialogueBubbles;

  /// Computes the final prompt to dispatch to synthesis providers.
  ///
  /// Evaluates prompt overrides before falling back to compiled prompts or scene descriptions,
  /// followed by Automatic1111/ComfyUI LoRA tag sanitization.
  String get effectivePrompt {
    final raw = (approval?.promptOverride != null && approval!.promptOverride!.trim().isNotEmpty)
        ? approval!.promptOverride!
        : (imagePrompt?.prompt ?? sceneModel.description);
    return ImagePromptItem.sanitizePrompt(raw);
  }

  /// The director review status (e.g. [ApprovalStatus.pending], [ApprovalStatus.approved], [ApprovalStatus.needsRegen]).
  ApprovalStatus get status => approval?.status ?? ApprovalStatus.pending;

  /// The 1-based version number of the active asset selected by the director.
  ///
  /// Defaults to the latest available version in [assetVersions], or 1 if none exist.
  int get selectedVersion => approval?.selectedVersion ?? (assetVersions.isNotEmpty ? assetVersions.last.version : 1);

  /// Resolves the concrete [AssetVersionRecord] corresponding to [selectedVersion].
  ///
  /// Returns `null` if no image versions have been cooked for this scene.
  AssetVersionRecord? get currentAssetRecord {
    if (assetVersions.isEmpty) return null;
    for (final asset in assetVersions) {
      if (asset.version == selectedVersion) return asset;
    }
    return assetVersions.last;
  }

  /// Whether this scene carries any diagnostic flags either directly or in its validation record.
  bool get hasFlags => flags.isNotEmpty || (validationRecord != null && validationRecord!.flags.isNotEmpty);

  /// Creates a copy of this scene with specified attributes updated.
  AggregatedScene copyWith({
    SceneApprovalItem? approval,
    List<AssetVersionRecord>? assetVersions,
    List<SceneValidationFlag>? flags,
    List<DialogueBubble>? dialogueBubbles,
  }) {
    return AggregatedScene(
      sceneId: sceneId,
      sequence: sequence,
      sceneModel: sceneModel,
      imagePrompt: imagePrompt,
      visualDirection: visualDirection,
      validationRecord: validationRecord,
      approval: approval ?? this.approval,
      assetVersions: assetVersions ?? this.assetVersions,
      flags: flags ?? this.flags,
      dialogueBubbles: dialogueBubbles ?? this.dialogueBubbles,
    );
  }
}

/// The top-level root entity representing an entire narrative project loaded into memory.
///
/// Encapsulates the complete project hierarchy, including all [scenes], global
/// [continuity] rules, global [visualDirection], [generationManifest], and studio
/// layout and lettering models.
@immutable
class StoryProject {
  /// Constructs a [StoryProject] aggregate root.
  const StoryProject({
    required this.rootPath,
    required this.manifest,
    required this.canonicalStory,
    required this.scenes,
    required this.continuity,
    required this.visualDirection,
    required this.generationManifest,
    required this.visualValidation,
    required this.approvals,
    required this.layout,
    required this.lettering,
    this.projectFlags = const [],
  });

  /// Absolute filesystem path to the project root directory.
  final String rootPath;

  /// Project metadata (title, author, creation timestamp, schema versions).
  final ProjectManifest manifest;

  /// Raw markdown text of the canonical story source (`canonical_story.md`).
  final String canonicalStory;

  /// Ordered collection of joined [AggregatedScene] entities.
  final List<AggregatedScene> scenes;

  /// Global cross-scene character costume, lighting, and timeline continuity rules.
  final ContinuityModel continuity;

  /// Project-wide visual aesthetic, color grading, and lens specifications.
  final VisualDirectionModel visualDirection;

  /// Tracking manifest for all synthesized image assets and cooking statuses.
  final GenerationManifestModel generationManifest;

  /// Project-wide visual validation rules and scores.
  final VisualValidationModel visualValidation;

  /// Studio approval ledger recording director approvals, rejections, and prompt overrides.
  final StudioApprovalsModel approvals;

  /// Comic page panel geometry and layout arrangement.
  final StudioLayoutModel layout;

  /// Comic lettering balloons, typography, and speaker attributions.
  final StudioLetteringModel lettering;

  /// Global project-level diagnostic flags collected during repository load.
  final List<SceneValidationFlag> projectFlags;

  /// Looks up an [AggregatedScene] by its [sceneId].
  ///
  /// Returns `null` if no scene with the given ID exists in this project.
  AggregatedScene? sceneById(String id) {
    for (final s in scenes) {
      if (s.sceneId == id) return s;
    }
    return null;
  }

  /// Total count of scenes in this story.
  int get totalScenes => scenes.length;

  /// Total count of scenes marked as [ApprovalStatus.approved].
  int get approvedCount => scenes.where((s) => s.status == ApprovalStatus.approved).length;

  /// Total count of scenes marked as [ApprovalStatus.needsRegen].
  int get needsRegenCount => scenes.where((s) => s.status == ApprovalStatus.needsRegen).length;

  /// Total count of scenes with active diagnostic warnings or validation flags.
  int get flaggedCount => scenes.where((s) => s.hasFlags).length;
}
