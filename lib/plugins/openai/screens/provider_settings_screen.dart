import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import '../models/service_provider.dart';
import '../controllers/provider_controller.dart';
import 'provider_edit_screen.dart';

class ProviderSettingsScreen extends StatefulWidget {
  const ProviderSettingsScreen({super.key});

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  final ProviderController _controller = ProviderController();
  List<ServiceProvider> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final providers = await _controller.getProviders();
      final defaultProviders = _controller.getDefaultProviders();

      if (providers.isEmpty) {
        // 如果没有服务商，添加默认服务商
        await _controller.saveProviders(defaultProviders);
        _providers = defaultProviders;
      } else {
        // 合并逻辑：添加默认列表中存在但用户数据中缺失的服务商
        final existingIds = providers.map((p) => p.id).toSet();
        final missingProviders = defaultProviders
            .where((defaultProvider) => !existingIds.contains(defaultProvider.id))
            .toList();

        if (missingProviders.isNotEmpty) {
          // 将缺失的默认服务商添加到列表末尾
          final mergedProviders = [...providers, ...missingProviders];
          await _controller.saveProviders(mergedProviders);
          _providers = mergedProviders;
        } else {
          _providers = providers;
        }
      }
    } catch (e) {
      _showErrorSnackBar(
        '${OpenAILocalizations.of(context).loadProvidersError}: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addProvider() async {
    final result = await NavigationHelper.push<bool>(
      context,
      const ProviderEditScreen(),
    );

    if (result == true) {
      await _loadProviders();
    }
  }

  Future<void> _editProvider(ServiceProvider provider) async {
    final result = await NavigationHelper.push<bool>(
      context,
      ProviderEditScreen(provider: provider),
    );

    if (result == true) {
      await _loadProviders();
    }
  }

  Future<void> _deleteProvider(ServiceProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              OpenAILocalizations.of(context).confirmDeleteProviderTitle,
            ),
            content: Text(
              OpenAILocalizations.of(context).confirmDeleteProviderMessage
                  .replaceAll('{providerLabel}', provider.label),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _controller.deleteProvider(provider.id);
        await _loadProviders();
      } catch (e) {
        _showErrorSnackBar(
          '${OpenAILocalizations.of(context).deleteFailed}: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(OpenAILocalizations.of(context).providerSettingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProvider,
            tooltip: OpenAILocalizations.of(context).addProviderTooltip,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _providers.isEmpty
              ? _buildEmptyState()
              : _buildProviderList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            OpenAILocalizations.of(context).noProvidersConfigured,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(OpenAILocalizations.of(context).addProviderTooltip),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _addProvider,
            child: Text(OpenAILocalizations.of(context).addProviderButton),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList() {
    return ListView.builder(
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(provider.label),
            subtitle: Text(
              provider.baseUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editProvider(provider),
                  tooltip: OpenAILocalizations.of(context).editAgent,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteProvider(provider),
                  tooltip: OpenAILocalizations.of(context).deleteAgent,
                ),
              ],
            ),
            onTap: () => _editProvider(provider),
          ),
        );
      },
    );
  }
}
