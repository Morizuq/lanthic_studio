import 'dart:io';
import 'package:yaml/yaml.dart';
import '../../core/errors/failures.dart';
import '../../domain/models/aggregated_scene.dart';
import 'schema_registry.dart';

class PhaseFileResult<T> {
  const PhaseFileResult({
    required this.data,
    this.flags = const [],
    this.wasFound = true,
  });

  final T? data;
  final List<SceneValidationFlag> flags;
  final bool wasFound;

  bool get hasErrors => flags.any((f) => f.severity == FlagSeverity.error);
}

class PhaseYamlReader {
  const PhaseYamlReader({required SchemaRegistry schemaRegistry})
      : _registry = schemaRegistry;

  final SchemaRegistry _registry;

  Future<PhaseFileResult<Map<String, dynamic>>> readAndValidateFile({
    required String filePath,
    required String schemaKey,
    bool isRequired = true,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (isRequired) {
        return PhaseFileResult(
          data: null,
          wasFound: false,
          flags: [
            SceneValidationFlag(
              phase: schemaKey,
              message: 'Missing required phase file: ${file.path}',
              severity: FlagSeverity.error,
            ),
          ],
        );
      }
      return const PhaseFileResult(data: null, wasFound: false);
    }

    final String rawContent;
    try {
      rawContent = await file.readAsString();
    } catch (e) {
      return PhaseFileResult(
        data: null,
        flags: [
          SceneValidationFlag(
            phase: schemaKey,
            message: 'Failed to read file ${file.path}: $e',
            severity: FlagSeverity.error,
          ),
        ],
      );
    }

    return parseAndValidateYaml(
      content: rawContent,
      schemaKey: schemaKey,
      sourceIdentifier: file.path,
    );
  }

  PhaseFileResult<Map<String, dynamic>> parseAndValidateYaml({
    required String content,
    required String schemaKey,
    required String sourceIdentifier,
  }) {
    final dynamic yamlNode;
    try {
      yamlNode = loadYaml(content);
    } catch (e, stack) {
      throw YamlParseFailure(
        'Syntax error in YAML',
        filePath: sourceIdentifier,
        details: e.toString(),
        cause: stack,
      );
    }

    final dynamic normalized = _normalizeYamlNode(yamlNode);
    if (normalized is! Map<String, dynamic>) {
      return PhaseFileResult(
        data: null,
        flags: [
          SceneValidationFlag(
            phase: schemaKey,
            message: 'Expected top-level map in $sourceIdentifier, found ${normalized.runtimeType}',
            severity: FlagSeverity.error,
          ),
        ],
      );
    }

    final validation = _registry.validate(schemaKey, normalized);
    final flags = <SceneValidationFlag>[];

    if (!validation.isValid) {
      for (final err in validation.errors) {
        flags.add(
          SceneValidationFlag(
            phase: schemaKey,
            message: 'Schema violation: $err',
            severity: FlagSeverity.warning,
          ),
        );
      }
    }

    return PhaseFileResult(
      data: normalized,
      flags: List.unmodifiable(flags),
    );
  }

  dynamic _normalizeYamlNode(dynamic node) {
    if (node is YamlMap) {
      final map = <String, dynamic>{};
      for (final entry in node.entries) {
        map[entry.key.toString()] = _normalizeYamlNode(entry.value);
      }
      return map;
    } else if (node is Map) {
      final map = <String, dynamic>{};
      for (final entry in node.entries) {
        map[entry.key.toString()] = _normalizeYamlNode(entry.value);
      }
      return map;
    } else if (node is YamlList) {
      return node.map(_normalizeYamlNode).toList();
    } else if (node is List) {
      return node.map(_normalizeYamlNode).toList();
    }
    return node;
  }
}
