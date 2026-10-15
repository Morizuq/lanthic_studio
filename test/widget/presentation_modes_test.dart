import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanthic_studio/data/repositories/disk_project_repository.dart';
import 'package:lanthic_studio/data/yaml/schema_registry.dart';
import 'package:lanthic_studio/data/yaml/schema_validator.dart';
import 'package:lanthic_studio/domain/models/aggregated_scene.dart';
import 'package:lanthic_studio/features/project/providers/project_providers.dart';
import 'package:lanthic_studio/features/project/screens/project_shell_screen.dart';
import 'package:lanthic_studio/features/project/widgets/studio_left_nav.dart';

class _LoadedProjectNotifier extends ProjectNotifier {
  _LoadedProjectNotifier(this._project);
  final StoryProject _project;

  @override
  Future<StoryProject?> build() async => _project;
}

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

  testWidgets(
      'ProjectShellScreen navigates across Review, Reader, Continuity, and Pipeline modes',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectStateNotifierProvider
              .overrideWith(() => _LoadedProjectNotifier(sampleProject)),
        ],
        child: const MaterialApp(
          home: ProjectShellScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Initial State: Review mode
    expect(find.text('Deep Orbit Protocol'), findsOneWidget);
    expect(find.text('FLUX'), findsOneWidget);
    expect(find.text('Scenes'), findsWidgets);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Reader'), findsOneWidget);
    expect(find.text('Continuity'), findsOneWidget);
    expect(find.text('Pipeline'), findsOneWidget);

    // Verify Scene Inspector tabs are rendered
    expect(find.widgetWithText(Tab, 'Scene'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Style'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Export'), findsOneWidget);

    // 2. Switch to Reader mode
    await tester.tap(find.text('Reader'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sequential Comic Reader'), findsOneWidget);
    expect(find.text('2 PANELS'), findsOneWidget);
    expect(find.byType(StudioLeftNav), findsOneWidget);

    // 3. Switch to Continuity mode
    await tester.tap(find.text('Continuity'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
        find.text('Phase 01: Canonical Story (canonical_story.md)'), findsOneWidget);
    expect(
        find.text('Phase 03: Entity Continuity (continuity.yaml)'), findsOneWidget);
    expect(find.byType(StudioLeftNav), findsOneWidget);

    // 4. Switch to Pipeline mode
    await tester.tap(find.text('Pipeline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Lanthic Skills Engine • Pipeline Architecture'), findsOneWidget);
    expect(find.text('Storytelling'), findsOneWidget);
    expect(find.text('Scene Extraction'), findsOneWidget);
    expect(find.text('Prompt Synthesis'), findsOneWidget);
    expect(find.text('Vision Validation'), findsOneWidget);
    expect(find.byType(StudioLeftNav), findsOneWidget);

    // 5. Navigate back to Review mode using Left Nav Scenes item
    await tester.tap(find.text('Scenes').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.widgetWithText(Tab, 'Scene'), findsOneWidget);
  });
}
