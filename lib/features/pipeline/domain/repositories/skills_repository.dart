class SkillDefinition {
  const SkillDefinition({
    required this.phaseNumber,
    required this.name,
    required this.directoryName,
    required this.instructionContent,
    this.authoritativeFileName,
  });

  final String phaseNumber;
  final String name;
  final String directoryName;
  final String instructionContent;
  final String? authoritativeFileName;
}

abstract class SkillsRepository {
  Future<bool> isSkillsSourceAvailable();
  Future<String> getSourceDescription();
  Future<Map<String, String>> loadAllSkills();
  Future<void> syncRemoteSkills({
    required String githubPat,
    required String repositoryOwnerAndName,
    String branch = 'main',
  });
  Future<void> setLocalSkillsDirectory(String path);
}
