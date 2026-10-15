import '../models/aggregated_scene.dart';
import '../models/studio_models.dart';

abstract class ProjectRepository {
  Future<StoryProject> loadProject(String projectDirectoryPath);
  Future<void> saveApprovals(String projectDirectoryPath, StudioApprovalsModel approvals);
  Future<void> saveLayout(String projectDirectoryPath, StudioLayoutModel layout);
  Future<void> saveLettering(String projectDirectoryPath, StudioLetteringModel lettering);
  Future<String> saveNewAssetVersion({
    required String projectDirectoryPath,
    required String sceneId,
    required List<int> imageBytes,
    required String extension,
  });
  Future<void> recordAssetInManifest({
    required String projectDirectoryPath,
    required String sceneId,
    required int version,
    required String relativeFilePath,
    required String promptHash,
    required String provider,
    double costUsd = 0.0,
  });
}
