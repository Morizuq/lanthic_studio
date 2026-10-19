import 'dart:io';
import 'package:yaml/yaml.dart';
import '../../core/errors/failures.dart';
import '../../domain/models/aggregated_scene.dart';
import 'schema_registry.dart';

/// Represents the strongly typed outcome of reading, parsing, and validating
/// a pipeline phase specification file from disk.
///
/// Encapsulates the parsed payload [data], diagnostic [flags] raised during
/// schema validation or file reading, and a boolean [wasFound] indicating whether
/// the physical file existed on disk.
///
/// This model embodies the "Diagnostic Collector" pattern, ensuring that non-fatal
/// schema anomalies do not abruptly crash pipeline loading, but are instead
/// surfaced to the user interface as inspectable warnings.
class PhaseFileResult<T> {
  /// Constructs a [PhaseFileResult] instance.
  ///
  /// * [data]: The deserialized and normalized Dart data structure (or `null` if missing/failed).
  /// * [flags]: Collection of diagnostic flags (warnings or errors) collected during processing.
  /// * [wasFound]: Whether the source file existed on disk. Defaults to `true`.
  const PhaseFileResult({
    required this.data,
    this.flags = const [],
    this.wasFound = true,
  });

  /// The parsed and normalized payload of type [T].
  ///
  /// Typically a [Map<String, dynamic>] for top-level YAML maps, or `null` if the
  /// file was missing or encountered an unrecoverable format violation.
  final T? data;

  /// Diagnostic flags generated during file read or schema validation.
  ///
  /// Errors indicate structural incompatibility, while warnings indicate optional
  /// schema deviations or field deprecations.
  final List<SceneValidationFlag> flags;

  /// Indicates whether the physical file existed on disk at the requested path.
  final bool wasFound;

  /// Returns `true` if any diagnostic flag carries a [FlagSeverity.error] rating.
  bool get hasErrors => flags.any((f) => f.severity == FlagSeverity.error);
}

/// Robust asynchronous YAML reader and validator for Lanthic pipeline phase files.
///
/// The [PhaseYamlReader] is responsible for:
/// 1. Asynchronously reading raw file content from disk.
/// 2. Parsing raw YAML strings into abstract syntax tree (AST) nodes via `package:yaml`.
/// 3. Normalizing read-only [YamlMap] and [YamlList] instances into mutable Dart
///    primitives ([Map<String, dynamic>] and [List<dynamic>]) to prevent downstream
///    type mismatches and runtime cast failures.
/// 4. Executing declarative JSON-schema validation against the [SchemaRegistry].
/// 5. Aggregating schema warnings and errors into [SceneValidationFlag] instances
///    without halting execution unless explicit syntax parsing fails.
class PhaseYamlReader {
  /// Creates a [PhaseYamlReader] backed by the provided [SchemaRegistry].
  ///
  /// * [_registry]: The centralized registry containing pre-loaded JSON schemas
  ///   for all 8 pipeline phases and studio configuration files.
  const PhaseYamlReader({required SchemaRegistry schemaRegistry})
      : _registry = schemaRegistry;

  final SchemaRegistry _registry;

  /// Asynchronously reads, normalizes, and validates a YAML file from disk.
  ///
  /// Parameters:
  /// * [filePath]: Absolute or relative path to the YAML file on the local filesystem.
  /// * [schemaKey]: The identifier used to look up the corresponding JSON schema in
  ///   the [SchemaRegistry] (e.g. `'scenes'`, `'visual_direction'`, `'project'`).
  /// * [isRequired]: When `true`, missing files will result in a [PhaseFileResult]
  ///   containing an error-level [SceneValidationFlag]. When `false`, missing files
  ///   gracefully return a result with `data: null` and `wasFound: false`.
  ///
  /// Returns a [PhaseFileResult] containing the normalized [Map<String, dynamic>]
  /// and any validation flags.
  ///
  /// Throws [YamlParseFailure] if the file contains invalid YAML syntax.
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

  /// Parses raw YAML string content into a normalized map and validates it against
  /// the schema identified by [schemaKey].
  ///
  /// Parameters:
  /// * [content]: The raw YAML string content to be parsed.
  /// * [schemaKey]: The schema identifier within the [SchemaRegistry].
  /// * [sourceIdentifier]: A human-readable identifier (such as a file path or URI)
  ///   used for error reporting and debug logs.
  ///
  /// Returns a [PhaseFileResult] holding the normalized map and any diagnostic flags.
  ///
  /// Throws [YamlParseFailure] if the raw string cannot be parsed as valid YAML.
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

  /// Recursively converts read-only YAML nodes ([YamlMap], [YamlList]) into standard
  /// mutable Dart collection structures ([Map<String, dynamic>], [List<dynamic>]).
  ///
  /// ### Rationale
  /// The `package:yaml` library produces specialized immutable maps (`YamlMap`) where keys
  /// are typed as `dynamic`. Passing `YamlMap` instances to standard JSON encoders, schema
  /// validators, or Riverpod state models frequently triggers `TypeError` at runtime.
  /// Normalizing the tree upfront ensures deep interoperability across the domain layer.
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
