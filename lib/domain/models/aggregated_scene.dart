import 'package:meta/meta.dart';
import 'continuity_model.dart';
import 'generation_manifest_model.dart';
import 'image_prompt_model.dart';
import 'project_manifest.dart';
import 'scene_model.dart';
import 'studio_models.dart';
import 'visual_direction_model.dart';
import 'visual_validation_model.dart';

@immutable
class SceneValidationFlag {
  const SceneValidationFlag({
    required this.phase,
    required this.message,
    this.severity = FlagSeverity.warning,
  });

  final String phase;
  final String message;
  final FlagSeverity severity;
}

enum FlagSeverity { warning, error, info }

@immutable
class AggregatedScene {
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

  final String sceneId;
  final int sequence;
  final SceneModel sceneModel;
  final ImagePromptItem? imagePrompt;
  final VisualDirectionModel? visualDirection;
  final VisualValidationRecord? validationRecord;
  final SceneApprovalItem? approval;
  final List<AssetVersionRecord> assetVersions;
  final List<SceneValidationFlag> flags;
  final List<DialogueBubble> dialogueBubbles;

  String get effectivePrompt {
    final raw = (approval?.promptOverride != null && approval!.promptOverride!.trim().isNotEmpty)
        ? approval!.promptOverride!
        : (imagePrompt?.prompt ?? sceneModel.description);
    return ImagePromptItem.sanitizePrompt(raw);
  }

  ApprovalStatus get status => approval?.status ?? ApprovalStatus.pending;

  int get selectedVersion => approval?.selectedVersion ?? (assetVersions.isNotEmpty ? assetVersions.last.version : 1);

  AssetVersionRecord? get currentAssetRecord {
    if (assetVersions.isEmpty) return null;
    for (final asset in assetVersions) {
      if (asset.version == selectedVersion) return asset;
    }
    return assetVersions.last;
  }

  bool get hasFlags => flags.isNotEmpty || (validationRecord != null && validationRecord!.flags.isNotEmpty);

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

@immutable
class StoryProject {
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

  final String rootPath;
  final ProjectManifest manifest;
  final String canonicalStory;
  final List<AggregatedScene> scenes;
  final ContinuityModel continuity;
  final VisualDirectionModel visualDirection;
  final GenerationManifestModel generationManifest;
  final VisualValidationModel visualValidation;
  final StudioApprovalsModel approvals;
  final StudioLayoutModel layout;
  final StudioLetteringModel lettering;
  final List<SceneValidationFlag> projectFlags;

  AggregatedScene? sceneById(String id) {
    for (final s in scenes) {
      if (s.sceneId == id) return s;
    }
    return null;
  }

  int get totalScenes => scenes.length;
  int get approvedCount => scenes.where((s) => s.status == ApprovalStatus.approved).length;
  int get needsRegenCount => scenes.where((s) => s.status == ApprovalStatus.needsRegen).length;
  int get flaggedCount => scenes.where((s) => s.hasFlags).length;
}
