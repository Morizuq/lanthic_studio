import 'package:meta/meta.dart';

@immutable
class CharacterContinuity {
  const CharacterContinuity({
    required this.name,
    this.id = '',
    this.type = 'character',
    this.appearance = '',
    this.clothing = '',
    this.distinguishingFeatures = const [],
    this.identity = const {},
  });

  final String name;
  final String id;
  final String type;
  final String appearance;
  final String clothing;
  final List<String> distinguishingFeatures;
  final Map<String, dynamic> identity;

  String get displayName => name.isNotEmpty ? name : id;

  factory CharacterContinuity.fromMap(Map<String, dynamic> map) {
    final rawFeatures = map['distinguishing_features'];
    final features = <String>[];
    if (rawFeatures is Iterable) {
      for (final f in rawFeatures) {
        features.add(f.toString());
      }
    }

    final rawIdentity = map['identity'];
    final identityMap = <String, dynamic>{};
    if (rawIdentity is Map) {
      for (final e in rawIdentity.entries) {
        if (e.value is Map && (e.value as Map)['value'] != null) {
          identityMap[e.key.toString()] = (e.value as Map)['value'];
        } else {
          identityMap[e.key.toString()] = e.value;
        }
      }
    }

    final id = (map['id'] ?? '').toString();
    final name = (map['name'] ?? id).toString();

    return CharacterContinuity(
      name: name,
      id: id.isNotEmpty ? id : name,
      type: (map['type'] ?? 'character').toString(),
      appearance: (map['appearance'] ?? '').toString(),
      clothing: (map['clothing'] ?? '').toString(),
      distinguishingFeatures: List.unmodifiable(features),
      identity: Map.unmodifiable(identityMap),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
      'type': type,
      'appearance': appearance,
      'clothing': clothing,
      'distinguishing_features': distinguishingFeatures,
      if (identity.isNotEmpty) 'identity': identity,
    };
  }
}

@immutable
class ContinuityEntity {
  const ContinuityEntity({
    required this.id,
    this.type = 'object',
    this.identity = const {},
  });

  final String id;
  final String type;
  final Map<String, dynamic> identity;

  factory ContinuityEntity.fromMap(Map<String, dynamic> map) {
    final rawIdentity = map['identity'];
    final identityMap = <String, dynamic>{};
    if (rawIdentity is Map) {
      for (final e in rawIdentity.entries) {
        if (e.value is Map && (e.value as Map)['value'] != null) {
          identityMap[e.key.toString()] = (e.value as Map)['value'];
        } else {
          identityMap[e.key.toString()] = e.value;
        }
      }
    }

    return ContinuityEntity(
      id: (map['id'] ?? '').toString(),
      type: (map['type'] ?? 'object').toString(),
      identity: Map.unmodifiable(identityMap),
    );
  }
}

@immutable
class ContinuityConstraint {
  const ContinuityConstraint({
    required this.entity,
    required this.rule,
  });

  final String entity;
  final String rule;

  factory ContinuityConstraint.fromMap(Map<String, dynamic> map) {
    return ContinuityConstraint(
      entity: (map['entity'] ?? '').toString(),
      rule: (map['rule'] ?? map['constraint'] ?? '').toString(),
    );
  }
}

@immutable
class ContinuityModel {
  const ContinuityModel({
    this.characters = const [],
    this.objects = const [],
    this.constraints = const [],
    this.worldRules = const [],
  });

  final List<CharacterContinuity> characters;
  final List<ContinuityEntity> objects;
  final List<ContinuityConstraint> constraints;
  final List<String> worldRules;

  factory ContinuityModel.fromMap(Map<String, dynamic> map) {
    final rootMap = map['continuity'] is Map ? map['continuity'] as Map : map;

    final charList = <CharacterContinuity>[];
    final objectList = <ContinuityEntity>[];

    // Check entities list (lanthic-skills format)
    final rawEntities = rootMap['entities'];
    if (rawEntities is Iterable) {
      for (final item in rawEntities) {
        if (item is Map) {
          final itemMap = Map<String, dynamic>.from(item);
          final type = itemMap['type']?.toString();
          if (type == 'character') {
            charList.add(CharacterContinuity.fromMap(itemMap));
          } else {
            objectList.add(ContinuityEntity.fromMap(itemMap));
          }
        }
      }
    }

    // Check characters list (flat format)
    final rawChars = rootMap['characters'];
    if (rawChars is Iterable) {
      for (final item in rawChars) {
        if (item is Map) {
          charList.add(CharacterContinuity.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Constraints
    final constraintList = <ContinuityConstraint>[];
    final rawConstraints = rootMap['constraints'];
    if (rawConstraints is Iterable) {
      for (final c in rawConstraints) {
        if (c is Map) {
          constraintList.add(ContinuityConstraint.fromMap(Map<String, dynamic>.from(c)));
        }
      }
    }

    final rawRules = rootMap['world_rules'];
    final ruleList = <String>[];
    if (rawRules is Iterable) {
      for (final r in rawRules) {
        ruleList.add(r.toString());
      }
    }

    return ContinuityModel(
      characters: List.unmodifiable(charList),
      objects: List.unmodifiable(objectList),
      constraints: List.unmodifiable(constraintList),
      worldRules: List.unmodifiable(ruleList),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'characters': characters.map((c) => c.toMap()).toList(),
      'world_rules': worldRules,
    };
  }
}
