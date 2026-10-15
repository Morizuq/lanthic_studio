import 'dart:io';
import 'package:flutter/services.dart';
import 'schema_validator.dart';

class SchemaRegistry {
  SchemaRegistry(this._validator);

  final SchemaValidator _validator;
  bool _initialized = false;

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
          // Fallback if not found
        }
      }

      if (jsonContent != null) {
        _validator.registerSchemaString(name, jsonContent);
      }
    }

    _initialized = true;
  }

  SchemaValidationResult validate(String schemaKey, dynamic data) {
    return _validator.validate(schemaKey, data);
  }
}
