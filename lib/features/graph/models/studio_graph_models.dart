import 'package:flutter/material.dart';

enum GraphNodeType {
  story,
  character,
  prompt,
  generator,
}

@immutable
class StudioGraphCable {
  const StudioGraphCable({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.color = const Color(0xFF00E5FF),
    this.label = '',
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final Color color;
  final String label;
}

class StudioGraphNode {
  StudioGraphNode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.nodeType,
    required this.position,
    this.promptText,
    this.imagePath,
    this.modelProvider = 'qwen',
    this.status = 'Ready',
    this.sceneId,
    this.characterName,
  });

  final String id;
  final String title;
  final String subtitle;
  final GraphNodeType nodeType;
  Offset position;
  final String? promptText;
  final String? imagePath;
  String modelProvider; // 'qwen' or 'flux'
  String status;
  final String? sceneId;
  final String? characterName;

  StudioGraphNode copyWith({
    String? title,
    String? subtitle,
    GraphNodeType? nodeType,
    Offset? position,
    String? promptText,
    String? imagePath,
    String? modelProvider,
    String? status,
    String? sceneId,
    String? characterName,
  }) {
    return StudioGraphNode(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      nodeType: nodeType ?? this.nodeType,
      position: position ?? this.position,
      promptText: promptText ?? this.promptText,
      imagePath: imagePath ?? this.imagePath,
      modelProvider: modelProvider ?? this.modelProvider,
      status: status ?? this.status,
      sceneId: sceneId ?? this.sceneId,
      characterName: characterName ?? this.characterName,
    );
  }
}
