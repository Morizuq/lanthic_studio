import 'dart:convert';
import 'package:json_schema/json_schema.dart';
import '../../core/errors/failures.dart';

class SchemaValidationResult {
  const SchemaValidationResult({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final List<String> errors;

  static const valid = SchemaValidationResult(isValid: true, errors: []);
}

class SchemaValidator {
  final Map<String, JsonSchema> _compiledSchemas = {};

  void registerSchemaString(String schemaKey, String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      final schema = JsonSchema.create(decoded);
      _compiledSchemas[schemaKey] = schema;
    } catch (e, stack) {
      throw SchemaValidationFailure(
        'Failed to parse JSON Schema for $schemaKey',
        filePath: schemaKey,
        errors: [e.toString()],
        cause: stack,
      );
    }
  }

  SchemaValidationResult validate(String schemaKey, dynamic data) {
    final schema = _compiledSchemas[schemaKey];
    if (schema == null) {
      return SchemaValidationResult(
        isValid: false,
        errors: ['Schema not registered: $schemaKey'],
      );
    }

    final validation = schema.validate(data);
    if (validation.isValid) {
      return SchemaValidationResult.valid;
    }

    final errorMessages = validation.errors.map((e) => e.message).toList();
    return SchemaValidationResult(
      isValid: false,
      errors: errorMessages,
    );
  }
}
