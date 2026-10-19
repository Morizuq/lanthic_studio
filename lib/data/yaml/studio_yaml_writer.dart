import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import '../../core/errors/failures.dart';
import '../../domain/models/generation_manifest_model.dart';
import '../../domain/models/studio_models.dart';

/// Thread-safe writer responsible for persisting studio mutations back to disk.
///
/// Features:
/// 1. **Atomic File Writes**: Writes data to a temporary file (`.tmp`) with `flush: true`
///    before atomically renaming it to the target file. This eliminates partial-write
///    corruptions caused by abrupt app termination or power failure.
/// 2. **Non-destructive In-Place YAML Edits**: Uses `package:yaml_edit` to append
///    records into `generation_manifest.yaml` while preserving comments, formatting,
///    and unrecognized custom keys.
/// 3. **Asynchronous Lock Mutex**: Enforces sequential serialization for manifest writes
///    via [_AsyncLock] to prevent race conditions during parallel scene cooking.
class StudioYamlWriter {
  /// Constructs a [StudioYamlWriter].
  const StudioYamlWriter();

  static final _AsyncLock _manifestLock = _AsyncLock();

  Future<void> writeApprovals(
    String projectRoot,
    StudioApprovalsModel model,
  ) async {
    final studioDir = Directory(p.join(projectRoot, 'studio'));
    if (!await studioDir.exists()) {
      await studioDir.create(recursive: true);
    }

    final buffer = StringBuffer();
    buffer.writeln('schema_version: "${model.schemaVersion}"');
    buffer.writeln('approvals:');
    for (final app in model.approvals) {
      buffer.writeln('  - scene_id: "${app.sceneId}"');
      buffer.writeln('    status: "${app.status.toSerializedString()}"');
      buffer.writeln('    selected_version: ${app.selectedVersion}');
      if (app.promptOverride != null) {
        final escapedPrompt = app.promptOverride!.replaceAll('"', '\\"');
        buffer.writeln('    prompt_override: "$escapedPrompt"');
      } else {
        buffer.writeln('    prompt_override: null');
      }
      final escapedNotes = app.reviewNotes.replaceAll('"', '\\"');
      buffer.writeln('    review_notes: "$escapedNotes"');
      buffer.writeln('    updated_at: "${app.updatedAt}"');
    }

    await _atomicWriteFile(
      p.join(studioDir.path, 'approvals.yaml'),
      buffer.toString(),
    );
  }

  Future<void> writeLayout(String projectRoot, StudioLayoutModel model) async {
    final studioDir = Directory(p.join(projectRoot, 'studio'));
    if (!await studioDir.exists()) {
      await studioDir.create(recursive: true);
    }

    final buffer = StringBuffer();
    buffer.writeln('schema_version: "${model.schemaVersion}"');
    buffer.writeln('pages:');
    for (final page in model.pages) {
      buffer.writeln('  - page: ${page.page}');
      buffer.writeln('    template: "${page.template}"');
      buffer.writeln('    panels:');
      for (final panel in page.panels) {
        buffer.writeln('      - slot: ${panel.slot}');
        buffer.writeln('        scene_id: "${panel.sceneId}"');
        buffer.writeln('        asset: "${panel.asset}"');
        buffer.writeln('        crop:');
        buffer.writeln('          x: ${panel.crop.x}');
        buffer.writeln('          y: ${panel.crop.y}');
        buffer.writeln('          w: ${panel.crop.w}');
        buffer.writeln('          h: ${panel.crop.h}');
      }
    }

    await _atomicWriteFile(
      p.join(studioDir.path, 'layout.yaml'),
      buffer.toString(),
    );
  }

  Future<void> writeLettering(
    String projectRoot,
    StudioLetteringModel model,
  ) async {
    final studioDir = Directory(p.join(projectRoot, 'studio'));
    if (!await studioDir.exists()) {
      await studioDir.create(recursive: true);
    }

    final buffer = StringBuffer();
    buffer.writeln('schema_version: "${model.schemaVersion}"');
    buffer.writeln('bubbles:');
    for (final b in model.bubbles) {
      buffer.writeln('  - bubble_id: "${b.bubbleId}"');
      buffer.writeln('    scene_id: "${b.sceneId}"');
      buffer.writeln('    type: "${b.type.name}"');
      if (b.speaker.isNotEmpty) {
        buffer.writeln('    speaker: "${b.speaker.replaceAll('"', '\\"')}"');
      }
      buffer.writeln('    text: "${b.text.replaceAll('"', '\\"')}"');
      buffer.writeln('    x: ${b.x}');
      buffer.writeln('    y: ${b.y}');
      buffer.writeln('    width: ${b.width}');
      buffer.writeln('    height: ${b.height}');
      buffer.writeln('    tail_target_x: ${b.tailTargetX}');
      buffer.writeln('    tail_target_y: ${b.tailTargetY}');
    }

    await _atomicWriteFile(
      p.join(studioDir.path, 'lettering.yaml'),
      buffer.toString(),
    );
  }

  Future<void> appendToGenerationManifest({
    required String projectRoot,
    required AssetVersionRecord record,
  }) {
    return _manifestLock.synchronized(() async {
      final manifestPath = p.join(projectRoot, 'generation_manifest.yaml');
      final file = File(manifestPath);

      final entry = {
        'scene_id': record.sceneId,
        'status': 'success',
        'version': record.version,
        'file_path': record.filePath,
        'asset': {
          'file_path': record.filePath,
          'file_format': record.filePath.endsWith('.png') ? 'png' : 'png',
        },
        'prompt_hash': record.promptHash,
        'provider': record.provider,
        'timestamp': record.timestamp,
        'cost_usd': record.costUsd,
      };

      if (!await file.exists()) {
        final buffer = StringBuffer();
        buffer.writeln('schema_version: "1.0.0"');
        buffer.writeln('records:');
        buffer.writeln('  - scene_id: "${record.sceneId}"');
        buffer.writeln('    version: ${record.version}');
        buffer.writeln('    file_path: "${record.filePath}"');
        buffer.writeln('    prompt_hash: "${record.promptHash}"');
        buffer.writeln('    provider: "${record.provider}"');
        buffer.writeln('    timestamp: "${record.timestamp}"');
        buffer.writeln('    cost_usd: ${record.costUsd}');
        await _atomicWriteFile(manifestPath, buffer.toString());
        return;
      }

      final rawContent = await file.readAsString();
      if (rawContent.trim().isEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('schema_version: "1.0.0"');
        buffer.writeln('records:');
        buffer.writeln('  - scene_id: "${record.sceneId}"');
        buffer.writeln('    version: ${record.version}');
        buffer.writeln('    file_path: "${record.filePath}"');
        buffer.writeln('    prompt_hash: "${record.promptHash}"');
        buffer.writeln('    provider: "${record.provider}"');
        buffer.writeln('    timestamp: "${record.timestamp}"');
        buffer.writeln('    cost_usd: ${record.costUsd}');
        await _atomicWriteFile(manifestPath, buffer.toString());
        return;
      }

      dynamic yamlNode;
      try {
        yamlNode = loadYaml(rawContent);
      } catch (_) {
        yamlNode = null;
      }

      final editor = YamlEditor(rawContent);

      if (yamlNode is YamlMap) {
        if (yamlNode.containsKey('generation_manifest') &&
            yamlNode['generation_manifest'] is YamlMap) {
          final inner = yamlNode['generation_manifest'] as YamlMap;
          if (inner.containsKey('scenes') && inner['scenes'] is YamlList) {
            editor.appendToList(['generation_manifest', 'scenes'], entry);
          } else if (inner.containsKey('records') &&
              inner['records'] is YamlList) {
            editor.appendToList(['generation_manifest', 'records'], entry);
          } else {
            editor.update(['generation_manifest', 'scenes'], [entry]);
          }
        } else if (yamlNode.containsKey('scenes') &&
            yamlNode['scenes'] is YamlList) {
          editor.appendToList(['scenes'], entry);
        } else if (yamlNode.containsKey('records') &&
            yamlNode['records'] is YamlList) {
          editor.appendToList(['records'], entry);
        } else {
          editor.update(['records'], [entry]);
        }
      } else {
        final buffer = StringBuffer();
        buffer.writeln('schema_version: "1.0.0"');
        buffer.writeln('records:');
        buffer.writeln('  - scene_id: "${record.sceneId}"');
        buffer.writeln('    version: ${record.version}');
        buffer.writeln('    file_path: "${record.filePath}"');
        buffer.writeln('    prompt_hash: "${record.promptHash}"');
        buffer.writeln('    provider: "${record.provider}"');
        buffer.writeln('    timestamp: "${record.timestamp}"');
        buffer.writeln('    cost_usd: ${record.costUsd}');
        await _atomicWriteFile(manifestPath, buffer.toString());
        return;
      }

      await _atomicWriteFile(manifestPath, editor.toString());
    });
  }

  Future<void> _atomicWriteFile(String filePath, String content) async {
    final tempPath = '$filePath.tmp';
    final tempFile = File(tempPath);
    try {
      await tempFile.writeAsString(content, flush: true);
      await tempFile.rename(filePath);
    } catch (e, stack) {
      throw ProjectLoadFailure(
        'Failed atomic write to $filePath',
        details: e.toString(),
        cause: stack,
      );
    }
  }
}

/// FIFO mutex guaranteeing a single-writer execution queue without external packages.
class _AsyncLock {
  Future<void>? _last;

  Future<T> synchronized<T>(Future<T> Function() action) {
    final prev = _last;
    final completer = Completer<void>();
    _last = completer.future;

    return Future<void>(() async {
      if (prev != null) {
        try {
          await prev;
        } catch (_) {}
      }
    }).then((_) => action()).whenComplete(() {
      completer.complete();
    });
  }
}
