// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Web平台的持久化存储实现，使用localStorage
class WebStorage {
  /// 私有构造函数，防止实例化
  WebStorage._();

  /// 保存数据到localStorage
  static void saveData(String key, String value) {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }
    try {
      html.window.localStorage[key] = value;
    } catch (e) {
      debugPrint('Web存储保存失败: $key - $e');
    }
  }

  /// 从localStorage读取数据
  static String? loadData(String key) {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }
    try {
      return html.window.localStorage[key];
    } catch (e) {
      debugPrint('Web存储读取失败: $key - $e');
      return null;
    }
  }

  /// 从localStorage删除数据
  static void removeData(String key) {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }
    try {
      html.window.localStorage.remove(key);
    } catch (e) {
      debugPrint('Web存储删除失败: $key - $e');
    }
  }

  /// 检查localStorage中是否存在数据
  static bool hasData(String key) {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }
    try {
      return html.window.localStorage.containsKey(key);
    } catch (e) {
      debugPrint('Web存储检查失败: $key - $e');
      return false;
    }
  }

  /// 保存JSON对象到localStorage
  static void saveJson(String key, dynamic data) {
    debugPrint('saveJson: $key, $data');
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }
    try {
      final jsonString = jsonEncode(data);
      WebStorage.saveData(key, jsonString);
    } catch (e) {
      debugPrint('Web存储保存JSON失败: $key - $e');
    }
  }

  /// 从localStorage读取JSON对象
  static dynamic loadJson(String key) {
    debugPrint('loadJson: $key');
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }
    try {
      final jsonString = WebStorage.loadData(key);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Web存储读取JSON失败: $key - $e');
      return null;
    }
  }

  /// 获取所有以指定前缀开头的键
  static List<String> getKeysWithPrefix(String prefix) {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }
    final keys = <String>[];
    try {
      html.window.localStorage.forEach((key, value) {
        if (key.startsWith(prefix)) {
          keys.add(key);
        }
      });
    } catch (e) {
      debugPrint('Web存储获取键列表失败: $prefix - $e');
    }
    return keys;
  }

  /// 清除所有以指定前缀开头的数据
  static void clearWithPrefix(String prefix) {
    if (!kIsWeb) {
      throw UnsupportedError('WebStorage 仅支持Web平台');
    }
    try {
      final keys = WebStorage.getKeysWithPrefix(prefix);
      for (final key in keys) {
        WebStorage.removeData(key);
      }
    } catch (e) {
      debugPrint('Web存储清除失败: $prefix - $e');
    }
  }
}

// 导出顶级函数
void saveData(String key, String value) => WebStorage.saveData(key, value);
String? loadData(String key) => WebStorage.loadData(key);
void removeData(String key) => WebStorage.removeData(key);
void removeDataByPrefix(String prefix) => WebStorage.clearWithPrefix(prefix);
bool hasData(String key) => WebStorage.hasData(key);
void saveJson(String key, dynamic data) => WebStorage.saveJson(key, data);
dynamic loadJson(String key) => WebStorage.loadJson(key);
