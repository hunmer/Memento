import 'dart:convert';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'plugin_base.dart';
import 'storage/storage_manager.dart';

/// 插件管理器，负责管理所有已注册的插件
class PluginManager {
  StorageManager? _storageManager;
  Map<String, int> _pluginAccessTimes = {};
  static const String _accessTimesStorageKey = 'configs/plugin_access_times';
  static const String _settingsStorageKey = 'configs/plugin_manager_settings';
  static const String _lastPluginKey = 'configs/last_opened_plugin';
  PluginBase? _currentPlugin; // 当前打开的插件
  bool _autoOpenLastPlugin = true; // 是否自动打开最后使用的插件
  String? _lastOpenedPluginId; // 最后打开的插件ID
  // 单例实例
  static final PluginManager _instance = PluginManager._internal();

  // 私有构造函数
  PluginManager._internal();

  // 工厂构造函数
  factory PluginManager() => _instance;

  // 获取单例实例
  static PluginManager get instance => _instance;

  // 设置存储管理器并初始化数据
  Future<void> setStorageManager(StorageManager manager) async {
    _storageManager = manager;

    // 设置存储管理器后加载数据
    await _loadAccessTimes();
    await _loadSettings();
    await _loadLastOpenedPlugin();
  }

  // 获取存储管理器
  StorageManager? get storageManager => _storageManager;

  final List<PluginBase> _plugins = [];

  /// 注册插件
  Future<void> registerPlugin(PluginBase plugin) async {
    if (!_plugins.any((p) => p.id == plugin.id)) {
      if (_storageManager != null) {
        plugin.setStorageManager(_storageManager!);
      }
      _plugins.add(plugin);
      // 初始化插件（加载数据、设置监听器等）
      await plugin.initialize();
      // 注册到应用程序（设置监听器等）
      await plugin.registerToApp(this, ConfigManager(_storageManager!));

      // 广播插件加载完成事件
      eventManager.broadcast('plugin_loaded', Value(plugin.id));
    }
  }

  /// 获取所有已注册的插件
  /// [sortByRecentlyOpened] 是否按最近打开时间排序
  List<PluginBase> getAllPlugins({bool sortByRecentlyOpened = false}) {
    if (!sortByRecentlyOpened) {
      return List.unmodifiable(_plugins);
    }

    // 创建插件列表的副本并按访问时间排序
    final sortedPlugins = List<PluginBase>.from(_plugins);
    sortedPlugins.sort((a, b) {
      final timeA = _pluginAccessTimes[a.id] ?? 0;
      final timeB = _pluginAccessTimes[b.id] ?? 0;
      return timeB.compareTo(timeA); // 降序排列，最近的在前
    });
    return List.unmodifiable(sortedPlugins);
  }

  /// 获取所有已注册的插件（向后兼容的getter）
  List<PluginBase> get allPlugins => getAllPlugins();

  /// 获取最近打开的插件
  /// [excludePluginId] 需要排除的插件ID，用于避免返回当前正在使用的插件
  PluginBase? getLastOpenedPlugin({String? excludePluginId}) {
    // 优先使用持久化存储的最后打开的插件ID
    if (_lastOpenedPluginId != null && _lastOpenedPluginId != excludePluginId) {
      final plugin = getPlugin(_lastOpenedPluginId!);
      if (plugin != null) {
        return plugin;
      }
    }

    // 如果没有最后打开的插件记录或该插件不存在，则回退到访问时间排序
    if (_pluginAccessTimes.isEmpty || _plugins.isEmpty) {
      return null;
    }

    // 按访问时间降序排序，并排除指定的插件ID
    var sortedEntries =
        _pluginAccessTimes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // 找到第一个不是被排除ID的插件
    for (var entry in sortedEntries) {
      if (entry.key != excludePluginId) {
        var plugin = getPlugin(entry.key);
        if (plugin != null) {
          return plugin;
        }
      }
    }

    return null;
  }

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

  /// 加载插件访问时间记录
  Future<void> _loadAccessTimes() async {
    // 确保初始化为空Map
    _pluginAccessTimes = {};

    if (_storageManager == null) return;

    try {
      final data = await _storageManager!.read(_accessTimesStorageKey);
      if (data.isNotEmpty) {
        _pluginAccessTimes = Map<String, int>.from(
          data.map((key, value) => MapEntry(key, value as int)),
        );
      }
    } catch (e) {
      debugPrint('Warning: Failed to load plugin access times: $e');
      // 保持使用空Map
    }
  }

  /// 保存插件访问时间记录
  Future<void> _saveAccessTimes() async {
    if (_storageManager == null) return;

    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        _pluginAccessTimes,
      );
      await _storageManager!.write(_accessTimesStorageKey, data);
    } catch (e) {
      debugPrint('Warning: Failed to save plugin access times: $e');
    }
  }

  /// 更新插件访问时间
  Future<void> _updatePluginAccessTime(String pluginId) async {
    _pluginAccessTimes[pluginId] = DateTime.now().millisecondsSinceEpoch;
    await _saveAccessTimes();
  }

  /// 获取当前打开的插件
  PluginBase? getCurrentPlugin() => _currentPlugin;

  /// 获取当前打开的插件ID
  String? getCurrentPluginId() => _currentPlugin?.id;

  /// 获取是否自动打开最后使用的插件
  bool get autoOpenLastPlugin => _autoOpenLastPlugin;

  /// 设置是否自动打开最后使用的插件
  set autoOpenLastPlugin(bool value) {
    _autoOpenLastPlugin = value;
    _saveSettings();
  }

  /// 获取最后打开的插件ID
  String? get getLastOpenedPluginId => _lastOpenedPluginId;

  /// 加载设置
  Future<void> _loadSettings() async {
    if (_storageManager == null) return;

    try {
      final settings = await _storageManager!.readFile(
        _settingsStorageKey,
        '{"autoOpenLastPlugin": true}',
      );
      final data = jsonDecode(settings);
      _autoOpenLastPlugin = data['autoOpenLastPlugin'] ?? true;
    } catch (e) {
      debugPrint('Warning: Failed to load plugin manager settings: $e');
      _autoOpenLastPlugin = true;
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    if (_storageManager == null) return;

    try {
      final settings = jsonEncode({'autoOpenLastPlugin': _autoOpenLastPlugin});
      await _storageManager!.writeFile(_settingsStorageKey, settings);
    } catch (e) {
      debugPrint('Warning: Failed to save plugin manager settings: $e');
    }
  }

  /// 加载最后打开的插件ID
  Future<void> _loadLastOpenedPlugin() async {
    if (_storageManager == null) return;

    try {
      final lastPluginId = await _storageManager!.readFile(_lastPluginKey, '');
      _lastOpenedPluginId = lastPluginId.isNotEmpty ? lastPluginId : null;
    } catch (e) {
      debugPrint('Warning: Failed to load last opened plugin: $e');
      _lastOpenedPluginId = null;
    }
  }

  /// 保存最后打开的插件ID
  Future<void> _saveLastOpenedPlugin() async {
    if (_storageManager == null) return;

    try {
      if (_lastOpenedPluginId != null) {
        await _storageManager!.writeFile(_lastPluginKey, _lastOpenedPluginId!);
      }
    } catch (e) {
      debugPrint('Warning: Failed to save last opened plugin: $e');
    }
  }

  /// 记录插件打开（仅记录，不导航）
  ///
  /// 用于 OpenContainer 等自定义导航场景，需要记录打开历史但不通过 Navigator 导航
  void recordPluginOpen(PluginBase plugin) {
    _currentPlugin = plugin;
    _lastOpenedPluginId = plugin.id;
    _saveLastOpenedPlugin();
    _updatePluginAccessTime(plugin.id);
  }

  /// 打开插件界面
  void openPlugin(BuildContext context, PluginBase plugin) {
    // 检查当前路由是否已经是该插件
    bool isPluginAlreadyOpen =
        ModalRoute.of(context)?.settings.name == '/${plugin.id}';
    if (isPluginAlreadyOpen) {
      return;
    }
    // 记录打开历史
    recordPluginOpen(plugin);
    // 使用 NavigationHelper.push 以支持 iOS 左滑返回
    NavigationHelper.push(context, plugin.buildMainView(context));
  }

  static toHomeScreen(BuildContext context) {
    PluginManager.instance._currentPlugin = null; // 清除当前插件记录
    // 清除所有历史路由，回到根路由
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
