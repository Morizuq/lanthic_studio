import 'package:meta/meta.dart';

@immutable
class ProviderRequestItem {
  const ProviderRequestItem({
    required this.sceneId,
    required this.provider,
    this.endpoint = '',
    this.parameters = const {},
  });

  final String sceneId;
  final String provider;
  final String endpoint;
  final Map<String, dynamic> parameters;

  factory ProviderRequestItem.fromMap(Map<String, dynamic> map) {
    return ProviderRequestItem(
      sceneId: (map['scene_id'] ?? '').toString(),
      provider: (map['provider'] ?? '').toString(),
      endpoint: (map['endpoint'] ?? '').toString(),
      parameters: Map.unmodifiable(
        map['parameters'] is Map ? Map<String, dynamic>.from(map['parameters'] as Map) : {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scene_id': sceneId,
      'provider': provider,
      'endpoint': endpoint,
      'parameters': parameters,
    };
  }
}

@immutable
class ProviderRequestModel {
  const ProviderRequestModel({
    this.requests = const [],
  });

  final List<ProviderRequestItem> requests;

  factory ProviderRequestModel.fromMap(Map<String, dynamic> map) {
    final rawList = map['requests'];
    final items = <ProviderRequestItem>[];
    if (rawList is Iterable) {
      for (final item in rawList) {
        if (item is Map) {
          items.add(ProviderRequestItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return ProviderRequestModel(requests: List.unmodifiable(items));
  }

  Map<String, dynamic> toMap() {
    return {
      'requests': requests.map((r) => r.toMap()).toList(),
    };
  }
}
