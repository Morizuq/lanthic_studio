abstract class StorageService {
  Future<bool> setString(String key, String value);
  String? getString(String key);
  Future<bool> setBool(String key, bool value);
  bool? getBool(String key);
  Future<bool> remove(String key);
  Future<bool> clear();
}

class InMemoryStorageService implements StorageService {
  InMemoryStorageService([Map<String, dynamic>? initialData]) {
    if (initialData != null) {
      _store.addAll(initialData);
    }
  }

  final Map<String, dynamic> _store = {};

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  String? getString(String key) {
    final val = _store[key];
    return val is String ? val : null;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _store[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) {
    final val = _store[key];
    return val is bool ? val : null;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _store.clear();
    return true;
  }
}
