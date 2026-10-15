import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/errors/failures.dart';
import '../../domain/models/aggregated_scene.dart';
import '../../domain/models/continuity_model.dart';
import '../../domain/models/generation_manifest_model.dart';
import '../../domain/models/image_prompt_model.dart';
import '../../domain/models/project_manifest.dart';
import '../../domain/models/scene_model.dart';
import '../../domain/models/studio_models.dart';
import '../../domain/models/visual_direction_model.dart';
import '../../domain/models/visual_validation_model.dart';
import '../../domain/repositories/project_repository.dart';
import '../yaml/phase_yaml_reader.dart';
import '../yaml/schema_registry.dart';
import '../yaml/studio_yaml_writer.dart';

class DiskProjectRepository implements ProjectRepository {
  DiskProjectRepository({
    required SchemaRegistry schemaRegistry,
    PhaseYamlReader? yamlReader,
    StudioYamlWriter? yamlWriter,
  })  : _schemaRegistry = schemaRegistry,
        _yamlReader = yamlReader ?? PhaseYamlReader(schemaRegistry: schemaRegistry),
        _yamlWriter = yamlWriter ?? const StudioYamlWriter();

  final SchemaRegistry _schemaRegistry;
  final PhaseYamlReader _yamlReader;
  final StudioYamlWriter _yamlWriter;

  @override
  Future<StoryProject> loadProject(String projectDirectoryPath) async {
    final rootDir = Directory(projectDirectoryPath);
    if (!await rootDir.exists()) {
      throw ProjectLoadFailure(
        'Project directory does not exist: $projectDirectoryPath',
      );
    }

    await _schemaRegistry.initialize(
      customSchemasDir: p.join(projectDirectoryPath, 'schemas'),
    );

    final projectFlags = <SceneValidationFlag>[];

    // 1. Read project.yaml
    final manifestPath = p.join(projectDirectoryPath, 'project.yaml');
    final manifestRes = await _yamlReader.readAndValidateFile(
      filePath: manifestPath,
      schemaKey: 'project',
      isRequired: false,
    );
    projectFlags.addAll(manifestRes.flags);

    final ProjectManifest manifest;
    if (manifestRes.data != null) {
      manifest = ProjectManifest.fromMap(manifestRes.data!);
    } else {
      final dirName = p.basename(projectDirectoryPath);
      manifest = ProjectManifest(
        schemaVersion: '1.0.0',
        storyId: dirName,
        runId: 'run_local',
        provider: 'flux',
        title: dirName.replaceAll('_', ' '),
      );
    }

    // 2. Read canonical_story.md
    final storyPath = p.join(projectDirectoryPath, 'canonical_story.md');
    final storyFile = File(storyPath);
    final canonicalStory = await storyFile.exists() ? await storyFile.readAsString() : '';

    // 3. Read scenes.yaml
    final scenesRes = await _yamlReader.readAndValidateFile(
      filePath: p.join(projectDirectoryPath, manifest.files['scenes'] ?? 'scenes.yaml'),
      schemaKey: 'scenes',
      isRequired: true,
    );
    projectFlags.addAll(scenesRes.flags);
    final rawScenes = scenesRes.data?['scenes'] ?? scenesRes.data;
    final sceneModels = <SceneModel>[];
    if (rawScenes is Iterable) {
      int idx = 1;
      for (final s in rawScenes) {
        if (s is Map) {
          sceneModels.add(SceneModel.fromMap(Map<String, dynamic>.from(s), idx++));
        }
      }
    }

    // 4. Read continuity.yaml
    final continuityRes = await _yamlReader.readAndValidateFile(
      filePath: p.join(projectDirectoryPath, manifest.files['continuity'] ?? 'continuity.yaml'),
      schemaKey: 'continuity',
      isRequired: false,
    );
    projectFlags.addAll(continuityRes.flags);
    final continuityData = continuityRes.data?['continuity'] is Map
        ? Map<String, dynamic>.from(continuityRes.data!['continuity'] as Map)
        : continuityRes.data;
    final continuity = continuityData != null
        ? ContinuityModel.fromMap(continuityData)
        : const ContinuityModel();

    // 5. Read visual_direction.yaml
    final visualDirRes = await _yamlReader.readAndValidateFile(
      filePath: p.join(projectDirectoryPath, manifest.files['visual_direction'] ?? 'visual_direction.yaml'),
      schemaKey: 'visual_direction',
      isRequired: false,
    );
    projectFlags.addAll(visualDirRes.flags);
    final visualDirData = visualDirRes.data?['visual_direction'] is Map
        ? Map<String, dynamic>.from(visualDirRes.data!['visual_direction'] as Map)
        : visualDirRes.data;
    final visualDirection = visualDirData != null
        ? VisualDirectionModel.fromMap(visualDirData)
        : const VisualDirectionModel();

    // 6. Read image_prompts.yaml
    final promptsRes = await _yamlReader.readAndValidateFile(
      filePath: p.join(projectDirectoryPath, manifest.files['image_prompts'] ?? 'image_prompts.yaml'),
      schemaKey: 'image_prompts',
      isRequired: false,
    );
    projectFlags.addAll(promptsRes.flags);
    final promptsData = promptsRes.data?['image_prompts'] is Map
        ? Map<String, dynamic>.from(promptsRes.data!['image_prompts'] as Map)
        : promptsRes.data;
    final imagePrompts = promptsData != null
        ? ImagePromptsModel.fromMap(promptsData)
        : const ImagePromptsModel();
    final promptsByScene = {for (final p in imagePrompts.prompts) p.sceneId: p};

    // 7. Read generation_manifest.yaml
    final manifestGenRes = await _yamlReader.readAndValidateFile(
      filePath: p.join(projectDirectoryPath, manifest.files['generation_manifest'] ?? 'generation_manifest.yaml'),
      schemaKey: 'generation_manifest',
      isRequired: false,
    );
    projectFlags.addAll(manifestGenRes.flags);
    final manifestGenData = manifestGenRes.data?['generation_manifest'] is Map
        ? Map<String, dynamic>.from(manifestGenRes.data!['generation_manifest'] as Map)
        : manifestGenRes.data;
    final generationManifest = manifestGenData != null
        ? GenerationManifestModel.fromMap(manifestGenData)
        : const GenerationManifestModel();

    // 8. Read visual_validation.yaml
    final validationRes = await _yamlReader.readAndValidateFile(
      filePath: p.join(projectDirectoryPath, manifest.files['visual_validation'] ?? 'visual_validation.yaml'),
      schemaKey: 'visual_validation',
      isRequired: false,
    );
    projectFlags.addAll(validationRes.flags);
    final validationData = validationRes.data?['visual_validation'] is Map
        ? Map<String, dynamic>.from(validationRes.data!['visual_validation'] as Map)
        : validationRes.data;
    final visualValidation = validationData != null
        ? VisualValidationModel.fromMap(validationData)
        : const VisualValidationModel();

    // 9. Read studio-owned files
    final studioDir = p.join(projectDirectoryPath, 'studio');

    final approvalsRes = await _yamlReader.readAndValidateFile(
      filePath: p.join(studioDir, 'approvals.yaml'),
      schemaKey: 'studio_approvals',
      isRequired: false,
    );
    final approvals = approvalsRes.data != null
        ? StudioApprovalsModel.fromMap(approvalsRes.data!)
        : const StudioApprovalsModel();

    final layoutRes = await _yamlReader.readAndValidateFile(
      filePath: p.join(studioDir, 'layout.yaml'),
      schemaKey: 'studio_layout',
      isRequired: false,
    );
    final layout = layoutRes.data != null
        ? StudioLayoutModel.fromMap(layoutRes.data!)
        : const StudioLayoutModel();

    final letteringRes = await _yamlReader.readAndValidateFile(
      filePath: p.join(studioDir, 'lettering.yaml'),
      schemaKey: 'studio_lettering',
      isRequired: false,
    );
    final lettering = letteringRes.data != null
        ? StudioLetteringModel.fromMap(letteringRes.data!)
        : const StudioLetteringModel();

    // Join all phase data by scene_id
    final aggregatedScenes = <AggregatedScene>[];
    for (final scene in sceneModels) {
      final sceneId = scene.sceneId;
      final prompt = promptsByScene[sceneId];
      final validationRecord = visualValidation.latestForScene(sceneId);
      final approval = approvals.forScene(sceneId);
      final assetVersions = generationManifest.versionsForScene(sceneId);
      final bubbles = lettering.forScene(sceneId);

      // Collect flags specific to this scene
      final sceneFlags = <SceneValidationFlag>[];
      if (prompt == null) {
        sceneFlags.add(
          SceneValidationFlag(
            phase: 'image_prompts',
            message: 'Scene $sceneId is missing from image_prompts.yaml',
            severity: FlagSeverity.warning,
          ),
        );
      }
      if (validationRecord != null && validationRecord.verdict == ValidationVerdict.fail) {
        sceneFlags.add(
          SceneValidationFlag(
            phase: 'visual_validation',
            message: 'Visual audit failed: ${validationRecord.critique}',
            severity: FlagSeverity.error,
          ),
        );
      }

      aggregatedScenes.add(
        AggregatedScene(
          sceneId: sceneId,
          sequence: scene.sequence,
          sceneModel: scene,
          imagePrompt: prompt,
          visualDirection: visualDirection,
          validationRecord: validationRecord,
          approval: approval,
          assetVersions: assetVersions,
          flags: List.unmodifiable(sceneFlags),
          dialogueBubbles: bubbles,
        ),
      );
    }

    final finalManifest = (manifestRes.data == null &&
            generationManifest.provider.isNotEmpty)
        ? ProjectManifest(
            schemaVersion: manifest.schemaVersion,
            storyId: manifest.storyId,
            runId: manifest.runId,
            provider: generationManifest.provider,
            title: manifest.title,
            files: manifest.files,
          )
        : manifest;

    return StoryProject(
      rootPath: projectDirectoryPath,
      manifest: finalManifest,
      canonicalStory: canonicalStory,
      scenes: List.unmodifiable(aggregatedScenes),
      continuity: continuity,
      visualDirection: visualDirection,
      generationManifest: generationManifest,
      visualValidation: visualValidation,
      approvals: approvals,
      layout: layout,
      lettering: lettering,
      projectFlags: List.unmodifiable(projectFlags),
    );
  }

  @override
  Future<void> saveApprovals(String projectDirectoryPath, StudioApprovalsModel approvals) {
    return _yamlWriter.writeApprovals(projectDirectoryPath, approvals);
  }

  @override
  Future<void> saveLayout(String projectDirectoryPath, StudioLayoutModel layout) {
    return _yamlWriter.writeLayout(projectDirectoryPath, layout);
  }

  @override
  Future<void> saveLettering(String projectDirectoryPath, StudioLetteringModel lettering) {
    return _yamlWriter.writeLettering(projectDirectoryPath, lettering);
  }

  @override
  Future<String> saveNewAssetVersion({
    required String projectDirectoryPath,
    required String sceneId,
    required List<int> imageBytes,
    required String extension,
  }) async {
    final assetDir = Directory(p.join(projectDirectoryPath, 'assets', sceneId));
    if (!await assetDir.exists()) {
      await assetDir.create(recursive: true);
    }

    // Determine next version number by inspecting existing files in assetDir
    int nextVersion = 1;
    final entities = await assetDir.list().toList();
    for (final e in entities) {
      final name = p.basenameWithoutExtension(e.path);
      if (name.startsWith('v')) {
        final verNum = int.tryParse(name.substring(1));
        if (verNum != null && verNum >= nextVersion) {
          nextVersion = verNum + 1;
        }
      }
    }

    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    final fileName = 'v$nextVersion.$ext';
    final targetPath = p.join(assetDir.path, fileName);
    final file = File(targetPath);
    await file.writeAsBytes(imageBytes, flush: true);

    return p.join('assets', sceneId, fileName);
  }

  @override
  Future<void> recordAssetInManifest({
    required String projectDirectoryPath,
    required String sceneId,
    required int version,
    required String relativeFilePath,
    required String promptHash,
    required String provider,
    double costUsd = 0.0,
  }) {
    final record = AssetVersionRecord(
      sceneId: sceneId,
      version: version,
      filePath: relativeFilePath,
      promptHash: promptHash,
      provider: provider,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      costUsd: costUsd,
    );

    return _yamlWriter.appendToGenerationManifest(
      projectRoot: projectDirectoryPath,
      record: record,
    );
  }
}
