import '../errors/failures.dart';
import 'secure_storage_service.dart';

abstract class CredentialStore {
  Future<String?> readApiKey(String provider);
  Future<void> writeApiKey(String provider, String apiKey);
  Future<void> deleteApiKey(String provider);
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore({
    SecureStorageService? storageService,
  }) : _storage = storageService ?? SecureStorageServiceImpl();

  final SecureStorageService _storage;

  static const String _keyPrefix = 'lanthic_provider_key_';

  @override
  Future<String?> readApiKey(String provider) async {
    try {
      return await _storage.read('$_keyPrefix$provider');
    } catch (e, stack) {
      throw SecureStorageFailure(
        'Failed to read API key for $provider',
        details: e.toString(),
        cause: stack,
      );
    }
  }

  @override
  Future<void> writeApiKey(String provider, String apiKey) async {
    try {
      await _storage.write('$_keyPrefix$provider', apiKey);
    } catch (e, stack) {
      throw SecureStorageFailure(
        'Failed to persist API key for $provider',
        details: e.toString(),
        cause: stack,
      );
    }
  }

  @override
  Future<void> deleteApiKey(String provider) async {
    try {
      await _storage.delete('$_keyPrefix$provider');
    } catch (e, stack) {
      throw SecureStorageFailure(
        'Failed to delete API key for $provider',
        details: e.toString(),
        cause: stack,
      );
    }
  }
}
