import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/console_analytics_service.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_credential_store.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/providers/flux_image_provider.dart';
import '../../../data/providers/provider_registry.dart';
import '../../../data/providers/qwen_image_provider.dart';
import '../../../data/repositories/disk_project_repository.dart';
import '../../../data/yaml/schema_registry.dart';
import '../../../data/yaml/schema_validator.dart';
import '../../../domain/models/aggregated_scene.dart';
import '../../../domain/models/scene_model.dart';
import '../../../domain/models/studio_models.dart';
import '../../../domain/repositories/image_provider_contract.dart';
import '../../../domain/repositories/project_repository.dart';
import '../../regenerate/regeneration_service.dart';

final schemaValidatorProvider = Provider<SchemaValidator>((ref) {
  return SchemaValidator();
});

final schemaRegistryProvider = Provider<SchemaRegistry>((ref) {
  final validator = ref.watch(schemaValidatorProvider);
  return SchemaRegistry(validator);
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final registry = ref.watch(schemaRegistryProvider);
  return DiskProjectRepository(schemaRegistry: registry);
});

final credentialStoreProvider = Provider<CredentialStore>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return SecureCredentialStore(storageService: storageService);
});

final providerRegistryProvider = Provider<ProviderRegistry>((ref) {
  final dio = ref.watch(dioProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return ProviderRegistry(
    customProviders: {
      'qwen': QwenImageProvider(dio: dio, analytics: analytics),
      'flux': FluxImageProvider(dio: dio),
    },
  );
});

class ActiveImageProviderNotifier extends Notifier<String> {
  @override
  String build() => 'qwen';

  void selectProvider(String providerId) {
    state = providerId.toLowerCase();
  }
}

final activeImageProviderIdProvider =
    NotifierProvider<ActiveImageProviderNotifier, String>(
      ActiveImageProviderNotifier.new,
    );

final availableProvidersProvider = Provider<List<ImageProviderContract>>((ref) {
  final registry = ref.watch(providerRegistryProvider);
  return registry.allProviders;
});

final activeImageProviderContractProvider = Provider<ImageProviderContract>((
  ref,
) {
  final registry = ref.watch(providerRegistryProvider);
  final activeId = ref.watch(activeImageProviderIdProvider);
  return registry.getProvider(activeId) ?? registry.defaultProvider;
});

final regenerationServiceProvider = Provider<RegenerationService>((ref) {
  return RegenerationService(
    projectRepository: ref.watch(projectRepositoryProvider),
    credentialStore: ref.watch(credentialStoreProvider),
    providerRegistry: ref.watch(providerRegistryProvider),
  );
});

enum StudioViewMode { review, graph, reader, continuity, pipeline }

class StudioViewModeNotifier extends Notifier<StudioViewMode> {
  @override
  StudioViewMode build() => StudioViewMode.review;

  void setMode(StudioViewMode mode) => state = mode;
}

final studioViewModeProvider =
    NotifierProvider<StudioViewModeNotifier, StudioViewMode>(
      StudioViewModeNotifier.new,
    );

class SelectedSceneIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedSceneIdProvider =
    NotifierProvider<SelectedSceneIdNotifier, String?>(
      SelectedSceneIdNotifier.new,
    );

final activeSceneProvider = Provider<AggregatedScene?>((ref) {
  final project = ref.watch(projectStateNotifierProvider).value;
  if (project == null) return null;
  final selectedId = ref.watch(selectedSceneIdProvider);
  if (selectedId != null) {
    final scene = project.sceneById(selectedId);
    if (scene != null) return scene;
  }
  return project.scenes.isNotEmpty ? project.scenes.first : null;
});

class ProjectNotifier extends AsyncNotifier<StoryProject?> {
  @override
  Future<StoryProject?> build() async => null;

  Future<void> openProject(String path) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(projectRepositoryProvider);
      return await repo.loadProject(path);
    });
  }

  Future<void> refreshProject() async {
    final current = state.value;
    if (current == null) return;
    await openProject(current.rootPath);
  }

  void resetToEmpty() {
    state = const AsyncValue.data(null);
  }

  Future<void> updateSelectedVersion({
    required String sceneId,
    required int version,
  }) async {
    final current = state.value;
    if (current == null) return;

    final existingList = List<SceneApprovalItem>.from(
      current.approvals.approvals,
    );
    final index = existingList.indexWhere((a) => a.sceneId == sceneId);

    final currentItem = index >= 0 ? existingList[index] : null;
    final updatedItem = SceneApprovalItem(
      sceneId: sceneId,
      status: currentItem?.status ?? ApprovalStatus.pending,
      selectedVersion: version,
      promptOverride: currentItem?.promptOverride,
      reviewNotes: currentItem?.reviewNotes ?? '',
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );

    if (index >= 0) {
      existingList[index] = updatedItem;
    } else {
      existingList.add(updatedItem);
    }

    final newApprovals = StudioApprovalsModel(
      schemaVersion: current.approvals.schemaVersion,
      approvals: List.unmodifiable(existingList),
    );

    final repo = ref.read(projectRepositoryProvider);
    await repo.saveApprovals(current.rootPath, newApprovals);
    await refreshProject();
  }

  Future<void> updateSceneApproval({
    required String sceneId,
    required ApprovalStatus status,
    String? promptOverride,
    String? reviewNotes,
  }) async {
    final current = state.value;
    if (current == null) return;

    final existingList = List<SceneApprovalItem>.from(
      current.approvals.approvals,
    );
    final index = existingList.indexWhere((a) => a.sceneId == sceneId);

    final updatedItem = SceneApprovalItem(
      sceneId: sceneId,
      status: status,
      selectedVersion: current.sceneById(sceneId)?.selectedVersion ?? 1,
      promptOverride: promptOverride,
      reviewNotes: reviewNotes ?? '',
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );

    if (index >= 0) {
      existingList[index] = updatedItem;
    } else {
      existingList.add(updatedItem);
    }

    final newApprovals = StudioApprovalsModel(
      schemaVersion: current.approvals.schemaVersion,
      approvals: List.unmodifiable(existingList),
    );

    final repo = ref.read(projectRepositoryProvider);
    await repo.saveApprovals(current.rootPath, newApprovals);
    await refreshProject();
  }

  Future<void> addSceneDraft({
    required String title,
    required String description,
    required String setting,
  }) async {
    final current = state.value;
    if (current == null) return;

    final nextSeq = current.scenes.length + 1;
    final sceneId = 'scene_${nextSeq.toString().padLeft(2, '0')}';
    final newSceneModel = SceneModel(
      sceneId: sceneId,
      sequence: nextSeq,
      title: title,
      slug: title.toLowerCase().replaceAll(' ', '_'),
      description: description,
      setting: setting,
    );

    final newScene = AggregatedScene(
      sceneId: sceneId,
      sequence: nextSeq,
      sceneModel: newSceneModel,
      approval: SceneApprovalItem(
        sceneId: sceneId,
        status: ApprovalStatus.pending,
        selectedVersion: 1,
        reviewNotes: 'Created in studio',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );

    final updatedScenes = [...current.scenes, newScene];
    final updatedApprovals = StudioApprovalsModel(
      schemaVersion: current.approvals.schemaVersion,
      approvals: [...current.approvals.approvals, newScene.approval!],
    );

    final updatedProject = StoryProject(
      rootPath: current.rootPath,
      manifest: current.manifest,
      canonicalStory: current.canonicalStory,
      scenes: List.unmodifiable(updatedScenes),
      continuity: current.continuity,
      visualDirection: current.visualDirection,
      generationManifest: current.generationManifest,
      visualValidation: current.visualValidation,
      approvals: updatedApprovals,
      layout: current.layout,
      lettering: current.lettering,
      projectFlags: current.projectFlags,
    );

    state = AsyncValue.data(updatedProject);
    ref.read(selectedSceneIdProvider.notifier).select(sceneId);
    final repo = ref.read(projectRepositoryProvider);
    await repo.saveApprovals(current.rootPath, updatedApprovals);
  }

  Future<void> addSceneDialogue({
    required String sceneId,
    required String speaker,
    required String text,
  }) async {
    final current = state.value;
    if (current == null) return;

    final updatedScenes = current.scenes.map((scene) {
      if (scene.sceneId != sceneId) return scene;
      final newDialogue = [
        ...scene.sceneModel.dialogue,
        DialogueLine(speaker: speaker, text: text),
      ];
      final updatedModel = SceneModel(
        sceneId: scene.sceneId,
        sequence: scene.sequence,
        title: scene.sceneModel.title,
        slug: scene.sceneModel.slug,
        description: scene.sceneModel.description,
        setting: scene.sceneModel.setting,
        characters: scene.sceneModel.characters.contains(speaker)
            ? scene.sceneModel.characters
            : [...scene.sceneModel.characters, speaker],
        dialogue: List.unmodifiable(newDialogue),
      );
      return AggregatedScene(
        sceneId: scene.sceneId,
        sequence: scene.sequence,
        sceneModel: updatedModel,
        imagePrompt: scene.imagePrompt,
        visualDirection: scene.visualDirection,
        validationRecord: scene.validationRecord,
        approval: scene.approval,
        assetVersions: scene.assetVersions,
        flags: scene.flags,
        dialogueBubbles: scene.dialogueBubbles,
      );
    }).toList();

    state = AsyncValue.data(
      StoryProject(
        rootPath: current.rootPath,
        manifest: current.manifest,
        canonicalStory: current.canonicalStory,
        scenes: List.unmodifiable(updatedScenes),
        continuity: current.continuity,
        visualDirection: current.visualDirection,
        generationManifest: current.generationManifest,
        visualValidation: current.visualValidation,
        approvals: current.approvals,
        layout: current.layout,
        lettering: current.lettering,
        projectFlags: current.projectFlags,
      ),
    );
  }
}

final projectStateNotifierProvider =
    AsyncNotifierProvider<ProjectNotifier, StoryProject?>(ProjectNotifier.new);
