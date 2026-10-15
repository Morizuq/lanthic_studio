import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/data/repositories/disk_project_repository.dart';
import 'package:lanthic_studio/data/yaml/schema_registry.dart';
import 'package:lanthic_studio/data/yaml/schema_validator.dart';
import 'package:lanthic_studio/domain/models/studio_models.dart';
import 'package:lanthic_studio/domain/models/visual_validation_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DiskProjectRepository repository;
  late String sampleStoryPath;

  setUp(() {
    final validator = SchemaValidator();
    final registry = SchemaRegistry(validator);
    repository = DiskProjectRepository(schemaRegistry: registry);
    sampleStoryPath = '${Directory.current.path}/test/fixtures/sample_story';
  });

  group('DiskProjectRepository', () {
    test('loads and joins all 8 phases + studio directory by scene_id', () async {
      final project = await repository.loadProject(sampleStoryPath);

      expect(project.manifest.storyId, 'story_deep_orbit');
      expect(project.manifest.provider, 'flux');
      expect(project.totalScenes, 2);

      // Verify scene 1 joins
      final sc1 = project.sceneById('sc_001');
      expect(sc1, isNotNull);
      expect(sc1!.sequence, 1);
      expect(sc1.sceneModel.characters, contains('Captain Vane'));
      expect(sc1.imagePrompt?.prompt, contains('Captain Vane'));
      expect(sc1.validationRecord?.verdict, ValidationVerdict.warn);
      expect(sc1.status, ApprovalStatus.needsRegen);
      expect(sc1.effectivePrompt, contains('bright neon cyan-blue'));
      expect(sc1.assetVersions.length, 1);
      expect(sc1.assetVersions.first.filePath, 'assets/sc_001/v1.png');

      // Verify scene 2 joins
      final sc2 = project.sceneById('sc_002');
      expect(sc2, isNotNull);
      expect(sc2!.status, ApprovalStatus.approved);
      expect(sc2.validationRecord?.verdict, ValidationVerdict.pass);
    });

    test('increments asset version without overwriting existing versions', () async {
      final bytes = [137, 80, 78, 71, 13, 10, 26, 10]; // dummy png header
      final relativePath = await repository.saveNewAssetVersion(
        projectDirectoryPath: sampleStoryPath,
        sceneId: 'sc_001',
        imageBytes: bytes,
        extension: 'png',
      );

      expect(relativePath, 'assets/sc_001/v2.png');
      final newFile = File('$sampleStoryPath/$relativePath');
      expect(await newFile.exists(), isTrue);

      // Clean up after test
      await newFile.delete();
    });
  });
}
