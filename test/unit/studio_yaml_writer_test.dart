import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/data/repositories/disk_project_repository.dart';
import 'package:lanthic_studio/data/yaml/schema_registry.dart';
import 'package:lanthic_studio/data/yaml/schema_validator.dart';
import 'package:lanthic_studio/data/yaml/studio_yaml_writer.dart';
import 'package:lanthic_studio/domain/models/generation_manifest_model.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StudioYamlWriter writer;
  late DiskProjectRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('studio_yaml_writer_test_');
    writer = const StudioYamlWriter();
    final validator = SchemaValidator();
    final registry = SchemaRegistry(validator);
    repository = DiskProjectRepository(schemaRegistry: registry);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StudioYamlWriter.appendToGenerationManifest', () {
    test('creates records list when generation_manifest.yaml does not exist', () async {
      final record = AssetVersionRecord(
        sceneId: 'sc_001',
        version: 1,
        filePath: 'assets/sc_001/v1.png',
        promptHash: 'hash123',
        provider: 'qwen',
        timestamp: '2026-10-15T12:00:00Z',
        costUsd: 0.01,
      );

      await writer.appendToGenerationManifest(
        projectRoot: tempDir.path,
        record: record,
      );

      final manifestFile = File(p.join(tempDir.path, 'generation_manifest.yaml'));
      expect(await manifestFile.exists(), isTrue);

      final content = await manifestFile.readAsString();
      expect(content, contains('sc_001'));
      expect(content, contains('v1.png'));

      final loadedProject = await repository.loadProject(tempDir.path);
      expect(loadedProject, isNotNull);
    });

    test('preserves generation_manifest block and appends new scenes cleanly', () async {
      // Simulate real-world lanthic-skills generation_manifest.yaml
      const initialYaml = '''
generation_manifest:
  story:
    title: "Test Story"
  execution_metadata:
    provider: "flux_api"
  scenes:
    - scene_id: night_outsourcing
      status: success
      asset:
        file_path: "assets/renders/night_outsourcing_84201.png"
''';

      final manifestFile = File(p.join(tempDir.path, 'generation_manifest.yaml'));
      await manifestFile.writeAsString(initialYaml);

      final scenesFile = File(p.join(tempDir.path, 'scenes.yaml'));
      await scenesFile.writeAsString('''
scenes:
  - scene_id: night_outsourcing
    sequence: 1
    slug: "EXT. NIGHT"
    description: "Night description"
''');

      final record = AssetVersionRecord(
        sceneId: 'night_outsourcing',
        version: 2,
        filePath: 'assets/night_outsourcing/v2.png',
        promptHash: 'new_hash_456',
        provider: 'qwen',
        timestamp: '2026-10-15T12:30:00Z',
        costUsd: 0.0,
      );

      await writer.appendToGenerationManifest(
        projectRoot: tempDir.path,
        record: record,
      );

      final content = await manifestFile.readAsString();
      expect(content, contains('title: "Test Story"'));
      expect(content, contains('assets/night_outsourcing/v2.png'));

      // Validate that repository loads it without YamlParseFailure
      final loadedProject = await repository.loadProject(tempDir.path);
      final scene = loadedProject.sceneById('night_outsourcing');
      expect(scene, isNotNull);
      expect(scene!.assetVersions.length, 2);
      expect(scene.assetVersions.last.version, 2);
    });
  });
}
