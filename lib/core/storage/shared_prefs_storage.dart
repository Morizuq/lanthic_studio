import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class SharedPrefsStorage implements StorageService {
  final SharedPreferences _prefs;

  const SharedPrefsStorage(this._prefs);

  @override
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  @override
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  @override
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  @override
  Future<bool> clear() async {
    return await _prefs.clear();
  }
}

/// Optional provider for SharedPreferences, overridable in main.dart:
///
/// final sharedPrefs = await SharedPreferences.getInstance();
/// runApp(
///   ProviderScope(
///     overrides: [
///       sharedPreferencesProvider.overrideWithValue(sharedPrefs),
///     ],
///     child: const LanthicStudioApp(),
///   ),
/// );
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs != null) {
    return SharedPrefsStorage(prefs);
  }
  return InMemoryStorageService();
});
