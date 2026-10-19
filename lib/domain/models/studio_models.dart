import 'package:meta/meta.dart';

enum ApprovalStatus {
  pending,
  approved,
  rejected,
  needsRegen;

  static ApprovalStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'needs_regen':
      case 'needsregen':
        return ApprovalStatus.needsRegen;
      case 'pending':
      default:
        return ApprovalStatus.pending;
    }
  }

  String toSerializedString() {
    switch (this) {
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.rejected:
        return 'rejected';
      case ApprovalStatus.needsRegen:
        return 'needs_regen';
      case ApprovalStatus.pending:
        return 'pending';
    }
  }
}

@immutable
class SceneApprovalItem {
  const SceneApprovalItem({
    required this.sceneId,
    required this.status,
    this.selectedVersion = 1,
    this.promptOverride,
    this.reviewNotes = '',
    this.updatedAt = '',
  });

  final String sceneId;
  final ApprovalStatus status;
  final int selectedVersion;
  final String? promptOverride;
  final String reviewNotes;
  final String updatedAt;

  factory SceneApprovalItem.fromMap(Map<String, dynamic> map) {
    return SceneApprovalItem(
      sceneId: (map['scene_id'] ?? '').toString(),
      status: ApprovalStatus.fromString(map['status']?.toString()),
      selectedVersion: (map['selected_version'] as num?)?.toInt() ?? 1,
      promptOverride: map['prompt_override']?.toString(),
      reviewNotes: (map['review_notes'] ?? '').toString(),
      updatedAt: (map['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scene_id': sceneId,
      'status': status.toSerializedString(),
      'selected_version': selectedVersion,
      if (promptOverride != null) 'prompt_override': promptOverride,
      'review_notes': reviewNotes,
      'updated_at': updatedAt,
    };
  }

  SceneApprovalItem copyWith({
    ApprovalStatus? status,
    int? selectedVersion,
    String? promptOverride,
    String? reviewNotes,
    String? updatedAt,
  }) {
    return SceneApprovalItem(
      sceneId: sceneId,
      status: status ?? this.status,
      selectedVersion: selectedVersion ?? this.selectedVersion,
      promptOverride: promptOverride ?? this.promptOverride,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class StudioApprovalsModel {
  const StudioApprovalsModel({
    this.schemaVersion = '1.0.0',
    this.approvals = const [],
  });

  final String schemaVersion;
  final List<SceneApprovalItem> approvals;

  factory StudioApprovalsModel.fromMap(Map<String, dynamic> map) {
    final rawList = map['approvals'];
    final items = <SceneApprovalItem>[];
    if (rawList is Iterable) {
      for (final item in rawList) {
        if (item is Map) {
          items.add(SceneApprovalItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return StudioApprovalsModel(
      schemaVersion: (map['schema_version'] ?? '1.0.0').toString(),
      approvals: List.unmodifiable(items),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schema_version': schemaVersion,
      'approvals': approvals.map((a) => a.toMap()).toList(),
    };
  }

  SceneApprovalItem? forScene(String sceneId) {
    for (final a in approvals) {
      if (a.sceneId == sceneId) return a;
    }
    return null;
  }
}

@immutable
class PanelCrop {
  const PanelCrop({this.x = 0.0, this.y = 0.0, this.w = 1.0, this.h = 1.0});

  final double x;
  final double y;
  final double w;
  final double h;

  factory PanelCrop.fromMap(Map<String, dynamic> map) {
    return PanelCrop(
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      w: (map['w'] as num?)?.toDouble() ?? 1.0,
      h: (map['h'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() => {'x': x, 'y': y, 'w': w, 'h': h};
}

@immutable
class PanelSlot {
  const PanelSlot({
    required this.slot,
    required this.sceneId,
    required this.asset,
    this.crop = const PanelCrop(),
  });

  final int slot;
  final String sceneId;
  final String asset;
  final PanelCrop crop;

  factory PanelSlot.fromMap(Map<String, dynamic> map) {
    return PanelSlot(
      slot: (map['slot'] as num?)?.toInt() ?? 0,
      sceneId: (map['scene_id'] ?? '').toString(),
      asset: (map['asset'] ?? '').toString(),
      crop: map['crop'] is Map
          ? PanelCrop.fromMap(Map<String, dynamic>.from(map['crop'] as Map))
          : const PanelCrop(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slot': slot,
      'scene_id': sceneId,
      'asset': asset,
      'crop': crop.toMap(),
    };
  }
}

@immutable
class PageLayout {
  const PageLayout({
    required this.page,
    required this.template,
    this.panels = const [],
  });

  final int page;
  final String template;
  final List<PanelSlot> panels;

  factory PageLayout.fromMap(Map<String, dynamic> map) {
    final rawPanels = map['panels'];
    final panelList = <PanelSlot>[];
    if (rawPanels is Iterable) {
      for (final p in rawPanels) {
        if (p is Map) {
          panelList.add(PanelSlot.fromMap(Map<String, dynamic>.from(p)));
        }
      }
    }
    return PageLayout(
      page: (map['page'] as num?)?.toInt() ?? 1,
      template: (map['template'] ?? 'grid_2x2').toString(),
      panels: List.unmodifiable(panelList),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'page': page,
      'template': template,
      'panels': panels.map((p) => p.toMap()).toList(),
    };
  }
}

@immutable
class StudioLayoutModel {
  const StudioLayoutModel({
    this.schemaVersion = '1.0.0',
    this.pages = const [],
  });

  final String schemaVersion;
  final List<PageLayout> pages;

  factory StudioLayoutModel.fromMap(Map<String, dynamic> map) {
    final rawPages = map['pages'];
    final pageList = <PageLayout>[];
    if (rawPages is Iterable) {
      for (final p in rawPages) {
        if (p is Map) {
          pageList.add(PageLayout.fromMap(Map<String, dynamic>.from(p)));
        }
      }
    }
    return StudioLayoutModel(
      schemaVersion: (map['schema_version'] ?? '1.0.0').toString(),
      pages: List.unmodifiable(pageList),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schema_version': schemaVersion,
      'pages': pages.map((p) => p.toMap()).toList(),
    };
  }
}

enum BubbleType {
  speech,
  thought,
  caption,
  soundFx;

  static BubbleType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'thought':
        return BubbleType.thought;
      case 'caption':
        return BubbleType.caption;
      case 'sound_fx':
      case 'soundfx':
      case 'sfx':
        return BubbleType.soundFx;
      case 'speech':
      default:
        return BubbleType.speech;
    }
  }

  String get yamlValue {
    switch (this) {
      case BubbleType.soundFx:
        return 'sound_fx';
      case BubbleType.thought:
        return 'thought';
      case BubbleType.caption:
        return 'caption';
      case BubbleType.speech:
        return 'speech';
    }
  }
}

@immutable
class DialogueBubble {
  const DialogueBubble({
    required this.bubbleId,
    required this.sceneId,
    required this.type,
    required this.text,
    required this.x,
    required this.y,
    this.speaker = '',
    this.width = 0.3,
    this.height = 0.15,
    this.tailTargetX = 0.5,
    this.tailTargetY = 0.5,
  });

  final String bubbleId;
  final String sceneId;
  final BubbleType type;
  final String text;
  final double x;
  final double y;
  final String speaker;
  final double width;
  final double height;
  final double tailTargetX;
  final double tailTargetY;

  factory DialogueBubble.fromMap(Map<String, dynamic> map) {
    return DialogueBubble(
      bubbleId: (map['bubble_id'] ?? '').toString(),
      sceneId: (map['scene_id'] ?? '').toString(),
      type: BubbleType.fromString(map['type']?.toString()),
      text: (map['text'] ?? '').toString(),
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      speaker: (map['speaker'] ?? '').toString(),
      width: (map['width'] as num?)?.toDouble() ?? 0.3,
      height: (map['height'] as num?)?.toDouble() ?? 0.15,
      tailTargetX: (map['tail_target_x'] as num?)?.toDouble() ?? 0.5,
      tailTargetY: (map['tail_target_y'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bubble_id': bubbleId,
      'scene_id': sceneId,
      'type': type.yamlValue,
      if (speaker.isNotEmpty) 'speaker': speaker,
      'text': text,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'tail_target_x': tailTargetX,
      'tail_target_y': tailTargetY,
    };
  }
}

@immutable
class StudioLetteringModel {
  const StudioLetteringModel({
    this.schemaVersion = '1.0.0',
    this.bubbles = const [],
  });

  final String schemaVersion;
  final List<DialogueBubble> bubbles;

  factory StudioLetteringModel.fromMap(Map<String, dynamic> map) {
    final rawBubbles = map['bubbles'];
    final bubbleList = <DialogueBubble>[];
    if (rawBubbles is Iterable) {
      for (final b in rawBubbles) {
        if (b is Map) {
          bubbleList.add(DialogueBubble.fromMap(Map<String, dynamic>.from(b)));
        }
      }
    }
    return StudioLetteringModel(
      schemaVersion: (map['schema_version'] ?? '1.0.0').toString(),
      bubbles: List.unmodifiable(bubbleList),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schema_version': schemaVersion,
      'bubbles': bubbles.map((b) => b.toMap()).toList(),
    };
  }

  List<DialogueBubble> forScene(String sceneId) {
    return bubbles.where((b) => b.sceneId == sceneId).toList();
  }
}
