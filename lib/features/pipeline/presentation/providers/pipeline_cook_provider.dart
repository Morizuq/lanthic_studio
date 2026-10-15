import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../../project/providers/project_providers.dart';
import '../../data/orchestrator/lanthic_pipeline_orchestrator.dart';
import '../../data/sources/hybrid_skills_repository.dart';
import '../../domain/models/pipeline_run_progress.dart';
import '../../domain/repositories/skills_repository.dart';

final skillsRepositoryProvider = Provider<SkillsRepository>((ref) {
  final credentialStore = ref.watch(credentialStoreProvider);
  final storageService = ref.watch(storageServiceProvider);
  final dio = ref.watch(dioProvider);

  return HybridSkillsRepository(
    credentialStore: credentialStore,
    storage: storageService,
    dio: dio,
  );
});

final pipelineOrchestratorProvider = Provider<LanthicPipelineOrchestrator>((ref) {
  final skillsRepo = ref.watch(skillsRepositoryProvider);
  return LanthicPipelineOrchestrator(skillsRepository: skillsRepo);
});

class PipelineCookNotifier extends Notifier<PipelineRunProgress> {
  @override
  PipelineRunProgress build() => PipelineRunProgress.initial();

  void reset() {
    state = PipelineRunProgress.initial();
  }

  Future<void> cookStory({
    required String title,
    required String rawStory,
    String? targetDirectory,
    String provider = 'flux',
  }) async {
    final orchestrator = ref.read(pipelineOrchestratorProvider);
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    final defaultDir = '$home/Documents/LanthicStories';
    final resolvedTarget = targetDirectory ?? defaultDir;

    await orchestrator.runPipeline(
      storyTitle: title,
      rawStory: rawStory,
      targetDirectory: resolvedTarget,
      provider: provider,
      onProgress: (progress) {
        state = progress;
      },
    );
  }

  Future<void> syncRemoteSkills({
    required String githubPat,
    required String repositoryOwnerAndName,
    String branch = 'main',
  }) async {
    final skillsRepo = ref.read(skillsRepositoryProvider);
    await skillsRepo.syncRemoteSkills(
      githubPat: githubPat,
      repositoryOwnerAndName: repositoryOwnerAndName,
      branch: branch,
    );
  }

  Future<void> setLocalSkillsDirectory(String path) async {
    final skillsRepo = ref.read(skillsRepositoryProvider);
    await skillsRepo.setLocalSkillsDirectory(path);
  }
}

final pipelineCookNotifierProvider =
    NotifierProvider<PipelineCookNotifier, PipelineRunProgress>(
  PipelineCookNotifier.new,
);
