enum AppEnvironment {
  dev,
  stage,
  prod;

  bool get isDev => this == dev;
  bool get isStage => this == stage;
  bool get isProd => this == prod;

  static AppEnvironment fromString(String name) {
    switch (name) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'stage':
      case 'staging':
        return AppEnvironment.stage;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.dev;
    }
  }
}
