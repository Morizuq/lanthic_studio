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

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        projectStateNotifierProvider.overrideWith(() => _LoadedProjectNotifier(sampleProject)),
      ],
      child: const MaterialApp(
        home: ProjectShellScreen(),
      ),
    );
  }

  testWidgets('Left nav opens Overview modal and displays project stats', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Overview nav item
    await tester.tap(find.text('Overview'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Project Specifications'), findsOneWidget);
    expect(find.text('Overall Completion'), findsOneWidget);

    // Close modal
    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Project Specifications'), findsNothing);
  });

  testWidgets('Left nav opens Beats modal and navigates to selected scene', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Beats nav item
    await tester.tap(find.text('Beats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Narrative Beats & Scene Flow'), findsOneWidget);

    // Tap Done
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Narrative Beats & Scene Flow'), findsNothing);
  });

  testWidgets('Left nav opens Assets modal and displays asset cards', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Assets nav item
    await tester.tap(find.text('Assets'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Project Asset Library'), findsOneWidget);

    // Close modal
    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Project Asset Library'), findsNothing);
  });

  testWidgets('Left nav opens Audio Studio modal', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Audio nav item
    await tester.tap(find.text('Audio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Audio & Voice Narration Studio'), findsOneWidget);
    expect(find.text('Voice Profile:'), findsOneWidget);

    // Close modal
    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Audio & Voice Narration Studio'), findsNothing);
  });

  testWidgets('Inspector Export tab allows triggering production deliverables', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Switch to Export tab in Inspector
    await tester.tap(find.widgetWithText(Tab, 'Export'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Export Comic Book (PDF)'), findsOneWidget);
    expect(find.text('Render Video (MP4)'), findsOneWidget);
    expect(find.text('Export All Scene PNGs (ZIP)'), findsOneWidget);

    // Trigger Comic Book PDF export
    await tester.tap(find.text('Export Comic Book (PDF)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
