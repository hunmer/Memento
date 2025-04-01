import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_interface.dart';

/// 移动平台的持久化存储实现，使用SharedPreferences
class MobileStorage implements StorageInterface {
  /// 私有构造函数，防止实例化
  MobileStorage._();

  /// 单例实例
  static final MobileStorage _instance = MobileStorage._();

  /// 获取单例实例
  static MobileStorage get instance => _instance;

  /// 保存数据到SharedPreferences
  @override
  Future<void> saveData(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('移动存储保存失败: $key - $e');
    }
  }

  /// 从SharedPreferences读取数据
  @override
  Future<String?> loadData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('移动存储读取失败: $key - $e');
      return null;
    }
  }

  /// 从SharedPreferences删除数据
  @override
  Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('移动存储删除失败: $key - $e');
    }
  }

  /// 检查SharedPreferences中是否存在数据
  @override
  Future<bool> hasData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      debugPrint('移动存储检查失败: $key - $e');
      return false;
    }
  }

  /// 保存JSON对象到SharedPreferences
  @override
  Future<void> saveJson(String key, dynamic data) async {
    debugPrint('saveJson: $key, $data');
    try {
      final jsonString = jsonEncode(data);
      await saveData(key, jsonString);
    } catch (e) {
      debugPrint('移动存储保存JSON失败: $key - $e');
    }
  }

  /// 从SharedPreferences读取JSON对象
  @override
  Future<dynamic> loadJson(String key) async {
    debugPrint('loadJson: $key');
    try {
      final jsonString = await loadData(key);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('移动存储读取JSON失败: $key - $e');
      return null;
    }
  }

  /// 获取所有以指定前缀开头的键
  @override
  Future<List<String>> getKeysWithPrefix(String prefix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      return allKeys.where((key) => key.startsWith(prefix)).toList();
    } catch (e) {
      debugPrint('移动存储获取键列表失败: $prefix - $e');
      return [];
    }
  }

  /// 清除所有以指定前缀开头的数据
  @override
  Future<void> clearWithPrefix(String prefix) async {
    try {
      final keys = await getKeysWithPrefix(prefix);
      final prefs = await SharedPreferences.getInstance();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('移动存储清除失败: $prefix - $e');
    }
  }
}
