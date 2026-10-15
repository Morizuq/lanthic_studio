import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';
import 'core/storage/shared_prefs_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS) {
    try {
      await FilePicker.skipEntitlementsChecks();
    } catch (_) {}
  }

  SharedPreferences? sharedPrefs;
  try {
    sharedPrefs = await SharedPreferences.getInstance();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        if (sharedPrefs != null)
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const LanthicStudioApp(),
    ),
  );
}

class LanthicStudioApp extends StatelessWidget {
  const LanthicStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeModeProvider);

        return MaterialApp.router(
          title: 'Lanthic Studio',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
