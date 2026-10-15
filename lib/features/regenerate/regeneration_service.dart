import '../../core/errors/failures.dart';
import '../../core/logging/studio_logger.dart';
import '../../core/storage/secure_credential_store.dart';
import '../../domain/models/aggregated_scene.dart';
import '../../domain/repositories/project_repository.dart';
import '../../data/providers/provider_registry.dart';
import 'phase6_payload_builder.dart';

class RegenerationResult {
  const RegenerationResult({
    required this.sceneId,
    required this.newVersion,
    required this.relativeAssetPath,
    required this.promptHash,
    required this.costUsd,
    required this.elapsedMs,
  });

  final String sceneId;
  final int newVersion;
  final String relativeAssetPath;
  final String promptHash;
  final double costUsd;
  final int elapsedMs;
}

class RegenerationService {
  const RegenerationService({
    required this.projectRepository,
    required this.credentialStore,
    required this.providerRegistry,
    this.payloadBuilder = const Phase6PayloadBuilder(),
    this.logger = const ConsoleStudioLogger(),
  });

  final ProjectRepository projectRepository;
  final CredentialStore credentialStore;
  final ProviderRegistry providerRegistry;
  final Phase6PayloadBuilder payloadBuilder;
  final StudioLogger logger;

  Future<RegenerationResult> regenerateScene({
    required StoryProject project,
    required String sceneId,
    String? promptOverride,
    String? providerOverride,
  }) async {
    final effectiveProviderId =
        (providerOverride != null && providerOverride.trim().isNotEmpty)
        ? providerOverride.trim().toLowerCase()
        : (project.manifest.provider.isNotEmpty
              ? project.manifest.provider
              : 'qwen');

    final scene = project.sceneById(sceneId);
    if (scene == null) {
      throw GenerationFailure(
        'Scene $sceneId not found in project',
        sceneId: sceneId,
        provider: effectiveProviderId,
      );
    }

    final provider =
        providerRegistry.getProvider(effectiveProviderId) ??
        providerRegistry.defaultProvider;
    final providerId = provider.providerIdentifier;

    final apiKey = (await credentialStore.readApiKey(providerId)) ?? '';
    if (!provider.isFreeOpenSource && apiKey.trim().isEmpty) {
      throw GenerationFailure(
        'Missing API key for provider $providerId. Configure it in settings.',
        sceneId: sceneId,
        provider: providerId,
      );
    }

    logger.info(
      'Building Phase 6 payload for scene $sceneId using $providerId',
    );
    final payload = payloadBuilder.build(
      sceneId: sceneId,
      prompt: promptOverride ?? scene.effectivePrompt,
      provider: providerId,
      negativePrompt: scene.imagePrompt?.negativePrompt,
      loraTags: scene.imagePrompt?.loraTags ?? const [],
      aspectRatio: scene.imagePrompt?.aspectRatio ?? '16:9',
      visualDirection: scene.visualDirection,
    );

    logger.info('Calling provider $providerId for scene $sceneId');
    final genResult = await provider.generate(
      prompt: payload.prompt,
      apiKey: apiKey,
      extraParameters: payload.parameters,
    );

    logger.info(
      'Saving new asset version for scene $sceneId (size: ${genResult.imageBytes.length} bytes)',
    );
    final relativePath = await projectRepository.saveNewAssetVersion(
      projectDirectoryPath: project.rootPath,
      sceneId: sceneId,
      imageBytes: genResult.imageBytes,
      extension: 'png',
    );

    final newVersion = project.generationManifest.nextVersionForScene(sceneId);

    logger.info(
      'Recording asset $relativePath in generation manifest as version $newVersion',
    );
    await projectRepository.recordAssetInManifest(
      projectDirectoryPath: project.rootPath,
      sceneId: sceneId,
      version: newVersion,
      relativeFilePath: relativePath,
      promptHash: genResult.promptHash,
      provider: providerId,
      costUsd: genResult.costUsd,
    );

    return RegenerationResult(
      sceneId: sceneId,
      newVersion: newVersion,
      relativeAssetPath: relativePath,
      promptHash: genResult.promptHash,
      costUsd: genResult.costUsd,
      elapsedMs: genResult.generationTimeMs,
    );
  }
}
