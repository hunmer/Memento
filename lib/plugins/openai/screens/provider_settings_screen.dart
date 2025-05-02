import 'package:flutter/material.dart';
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
      if (providers.isEmpty) {
        // 如果没有服务商，添加默认服务商
        final defaultProviders = _controller.getDefaultProviders();
        await _controller.saveProviders(defaultProviders);
        _providers = defaultProviders;
      } else {
        _providers = providers;
      }
    } catch (e) {
      _showErrorSnackBar('加载服务商失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addProvider() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ProviderEditScreen(),
      ),
    );

    if (result == true) {
      await _loadProviders();
    }
  }

  Future<void> _editProvider(ServiceProvider provider) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderEditScreen(provider: provider),
      ),
    );

    if (result == true) {
      await _loadProviders();
    }
  }

  Future<void> _deleteProvider(ServiceProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除服务商 "${provider.label}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.deleteProvider(provider.id);
        await _loadProviders();
      } catch (e) {
        _showErrorSnackBar('删除服务商失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务商设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProvider,
            tooltip: '添加服务商',
          ),
        ],
      ),
      body: _isLoading
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
          const Text(
            '没有配置服务商',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('点击右上角的加号添加服务商'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _addProvider,
            child: const Text('添加服务商'),
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
                  tooltip: '编辑',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteProvider(provider),
                  tooltip: '删除',
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