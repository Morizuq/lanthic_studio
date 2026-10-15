import '../../domain/repositories/image_provider_contract.dart';
import 'flux_image_provider.dart';
import 'qwen_image_provider.dart';

class ProviderRegistry {
  ProviderRegistry({
    Map<String, ImageProviderContract>? customProviders,
  }) {
    if (customProviders != null) {
      _providers.addAll(customProviders);
    } else {
      final qwen = QwenImageProvider();
      final flux = FluxImageProvider();
      // Default to Qwen as primary provider
      _providers[qwen.providerIdentifier] = qwen;
      _providers[flux.providerIdentifier] = flux;
    }
  }

  final Map<String, ImageProviderContract> _providers = {};

  void registerProvider(ImageProviderContract provider) {
    _providers[provider.providerIdentifier.toLowerCase()] = provider;
  }

  ImageProviderContract? getProvider(String identifier) {
    return _providers[identifier.toLowerCase()];
  }

  List<ImageProviderContract> get allProviders => List.unmodifiable(_providers.values);

  List<String> get registeredIdentifiers => List.unmodifiable(_providers.keys);

  ImageProviderContract get defaultProvider =>
      getProvider('qwen') ?? (_providers.isNotEmpty ? _providers.values.first : QwenImageProvider());
}
