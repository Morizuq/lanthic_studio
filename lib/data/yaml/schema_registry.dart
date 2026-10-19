import 'dart:io';
import 'package:flutter/services.dart';
import 'schema_validator.dart';

/// Central catalog responsible for locating, loading, and caching JSON Schemas
/// for all 8 narrative pipeline phases and studio configuration files.
///
/// Implements a multi-tiered schema discovery policy:
/// 1. Custom schemas directory supplied by the project (e.g. `<project_root>/schemas/`).
/// 2. Local workspace filesystem assets (`assets/schemas/`).
/// 3. Flutter compiled bundle assets via [rootBundle].
class SchemaRegistry {
  /// Constructs a [SchemaRegistry] backed by the given [SchemaValidator].
  SchemaRegistry(this._validator);

  final SchemaValidator _validator;
  bool _initialized = false;

  /// Canonical list of schema names required across the studio pipeline.
  static const List<String> schemaNames = [
    'project',
    'scenes',
    'continuity',
    'visual_direction',
    'image_prompts',
    'provider_request',
    'generation_manifest',
    'visual_validation',
    'studio_approvals',
    'studio_layout',
    'studio_lettering',
  ];

  /// Asynchronously loads and compiles all JSON schemas from filesystem or bundle.
  ///
  /// * [customSchemasDir]: Optional project-specific override path.
  Future<void> initialize({String? customSchemasDir}) async {
    if (_initialized) return;

    for (final name in schemaNames) {
      String? jsonContent;

      if (customSchemasDir != null) {
        final file = File('$customSchemasDir/$name.schema.json');
        if (file.existsSync()) {
          jsonContent = file.readAsStringSync();
        }
      }

      // Check workspace assets/schemas/ directory directly on disk
      if (jsonContent == null) {
        final localFile = File('assets/schemas/$name.schema.json');
        if (localFile.existsSync()) {
          jsonContent = localFile.readAsStringSync();
        }
      }

      if (jsonContent == null) {
        try {
          jsonContent = await rootBundle.loadString('assets/schemas/$name.schema.json');
        } catch (_) {
          // Fallback if not found in bundle
        }
      }

      if (jsonContent != null) {
        _validator.registerSchemaString(name, jsonContent);
      }
    }

    _initialized = true;
  }

  /// Delegates schema validation for [schemaKey] to the underlying [SchemaValidator].
  SchemaValidationResult validate(String schemaKey, dynamic data) {
    return _validator.validate(schemaKey, data);
  }
}

