import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/storage/secure_credential_store.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/repositories/skills_repository.dart';

class HybridSkillsRepository implements SkillsRepository {
  HybridSkillsRepository({
    required this.credentialStore,
    required this.storage,
    Dio? dio,
  }) : dio = dio ?? Dio();

  final CredentialStore credentialStore;
  final StorageService storage;
  final Dio dio;

  static const String _prefKeyLocalSkillsPath = 'lanthic_local_skills_path';
  static const String _defaultLocalRepoPath = '/Users/mac/Projects/lanthic-skills';
  static const String _githubPatProvider = 'github_pat';

  Directory get _cacheDirectory {
    final home = Platform.environment['HOME'] ?? '';
    return Directory('$home/.lanthic_studio/skills_cache');
  }

  @override
  Future<void> setLocalSkillsDirectory(String path) async {
    await storage.setString(_prefKeyLocalSkillsPath, path);
  }

  Future<String?> _resolveConfiguredOrDiscoveredPath() async {
    final configured = storage.getString(_prefKeyLocalSkillsPath);
    if (configured != null && Directory('$configured/skills').existsSync()) {
      return configured;
    }

    if (Directory('$_defaultLocalRepoPath/skills').existsSync()) {
      return _defaultLocalRepoPath;
    }

    final parentCandidate = '${Directory.current.parent.path}/lanthic-skills';
    if (Directory('$parentCandidate/skills').existsSync()) {
      return parentCandidate;
    }

    if (_cacheDirectory.existsSync()) {
      return _cacheDirectory.path;
    }

    return null;
  }

  @override
  Future<bool> isSkillsSourceAvailable() async {
    final path = await _resolveConfiguredOrDiscoveredPath();
    if (path != null) return true;

    final pat = await credentialStore.readApiKey(_githubPatProvider);
    return pat != null && pat.isNotEmpty;
  }

  @override
  Future<String> getSourceDescription() async {
    final path = await _resolveConfiguredOrDiscoveredPath();
    if (path != null) {
      if (path == _cacheDirectory.path) {
        return 'Synced from GitHub (Local Cache)';
      }
      return 'Local Repository ($path)';
    }

    final pat = await credentialStore.readApiKey(_githubPatProvider);
    if (pat != null && pat.isNotEmpty) {
      return 'Configured for Remote GitHub Sync';
    }

    return 'No Skills Source Configured';
  }

  @override
  Future<Map<String, String>> loadAllSkills() async {
    final basePath = await _resolveConfiguredOrDiscoveredPath();
    final skillsMap = <String, String>{};

    if (basePath != null) {
      final skillsDir = Directory('$basePath/skills');
      if (skillsDir.existsSync()) {
        final entities = skillsDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.md')) {
            final relative = entity.path.substring(skillsDir.path.length + 1);
            skillsMap[relative] = await entity.readAsString();
          }
        }
      }
    }

    return skillsMap;
  }

  @override
  Future<void> syncRemoteSkills({
    required String githubPat,
    required String repositoryOwnerAndName,
    String branch = 'main',
  }) async {
    await credentialStore.writeApiKey(_githubPatProvider, githubPat);

    final cacheDir = _cacheDirectory;
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }

    final skillsCacheDir = Directory('${cacheDir.path}/skills');
    if (!skillsCacheDir.existsSync()) {
      skillsCacheDir.createSync(recursive: true);
    }

    final response = await dio.get<dynamic>(
      'https://api.github.com/repos/$repositoryOwnerAndName/contents/skills?ref=$branch',
      options: Options(
        headers: {
          'Authorization': 'Bearer $githubPat',
          'Accept': 'application/vnd.github.v3+json',
        },
      ),
    );

    if (response.data is List) {
      for (final item in response.data as List) {
        if (item is Map<String, dynamic> && item['type'] == 'dir') {
          final dirName = item['name'] as String;
          final subDir = Directory('${skillsCacheDir.path}/$dirName');
          if (!subDir.existsSync()) {
            subDir.createSync(recursive: true);
          }

          // Fetch directory contents
          final subResponse = await dio.get<dynamic>(
            item['url'] as String,
            options: Options(
              headers: {
                'Authorization': 'Bearer $githubPat',
                'Accept': 'application/vnd.github.v3+json',
              },
            ),
          );

          if (subResponse.data is List) {
            for (final fileItem in subResponse.data as List) {
              if (fileItem is Map<String, dynamic> &&
                  fileItem['type'] == 'file' &&
                  fileItem['download_url'] != null) {
                final fileDownloadResponse = await dio.get<String>(
                  fileItem['download_url'] as String,
                  options: Options(
                    headers: {'Authorization': 'Bearer $githubPat'},
                    responseType: ResponseType.plain,
                  ),
                );
                final targetFile = File('${subDir.path}/${fileItem['name']}');
                await targetFile.writeAsString(fileDownloadResponse.data ?? '');
              }
            }
          }
        }
      }
    }
  }
}
