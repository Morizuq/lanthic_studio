enum PipelineRunStatus {
  idle,
  preparing,
  running,
  phaseCompleted,
  failed,
  completed,
}

class PipelineLogEntry {
  const PipelineLogEntry({
    required this.timestamp,
    required this.message,
    this.isError = false,
  });

  final DateTime timestamp;
  final String message;
  final bool isError;
}

class PipelineRunProgress {
  const PipelineRunProgress({
    required this.status,
    required this.currentPhase,
    required this.totalPhases,
    required this.currentPhaseName,
    required this.logs,
    this.storyId = '',
    this.projectDirectory = '',
    this.errorMessage,
    this.artifactsGenerated = const [],
  });

  final PipelineRunStatus status;
  final int currentPhase;
  final int totalPhases;
  final String currentPhaseName;
  final List<PipelineLogEntry> logs;
  final String storyId;
  final String projectDirectory;
  final String? errorMessage;
  final List<String> artifactsGenerated;

  factory PipelineRunProgress.initial() {
    return const PipelineRunProgress(
      status: PipelineRunStatus.idle,
      currentPhase: 0,
      totalPhases: 8,
      currentPhaseName: 'Ready',
      logs: [],
    );
  }

  PipelineRunProgress copyWith({
    PipelineRunStatus? status,
    int? currentPhase,
    int? totalPhases,
    String? currentPhaseName,
    List<PipelineLogEntry>? logs,
    String? storyId,
    String? projectDirectory,
    String? errorMessage,
    List<String>? artifactsGenerated,
  }) {
    return PipelineRunProgress(
      status: status ?? this.status,
      currentPhase: currentPhase ?? this.currentPhase,
      totalPhases: totalPhases ?? this.totalPhases,
      currentPhaseName: currentPhaseName ?? this.currentPhaseName,
      logs: logs ?? this.logs,
      storyId: storyId ?? this.storyId,
      projectDirectory: projectDirectory ?? this.projectDirectory,
      errorMessage: errorMessage ?? this.errorMessage,
      artifactsGenerated: artifactsGenerated ?? this.artifactsGenerated,
    );
  }

  bool get isRunning => status == PipelineRunStatus.running || status == PipelineRunStatus.preparing;
  bool get isCompleted => status == PipelineRunStatus.completed;
  bool get isFailed => status == PipelineRunStatus.failed;
}
