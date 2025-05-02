import '../models/service_provider.dart';
import '../../../core/plugin_manager.dart';

class ServiceProviderController {
  List<ServiceProvider> providers = [];

  Future<List<ServiceProvider>> loadProviders() async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return [];

    final storage = plugin.storage;
    final data = await storage.read('${plugin.storageDir}/providers.json');
    if (data.isNotEmpty) {
      final List<dynamic> jsonList = (data['providers'] ?? []) as List<dynamic>;
      providers =
          jsonList
              .map(
                (item) =>
                    ServiceProvider.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    }
    return providers;
  }

  Future<void> saveProvider(ServiceProvider provider) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    // Load existing providers
    await loadProviders();

    // Update or add the provider
    final index = providers.indexWhere((p) => p.label == provider.label);
    if (index >= 0) {
      providers[index] = provider;
    } else {
      providers.add(provider);
    }

    // Save all providers
    final List<Map<String, dynamic>> providersJson =
        providers.map((p) => p.toJson()).toList();
    await plugin.storage.write('${plugin.storageDir}/providers.json', {
      'providers': providersJson,
    });
  }

  Future<void> deleteProvider(String providerName) async {
    final plugin = PluginManager.instance.getPlugin('openai');
    if (plugin == null) return;

    providers.removeWhere((provider) => provider.label == providerName);
    final List<Map<String, dynamic>> providersJson =
        providers.map((p) => p.toJson()).toList();
    await plugin.storage.write('${plugin.storageDir}/providers.json', {
      'providers': providersJson,
    });
  }
}
