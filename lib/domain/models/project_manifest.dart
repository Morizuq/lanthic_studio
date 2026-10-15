import 'package:meta/meta.dart';

@immutable
class ProjectManifest {
  const ProjectManifest({
    required this.schemaVersion,
    required this.storyId,
    required this.runId,
    required this.provider,
    this.title = '',
    this.files = const {},
  });

  final String schemaVersion;
  final String storyId;
  final String runId;
  final String provider;
  final String title;
  final Map<String, String> files;

  factory ProjectManifest.fromMap(Map<String, dynamic> map) {
    final rawFiles = map['files'];
    final filesMap = <String, String>{};
    if (rawFiles is Map) {
      for (final entry in rawFiles.entries) {
        filesMap[entry.key.toString()] = entry.value.toString();
      }
    }

    return ProjectManifest(
      schemaVersion: (map['schema_version'] ?? '1.0.0').toString(),
      storyId: (map['story_id'] ?? '').toString(),
      runId: (map['run_id'] ?? '').toString(),
      provider: (map['provider'] ?? 'flux').toString(),
      title: (map['title'] ?? '').toString(),
      files: Map.unmodifiable(filesMap),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schema_version': schemaVersion,
      'story_id': storyId,
      'run_id': runId,
      'provider': provider,
      if (title.isNotEmpty) 'title': title,
      if (files.isNotEmpty) 'files': files,
    };
  }
}
