import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'storage/storage_manager.dart';

/// 配置管理器，负责管理插件配置
class ConfigManager {
  final StorageManager _storage;
  final Map<String, dynamic> _configs = {};
  final Map<String, dynamic> _appConfig = {};
  static const String _appConfigKey = 'app_config';

  ConfigManager(this._storage);

  /// 初始化配置管理器
  Future<void> initialize() async {
    // Web平台不需要创建目录，只需要确保存储管理器已初始化
    if (!kIsWeb) {
      await _storage.createDirectory('configs');
    }

    // 加载应用级配置
    await _loadAppConfig();
  }

  /// 加载应用级配置
  Future<void> _loadAppConfig() async {
    try {
      final configStr = await _storage.readString(
        'configs/$_appConfigKey.json',
      );
      _appConfig.addAll(jsonDecode(configStr) as Map<String, dynamic>);
    } catch (e) {
      // 如果没有找到配置文件或解析失败，使用默认配置并创建配置文件
      debugPrint('未找到应用配置或解析失败，将创建默认配置: $e');
      _appConfig.addAll(_getDefaultConfig());
      await saveAppConfig(); // 保存默认配置到文件
    }
  }

  /// 获取默认配置
  Map<String, dynamic> _getDefaultConfig() {
    return {'themeMode': 'system', 'locale': 'zh_CN'};
  }

  /// 保存应用级配置
  Future<void> saveAppConfig() async {
    await _storage.writeString(
      'configs/$_appConfigKey.json',
      jsonEncode(_appConfig),
    );
  }

  /// 获取语言设置
  Locale? getLocale() {
    if (!_appConfig.containsKey('locale')) return null;

    final localeStr = _appConfig['locale'] as String;
    final parts = localeStr.split('_');

    if (parts.length == 1) {
      return Locale(parts[0]);
    } else if (parts.length > 1) {
      return Locale(parts[0], parts[1]);
    }

    return null;
  }

  /// 获取主题模式
  ThemeMode getThemeMode() {
    final dynamic themeMode = _appConfig['themeMode'];
    if (themeMode is! String) return ThemeMode.system;

    switch (themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    String themeModeStr;
    switch (mode) {
      case ThemeMode.dark:
        themeModeStr = 'dark';
        break;
      case ThemeMode.light:
        themeModeStr = 'light';
        break;
      case ThemeMode.system:
        themeModeStr = 'system';
        break;
    }

    _appConfig['themeMode'] = themeModeStr;
    await saveAppConfig();
  }

  /// 设置语言
  Future<void> setLocale(Locale locale) async {
    String localeStr = locale.languageCode;
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      localeStr += '_${locale.countryCode}';
    }

    _appConfig['locale'] = localeStr;
    await saveAppConfig();
  }

  /// 保存插件配置
  Future<void> savePluginConfig(
    String pluginId,
    Map<String, dynamic> config,
  ) async {
    _configs[pluginId] = config;
    await _storage.writeString('configs/$pluginId.json', jsonEncode(config));
  }

  /// 获取插件配置
  Future<Map<String, dynamic>?> getPluginConfig(String pluginId) async {
    if (_configs.containsKey(pluginId)) {
      return _configs[pluginId];
    }

    try {
      final configStr = await _storage.readString('configs/$pluginId.json');
      final config = jsonDecode(configStr) as Map<String, dynamic>;
      _configs[pluginId] = config;
      return config;
    } catch (e) {
      return null;
    }
  }

  /// 删除插件配置
  Future<void> deletePluginConfig(String pluginId) async {
    _configs.remove(pluginId);
    await _storage.deleteFile('configs/$pluginId.json');
  }
}
