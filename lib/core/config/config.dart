import 'app_environment.dart';

class AppConfig {
  const AppConfig({required this.environment, this.serverpodUrl});

  final AppEnvironment environment;
  final String? serverpodUrl;

  bool get hasBackend => serverpodUrl != null && serverpodUrl!.isNotEmpty;

  factory AppConfig.fromEnvironment() {
    const rawEnv = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    const rawServerpodUrl = String.fromEnvironment(
      'SERVERPOD_URL',
      defaultValue: '',
    );

    final env = AppEnvironment.fromString(rawEnv);
    final serverpodUrl = rawServerpodUrl.trim().isNotEmpty
        ? rawServerpodUrl.trim()
        : null;

    return AppConfig(environment: env, serverpodUrl: serverpodUrl);
  }
}
