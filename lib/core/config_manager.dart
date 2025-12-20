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
      final config = await _storage.readJson('configs/$_appConfigKey.json');
      _appConfig.addAll(config as Map<String, dynamic>);
    } catch (e) {
      _appConfig.addAll(_getDefaultConfig());
      await saveAppConfig(); // 保存默认配置到文件
    }
  }

  /// 获取默认配置
  Map<String, dynamic> _getDefaultConfig() {
    return {
      'themeMode': 'system',
      'locale': 'zh_CN',
      'permissionsOnboardingCompleted': false,
    };
  }

  /// 保存应用级配置
  Future<void> saveAppConfig() async {
    await _storage.writeString(
      'configs/$_appConfigKey.json',
      jsonEncode(_appConfig),
    );
  }

  /// 获取语言设置
  Locale getLocale() {
    final localeStr = _appConfig['locale'] as String;
    final parts = localeStr.split('_');
    if (parts.length == 1) {
      return Locale(parts[0]);
    } else if (parts.length > 1) {
      return Locale(parts[0], parts[1]);
    }
    // ignore: deprecated_member_use
    return WidgetsBinding.instance.window.locale;
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

  /// èŽ·å–åº”ç”¨çº§é…ç½®å€¼ï¼Œå¦‚æžœä¸å­˜åœ¨åˆ™è¿”å›žé»˜è®¤å€¼
  T getAppConfigValue<T>(String key, T defaultValue) {
    final value = _appConfig[key];
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  /// è®¾ç½®åº”ç”¨çº§é…ç½®å¹¶ç«‹å³ä¿å­˜
  Future<void> setAppConfigValue<T>(String key, T value) async {
    _appConfig[key] = value;
    await saveAppConfig();
  }

  static String getPluginConfigPath(
    String pluginId, [
    String? fileName = 'settings',
  ]) {
    return 'configs/$pluginId/$fileName.json';
  }

  /// 保存插件配置
  Future<void> savePluginConfig(
    String pluginId,
    Map<String, dynamic> config,
  ) async {
    _configs[pluginId] = config;
    await _storage.writeString(
      getPluginConfigPath(pluginId),
      jsonEncode(config),
    );
  }

  /// 获取插件配置
  Future<Map<String, dynamic>?> getPluginConfig(String pluginId) async {
    if (_configs.containsKey(pluginId)) {
      return _configs[pluginId] as Map<String, dynamic>?;
    }

    try {
      final config = await _storage.readJson(getPluginConfigPath(pluginId));
      if (config is! Map) return null;

      // 确保所有键都是String类型
      final result = <String, dynamic>{};
      for (final key in config.keys) {
        if (key is String) {
          result[key] = config[key];
        }
      }

      _configs[pluginId] = result;
      return result;
    } catch (e) {
      return null;
    }
  }

  /// 删除插件配置
  Future<void> deletePluginConfig(String pluginId) async {
    _configs.remove(pluginId);
    await _storage.deleteFile(getPluginConfigPath(pluginId));
  }
}
