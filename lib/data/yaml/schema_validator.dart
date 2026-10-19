import 'dart:convert';
import 'package:json_schema/json_schema.dart';
import '../../core/errors/failures.dart';

/// The result of evaluating a data payload against a compiled JSON Schema.
///
/// Encapsulates a boolean [isValid] indicator and a collection of human-readable
/// schema constraint [errors] (e.g. missing required properties, type violations).
class SchemaValidationResult {
  /// Constructs a [SchemaValidationResult].
  const SchemaValidationResult({required this.isValid, required this.errors});

  /// Whether the evaluated data structure satisfies all schema requirements.
  final bool isValid;

  /// Human-readable validation error messages produced by the JSON Schema evaluator.
  final List<String> errors;

  /// Canonical instance representing successful validation with zero errors.
  static const valid = SchemaValidationResult(isValid: true, errors: []);
}

/// In-memory engine for compiling and executing JSON Schema validations.
///
/// Pre-compiles declarative JSON schema strings into executable [JsonSchema]
/// evaluators, providing fast, cached validation against incoming YAML phase data.
class SchemaValidator {
  final Map<String, JsonSchema> _compiledSchemas = {};

  /// Compiles a raw JSON schema string and registers it under [schemaKey].
  ///
  /// Throws [SchemaValidationFailure] if [jsonString] is malformed JSON or an invalid schema.
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

  /// Evaluates normalized [data] against the schema registered at [schemaKey].
  ///
  /// If [schemaKey] is not registered, returns a [SchemaValidationResult] marked invalid.
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
    return SchemaValidationResult(isValid: false, errors: errorMessages);
  }
}
