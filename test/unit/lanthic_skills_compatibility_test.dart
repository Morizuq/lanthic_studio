import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/data/repositories/disk_project_repository.dart';
import 'package:lanthic_studio/data/yaml/schema_registry.dart';
import 'package:lanthic_studio/data/yaml/schema_validator.dart';
import 'package:lanthic_studio/domain/models/visual_validation_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DiskProjectRepository repository;
  late String fixturePath;

  setUp(() {
    final validator = SchemaValidator();
    final registry = SchemaRegistry(validator);
    repository = DiskProjectRepository(schemaRegistry: registry);
    fixturePath =
        '${Directory.current.path}/test/fixtures/the_signature_in_the_lining';
  });

  group('Lanthic Skills Real-World Compatibility', () {
    test(
        'successfully loads and validates native lanthic-skills pipeline outputs',
        () async {
      final project = await repository.loadProject(fixturePath);

      // Synthesized project manifest verification
      expect(project.manifest.storyId, 'the_signature_in_the_lining');
      expect(project.manifest.provider, 'flux_api');
      expect(project.totalScenes, 2);

      // Schema validation: ensure no schema errors were logged on lanthic-skills format
      expect(project.projectFlags, isEmpty);

      // Verify Scene 1 (night_outsourcing)
      final scene1 = project.sceneById('night_outsourcing');
      expect(scene1, isNotNull);
      expect(scene1!.sequence, 1);
      expect(scene1.sceneModel.sceneId, 'night_outsourcing');
      expect(scene1.sceneModel.characters, contains('tunde'));
      expect(scene1.sceneModel.characters, contains('bassey'));
      expect(
        scene1.visualDirection?.sceneOverrides['night_outsourcing']
            ?['primary_focus'],
        'tunde',
      );
      expect(scene1.imagePrompt?.prompt, contains('kerosene lantern'));
      expect(
        scene1.currentAssetRecord?.filePath,
        contains('night_outsourcing_84201.png'),
      );
      expect(scene1.validationRecord?.verdict, ValidationVerdict.pass);

      // Verify Scene 2 (cuff_exposure)
      final scene2 = project.sceneById('cuff_exposure');
      expect(scene2, isNotNull);
      expect(scene2!.sequence, 2);
      expect(scene2.sceneModel.sceneId, 'cuff_exposure');
      expect(scene2.sceneModel.characters, contains('patriarch'));
      expect(scene2.sceneModel.characters, contains('tunde'));
      expect(scene2.sceneModel.characters, contains('bassey'));
      expect(
        scene2.visualDirection?.sceneOverrides['cuff_exposure']
            ?['primary_focus'],
        'wedding_robe',
      );
      expect(scene2.imagePrompt?.prompt, contains('indigo'));
      expect(
        scene2.currentAssetRecord?.filePath,
        contains('cuff_exposure_84206.png'),
      );
      expect(scene2.validationRecord?.verdict, ValidationVerdict.pass);

      // Global visual direction verification
      expect(
        project.visualDirection.style,
        contains('Yoruba textile traditions'),
      );

      // Canonical story verification
      expect(project.canonicalStory, contains('The Blind Stitch'));
    });
  });
}
