import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/data/repositories/disk_project_repository.dart';
import 'package:lanthic_studio/data/yaml/schema_registry.dart';
import 'package:lanthic_studio/data/yaml/schema_validator.dart';
import 'package:lanthic_studio/features/pipeline/data/orchestrator/lanthic_pipeline_orchestrator.dart';
import 'package:lanthic_studio/features/pipeline/domain/models/pipeline_run_progress.dart';
import 'package:lanthic_studio/features/pipeline/domain/repositories/skills_repository.dart';

class MockSkillsRepository implements SkillsRepository {
  @override
  Future<String> getSourceDescription() async => 'Test Mock Skills Source';

  @override
  Future<bool> isSkillsSourceAvailable() async => true;

  @override
  Future<Map<String, String>> loadAllSkills() async => {
        '01-storytelling/SKILL.md': '# Storytelling instructions',
        '02-scene-extraction/SKILL.md': '# Scene Extraction instructions',
      };

  @override
  Future<void> setLocalSkillsDirectory(String path) async {}

  @override
  Future<void> syncRemoteSkills({
    required String githubPat,
    required String repositoryOwnerAndName,
    String branch = 'main',
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LanthicPipelineOrchestrator orchestrator;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lanthic_cook_test_');
    orchestrator = LanthicPipelineOrchestrator(
      skillsRepository: MockSkillsRepository(),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('orchestrator runs all 8 phases and generates a valid project loadable by repository', () async {
    final progressEvents = <PipelineRunProgress>[];

    await orchestrator.runPipeline(
      storyTitle: 'The Blue Eclipse',
      rawStory: 'A young blacksmith in the highlands watches blue sparks descend from an astronomical anomaly.',
      targetDirectory: tempDir.path,
      provider: 'flux',
      onProgress: (p) => progressEvents.add(p),
    );

    expect(progressEvents.isNotEmpty, isTrue);
    final lastEvent = progressEvents.last;
    expect(lastEvent.status, PipelineRunStatus.completed);
    expect(lastEvent.currentPhase, 8);
    expect(lastEvent.artifactsGenerated.length, 8);

    final projectFolder = Directory(lastEvent.projectDirectory);
    expect(projectFolder.existsSync(), isTrue);

    // Verify all 8 files exist on disk
    expect(File('${projectFolder.path}/canonical_story.md').existsSync(), isTrue);
    expect(File('${projectFolder.path}/scenes.yaml').existsSync(), isTrue);
    expect(File('${projectFolder.path}/continuity.yaml').existsSync(), isTrue);
    expect(File('${projectFolder.path}/visual_direction.yaml').existsSync(), isTrue);
    expect(File('${projectFolder.path}/image_prompts.yaml').existsSync(), isTrue);
    expect(File('${projectFolder.path}/provider_request.yaml').existsSync(), isTrue);
    expect(File('${projectFolder.path}/generation_manifest.yaml').existsSync(), isTrue);
    expect(File('${projectFolder.path}/visual_validation.yaml').existsSync(), isTrue);

    // Now test that DiskProjectRepository actually loads this freshly cooked story cleanly!
    final validator = SchemaValidator();
    final registry = SchemaRegistry(validator);
    final repository = DiskProjectRepository(schemaRegistry: registry);

    final project = await repository.loadProject(projectFolder.path);
    expect(project.manifest.storyId, 'the_blue_eclipse');
    expect(project.totalScenes, 2);
    expect(project.canonicalStory, contains('The Blue Eclipse'));
    expect(project.manifest.provider, 'flux');
  });
}
