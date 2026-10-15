import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/data/yaml/phase_yaml_reader.dart';
import 'package:lanthic_studio/data/yaml/schema_registry.dart';
import 'package:lanthic_studio/data/yaml/schema_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PhaseYamlReader reader;

  setUp(() async {
    final validator = SchemaValidator();
    final registry = SchemaRegistry(validator);
    await registry.initialize();
    reader = PhaseYamlReader(schemaRegistry: registry);
  });

  group('YamlDriftResilience', () {
    test('produces validation warning flags when LLM outputs missing required fields', () {
      const driftedYaml = '''
scenes:
  - # scene_id is missing (violates scenes.schema.json required property)
    slug: "INT. DRIFT - NIGHT"
''';

      final result = reader.parseAndValidateYaml(
        content: driftedYaml,
        schemaKey: 'scenes',
        sourceIdentifier: 'memory_test',
      );

      expect(result.data, isNotNull);
      expect(result.flags.isNotEmpty, isTrue);
      expect(result.flags.first.message, contains('Schema violation'));
    });
  });
}
