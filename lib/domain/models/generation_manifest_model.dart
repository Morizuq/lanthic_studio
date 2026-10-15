import 'package:meta/meta.dart';

@immutable
class AssetVersionRecord {
  const AssetVersionRecord({
    required this.sceneId,
    required this.version,
    required this.filePath,
    required this.promptHash,
    this.provider = '',
    this.timestamp = '',
    this.costUsd = 0.0,
  });

  final String sceneId;
  final int version;
  final String filePath;
  final String promptHash;
  final String provider;
  final String timestamp;
  final double costUsd;

  factory AssetVersionRecord.fromMap(
    Map<String, dynamic> map, [
    int fallbackVersion = 1,
  ]) {
    String filePath = '';
    final asset = map['asset'];
    if (asset is Map && asset['file_path'] != null) {
      filePath = asset['file_path'].toString();
    } else if (map['file_path'] != null) {
      filePath = map['file_path'].toString();
    }

    int version = (map['version'] as num?)?.toInt() ?? fallbackVersion;
    if (map['version'] == null && filePath.isNotEmpty) {
      // Try to parse version from filename like sc_001_v2.png or v2.png
      final match = RegExp(r'v(\d+)').firstMatch(filePath);
      if (match != null) {
        version = int.tryParse(match.group(1)!) ?? fallbackVersion;
      }
    }

    final renderDetails = map['render_details'] is Map
        ? map['render_details'] as Map
        : null;
    final promptHash =
        (map['prompt_hash'] ?? renderDetails?['provider_job_id'] ?? '')
            .toString();
    final provider = (map['provider'] ?? '').toString();
    final timestamp = (map['timestamp'] ?? '').toString();
    final costUsd = (map['cost_usd'] as num?)?.toDouble() ?? 0.0;

    return AssetVersionRecord(
      sceneId: (map['scene_id'] ?? '').toString(),
      version: version,
      filePath: filePath,
      promptHash: promptHash,
      provider: provider,
      timestamp: timestamp,
      costUsd: costUsd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scene_id': sceneId,
      'version': version,
      'file_path': filePath,
      'prompt_hash': promptHash,
      'provider': provider,
      'timestamp': timestamp,
      'cost_usd': costUsd,
    };
  }
}

@immutable
class GenerationManifestModel {
  const GenerationManifestModel({this.records = const [], this.provider = ''});

  final List<AssetVersionRecord> records;
  final String provider;

  factory GenerationManifestModel.fromMap(Map<String, dynamic> map) {
    final manifestObj = map['generation_manifest'] is Map
        ? map['generation_manifest'] as Map
        : map;
    final execMeta = manifestObj['execution_metadata'] is Map
        ? manifestObj['execution_metadata'] as Map
        : null;
    final provider = (execMeta?['provider'] ?? manifestObj['provider'] ?? '')
        .toString();

    final rawList = manifestObj['scenes'] ?? manifestObj['records'];
    final items = <AssetVersionRecord>[];
    if (rawList is Iterable) {
      for (final item in rawList) {
        if (item is Map) {
          items.add(
            AssetVersionRecord.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return GenerationManifestModel(
      records: List.unmodifiable(items),
      provider: provider,
    );
  }

  Map<String, dynamic> toMap() {
    return {'records': records.map((r) => r.toMap()).toList()};
  }

  List<AssetVersionRecord> versionsForScene(String sceneId) {
    return records.where((r) => r.sceneId == sceneId).toList()
      ..sort((a, b) => a.version.compareTo(b.version));
  }

  int nextVersionForScene(String sceneId) {
    final versions = versionsForScene(sceneId);
    if (versions.isEmpty) return 1;
    return versions.last.version + 1;
  }
}
