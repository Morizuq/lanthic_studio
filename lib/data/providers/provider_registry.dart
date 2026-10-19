import '../../domain/repositories/image_provider_contract.dart';
import 'flux_image_provider.dart';
import 'qwen_image_provider.dart';

/// Central Service Locator and factory for image synthesis providers.
///
/// Maintains a registry of available [ImageProviderContract] implementations,
/// allowing the application to dynamically resolve providers by string slug
/// (e.g., `'qwen'`, `'flux'`) at runtime based on user settings or project manifests.
class ProviderRegistry {
  /// Constructs a [ProviderRegistry].
  ///
  /// * [customProviders]: Optional initial mapping of providers. If omitted,
  ///   defaults to registering [QwenImageProvider] and [FluxImageProvider].
  ProviderRegistry({
    Map<String, ImageProviderContract>? customProviders,
  }) {
    if (customProviders != null) {
      _providers.addAll(customProviders);
    } else {
      final qwen = QwenImageProvider();
      final flux = FluxImageProvider();
      _providers[qwen.providerIdentifier] = qwen;
      _providers[flux.providerIdentifier] = flux;
    }
  }

  final Map<String, ImageProviderContract> _providers = {};

  /// Registers an [ImageProviderContract] in the catalog.
  ///
  /// Keys are stored in lowercase to guarantee case-insensitive lookups.
  void registerProvider(ImageProviderContract provider) {
    _providers[provider.providerIdentifier.toLowerCase()] = provider;
  }

  /// Retrieves a registered provider by its unique identifier (case-insensitive).
  ///
  /// Returns `null` if no provider matching [identifier] is found.
  ImageProviderContract? getProvider(String identifier) {
    return _providers[identifier.toLowerCase()];
  }

  /// Returns an unmodifiable list of all currently registered image providers.
  List<ImageProviderContract> get allProviders => List.unmodifiable(_providers.values);

  /// Returns an unmodifiable list of all registered provider identifier slugs.
  List<String> get registeredIdentifiers => List.unmodifiable(_providers.keys);

  /// Resolves the default provider for synthesis when none is specified.
  ///
  /// Prefers `'qwen'`, falling back to the first available provider or a new [QwenImageProvider].
  ImageProviderContract get defaultProvider =>
      getProvider('qwen') ?? (_providers.isNotEmpty ? _providers.values.first : QwenImageProvider());
}

