import 'plugin_base.dart';

/// 插件管理器，负责管理所有已注册的插件
class PluginManager {
  // 单例实例
  static final PluginManager _instance = PluginManager._internal();

  // 私有构造函数
  PluginManager._internal();

  // 工厂构造函数
  factory PluginManager() => _instance;

  final List<PluginBase> _plugins = [];

  /// 注册插件
  Future<void> registerPlugin(PluginBase plugin) async {
    if (!_plugins.any((p) => p.id == plugin.id)) {
      await plugin.initialize();
      _plugins.add(plugin);
    }
  }

  /// 获取所有已注册的插件
  List<PluginBase> get allPlugins => List.unmodifiable(_plugins);

  /// 根据ID获取插件
  PluginBase? getPlugin(String id) {
    try {
      return _plugins.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 移除插件
  Future<void> removePlugin(String id) async {
    _plugins.removeWhere((p) => p.id == id);
  }
}
