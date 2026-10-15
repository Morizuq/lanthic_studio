import 'package:meta/meta.dart';

enum ValidationVerdict {
  pass,
  warn,
  fail;

  static ValidationVerdict fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'approved':
      case 'pass':
        return ValidationVerdict.pass;
      case 'rejected':
      case 'fail':
        return ValidationVerdict.fail;
      case 'warning':
      case 'warn':
      default:
        return ValidationVerdict.warn;
    }
  }
}

@immutable
class VisualValidationRecord {
  const VisualValidationRecord({
    required this.sceneId,
    required this.version,
    required this.verdict,
    this.flags = const [],
    this.critique = '',
    this.remediationGuidance,
  });

  final String sceneId;
  final int version;
  final ValidationVerdict verdict;
  final List<String> flags;
  final String critique;
  final String? remediationGuidance;

  factory VisualValidationRecord.fromMap(Map<String, dynamic> map, [int fallbackVersion = 1]) {
    final flagList = <String>[];
    final rawFlags = map['flags'];
    if (rawFlags is Iterable) {
      for (final f in rawFlags) {
        flagList.add(f.toString());
      }
    }

    final rawEvals = map['evaluations'];
    final evalCritiqueParts = <String>[];
    if (rawEvals is Map) {
      for (final entry in rawEvals.entries) {
        if (entry.value is Map) {
          final evalMap = entry.value as Map;
          final status = evalMap['status']?.toString().toLowerCase();
          final details = evalMap['details']?.toString();
          if (details != null && details.isNotEmpty) {
            if (status == 'fail' || status == 'warn' || status == 'rejected') {
              flagList.add('${entry.key}: $details');
            } else {
              evalCritiqueParts.add(details);
            }
          }
        }
      }
    }

    String critique = (map['critique'] ?? '').toString();
    if (critique.isEmpty && evalCritiqueParts.isNotEmpty) {
      critique = evalCritiqueParts.join(' ');
    }
    String? remediationGuidance;
    final remediation = map['remediation'];
    if (remediation is Map && remediation['guidance'] != null) {
      final guidance = remediation['guidance'].toString();
      if (guidance.isNotEmpty && guidance != 'null') {
        remediationGuidance = guidance;
        critique = critique.isNotEmpty ? '$critique (Remediation: $guidance)' : guidance;
      }
    }

    final version = (map['version'] as num?)?.toInt() ?? fallbackVersion;

    return VisualValidationRecord(
      sceneId: (map['scene_id'] ?? '').toString(),
      version: version,
      verdict: ValidationVerdict.fromString(map['verdict']?.toString()),
      flags: List.unmodifiable(flagList),
      critique: critique,
      remediationGuidance: remediationGuidance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scene_id': sceneId,
      'version': version,
      'verdict': verdict.name,
      'flags': flags,
      'critique': critique,
    };
  }
}

@immutable
class VisualValidationModel {
  const VisualValidationModel({
    this.validations = const [],
  });

  final List<VisualValidationRecord> validations;

  factory VisualValidationModel.fromMap(Map<String, dynamic> map) {
    final validationObj = map['visual_validation'] is Map ? map['visual_validation'] as Map : map;
    final rawList = validationObj['scenes'] ?? validationObj['validations'];
    final items = <VisualValidationRecord>[];
    if (rawList is Iterable) {
      for (final item in rawList) {
        if (item is Map) {
          items.add(VisualValidationRecord.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return VisualValidationModel(validations: List.unmodifiable(items));
  }

  Map<String, dynamic> toMap() {
    return {
      'validations': validations.map((v) => v.toMap()).toList(),
    };
  }

  VisualValidationRecord? latestForScene(String sceneId) {
    final forScene = validations.where((v) => v.sceneId == sceneId).toList()
      ..sort((a, b) => b.version.compareTo(a.version));
    return forScene.isEmpty ? null : forScene.first;
  }

  int get approvedCount => validations.where((v) => v.verdict == ValidationVerdict.pass).length;
  int get rejectedCount => validations.where((v) => v.verdict == ValidationVerdict.fail).length;
  int get warningCount => validations.where((v) => v.verdict == ValidationVerdict.warn).length;
}
