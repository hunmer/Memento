import 'package:flutter/material.dart';
import '../../../core/plugin_manager.dart';
import '../../../core/config_manager.dart';
import '../../../core/storage/storage_manager.dart';
import '../../base_plugin.dart';

/// 临时基础插件实现，用于紧急情况下提供ContactController所需的BasePlugin实例
/// 这只是一个回退方案，实际应用中应确保能够获取到正确的插件实例
class _TempBasePlugin extends BasePlugin {
  @override
  String get id => 'temp_contact_plugin';

  @override
  String get name => 'Temporary Contact Plugin';

  @override
  String get description => 'Temporary plugin for contact functionality';

  @override
  String get author => 'System';

  @override
  Widget buildMainView(BuildContext context) {
    return const Center(child: Text('Temporary Plugin'));
  }

  @override
  Future<void> initialize() async {
    // 最小化实现
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 最小化实现
  }

  @override
  StorageManager get storage {
    // 尝试从PluginManager获取StorageManager
    final manager = PluginManager.instance.storageManager;
    if (manager != null) {
      return manager;
    }
    throw StateError('StorageManager not available');
  }
}
