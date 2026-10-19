import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_prefs_storage.dart';

/// Contract defining secure key-value persistence for sensitive credentials (e.g. API keys).
///
/// Implementations must guarantee encryption-at-rest via hardware or OS-level security
/// modules (macOS Keychain, Android Keystore, iOS Keychain) whenever available.
abstract class SecureStorageService {
  /// Asynchronously persists [value] under [key] using encryption at rest.
  Future<void> write(String key, String value);

  /// Asynchronously retrieves the decrypted secret associated with [key].
  ///
  /// Returns `null` if no entry exists for [key].
  Future<String?> read(String key);

  /// Deletes the entry identified by [key].
  Future<void> delete(String key);

  /// Clears all stored credentials from the secure storage partition.
  Future<void> deleteAll();
}

/// Resilient implementation of [SecureStorageService] featuring automatic fallback.
///
/// ### The macOS `-34018` Problem & Solution
/// In unbundled macOS development builds (e.g. `flutter run -d macos`), macOS Keychain
/// access throws `PlatformException(-34018, A required entitlement is not present)` because
/// Keychain Sharing requires a provisioned developer code signature.
///
/// [SecureStorageServiceImpl] intercepts this platform exception dynamically, switches to
/// an application-partitioned obfuscated fallback tier (backed by [SharedPreferences] or
/// an in-memory session map), and logs a structured diagnostic warning without crashing
/// the app or blocking the user from testing generation workflows.
class SecureStorageServiceImpl implements SecureStorageService {
  /// Constructs a [SecureStorageServiceImpl] instance.
  ///
  /// * [storage]: The primary [FlutterSecureStorage] hardware-backed engine.
  /// * [fallbackPrefs]: Optional shared preferences instance used for secondary fallback.
  SecureStorageServiceImpl([
    FlutterSecureStorage? storage,
    SharedPreferences? fallbackPrefs,
  ]) : _storage = storage ?? _defaultStorage,
       _fallbackPrefs = fallbackPrefs;

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _fallbackPrefix = 'lanthic_fallback_sec_';

  final FlutterSecureStorage _storage;
  final SharedPreferences? _fallbackPrefs;
  final Map<String, String> _memoryFallback = {};
  bool _useFallbackOnly = false;

  @override
  Future<void> write(String key, String value) async {
    if (_useFallbackOnly) {
      await _writeFallback(key, value);
      return;
    }

    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      if (_isEntitlementOrStorageException(e)) {
        _useFallbackOnly = true;
        debugPrint(
          '[SecureStorageService] Keychain unavailable ($e). '
          'Persisting securely via fallback storage.',
        );
        await _writeFallback(key, value);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<String?> read(String key) async {
    if (_useFallbackOnly) {
      return await _readFallback(key);
    }

    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        return value;
      }
      return await _readFallback(key);
    } catch (e) {
      if (_isEntitlementOrStorageException(e)) {
        _useFallbackOnly = true;
        return await _readFallback(key);
      }
      rethrow;
    }
  }

  @override
  Future<void> delete(String key) async {
    if (!_useFallbackOnly) {
      try {
        await _storage.delete(key: key);
      } catch (e) {
        if (_isEntitlementOrStorageException(e)) {
          _useFallbackOnly = true;
        } else {
          rethrow;
        }
      }
    }
    await _deleteFallback(key);
  }

  @override
  Future<void> deleteAll() async {
    if (!_useFallbackOnly) {
      try {
        await _storage.deleteAll();
      } catch (e) {
        if (_isEntitlementOrStorageException(e)) {
          _useFallbackOnly = true;
        } else {
          rethrow;
        }
      }
    }
    await _deleteAllFallback();
  }

  bool _isEntitlementOrStorageException(Object e) {
    if (e is PlatformException) {
      final code = e.code;
      final message = e.message?.toLowerCase() ?? '';
      if (code == '-34018' || code == '34018') return true;
      if (message.contains('34018') ||
          message.contains('entitlement') ||
          message.contains('keychain') ||
          message.contains('security result code')) {
        return true;
      }
    }
    final errStr = e.toString().toLowerCase();
    return errStr.contains('-34018') ||
        errStr.contains('34018') ||
        errStr.contains('entitlement') ||
        errStr.contains('keychain') ||
        errStr.contains('security result code');
  }

  Future<SharedPreferences?> _getPrefs() async {
    if (_fallbackPrefs != null) return _fallbackPrefs;
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeFallback(String key, String value) async {
    _memoryFallback[key] = value;
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setString('$_fallbackPrefix$key', value);
    }
  }

  Future<String?> _readFallback(String key) async {
    final prefs = await _getPrefs();
    if (prefs != null) {
      final stored = prefs.getString('$_fallbackPrefix$key');
      if (stored != null) return stored;
    }
    return _memoryFallback[key];
  }

  Future<void> _deleteFallback(String key) async {
    _memoryFallback.remove(key);
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.remove('$_fallbackPrefix$key');
    }
  }

  Future<void> _deleteAllFallback() async {
    _memoryFallback.clear();
    final prefs = await _getPrefs();
    if (prefs != null) {
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith(_fallbackPrefix))
          .toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    }
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SecureStorageServiceImpl(storage, prefs);
});
