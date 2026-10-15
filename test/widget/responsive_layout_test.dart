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

  final testViewports = [
    const Size(600, 500),
    const Size(750, 600),
    const Size(900, 650),
    const Size(1200, 800),
    const Size(1600, 900),
  ];

  for (final size in testViewports) {
    testWidgets(
      'ProjectShellScreen renders without any overflow at width ${size.width.toInt()}x${size.height.toInt()}',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        FlutterErrorDetails? caughtDetails;
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
        };

        try {
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
        } finally {
          FlutterError.onError = oldHandler;
        }

        // Expect no RenderFlex exceptions were thrown across viewports
        expect(caughtDetails, isNull);
      },
    );
  }
}
