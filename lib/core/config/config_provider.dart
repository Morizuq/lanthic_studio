import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanthic_studio/core/config/config.dart';

final configProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
