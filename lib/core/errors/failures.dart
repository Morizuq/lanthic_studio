import 'package:meta/meta.dart';

@immutable
abstract class StudioFailure implements Exception {
  const StudioFailure(this.message, {this.details, this.cause});

  final String message;
  final String? details;
  final Object? cause;

  @override
  String toString() {
    if (details != null) {
      return '$runtimeType: $message ($details)';
    }
    return '$runtimeType: $message';
  }
}

class ProjectLoadFailure extends StudioFailure {
  const ProjectLoadFailure(super.message, {super.details, super.cause});
}

class SchemaValidationFailure extends StudioFailure {
  const SchemaValidationFailure(
    super.message, {
    required this.filePath,
    required this.errors,
    super.cause,
  }) : super(details: 'File: $filePath, Issues: ${errors.length}');

  final String filePath;
  final List<String> errors;
}

class YamlParseFailure extends StudioFailure {
  const YamlParseFailure(
    super.message, {
    required this.filePath,
    super.details,
    super.cause,
  });

  final String filePath;
}

class GenerationFailure extends StudioFailure {
  const GenerationFailure(
    super.message, {
    required this.sceneId,
    required this.provider,
    super.details,
    super.cause,
  });

  final String sceneId;
  final String provider;
}

class SecureStorageFailure extends StudioFailure {
  const SecureStorageFailure(super.message, {super.details, super.cause});
}
