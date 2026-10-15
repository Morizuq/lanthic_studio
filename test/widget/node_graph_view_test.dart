import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/data/repositories/disk_project_repository.dart';
import 'package:lanthic_studio/data/yaml/schema_registry.dart';
import 'package:lanthic_studio/data/yaml/schema_validator.dart';
import 'package:lanthic_studio/domain/models/aggregated_scene.dart';
import 'package:lanthic_studio/features/graph/models/studio_graph_models.dart';
import 'package:lanthic_studio/features/graph/screens/studio_node_graph_view.dart';
import 'package:lanthic_studio/features/graph/widgets/graph_node_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StoryProject sampleProject;

  setUpAll(() async {
    final sampleStoryPath = '${Directory.current.path}/test/fixtures/sample_story';
    final validator = SchemaValidator();
    final registry = SchemaRegistry(validator);
    final repo = DiskProjectRepository(schemaRegistry: registry);
    sampleProject = await repo.loadProject(sampleStoryPath);
  });

  testWidgets('StudioNodeGraphView renders interactive nodes and controls', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StudioNodeGraphView(project: sampleProject),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify HUD elements
    expect(find.text('Node Pipeline Canvas'), findsOneWidget);
    expect(find.text('Narrative'), findsOneWidget);
    expect(find.text('Continuity'), findsOneWidget);
    expect(find.text('Generation'), findsOneWidget);
    expect(find.text('Cook Graph'), findsOneWidget);
    expect(find.text('HF Inference (FLUX)'), findsWidgets);

    // Verify Story Node Card
    expect(find.text('Story Narrative Root'), findsOneWidget);

    // Verify GraphNodeCards are rendered
    expect(find.byType(GraphNodeCard), findsWidgets);

    // Tap model chip to toggle to FLUX Pro
    await tester.tap(find.text('FLUX Pro').first);
    await tester.pump();

    // Verify Cook button exists and can be tapped
    await tester.tap(find.text('Cook Graph'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });

  test('StudioGraphCable and StudioGraphNode instantiate correctly', () {
    final node = StudioGraphNode(
      id: 'test_node',
      title: 'Prompt Synthesizer',
      subtitle: 'Parameters',
      nodeType: GraphNodeType.prompt,
      position: const Offset(100, 200),
      promptText: 'Test prompt synthesis',
      modelProvider: 'qwen',
    );

    expect(node.id, equals('test_node'));
    expect(node.nodeType, equals(GraphNodeType.prompt));
    expect(node.modelProvider, equals('qwen'));

    final cable = StudioGraphCable(
      id: 'c1',
      fromNodeId: 'test_node',
      toNodeId: 'node_gen',
    );
    expect(cable.color, equals(const Color(0xFF00E5FF)));
  });
}
