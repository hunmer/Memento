import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 系统日历映射管理器
/// 负责管理本地事件ID与系统日历事件ID的映射关系
class CalendarMappingManager {
  static CalendarMappingManager? _instance;
  static CalendarMappingManager get instance =>
      _instance ??= CalendarMappingManager._();

  CalendarMappingManager._();

  // 存储键名
  static const String _mappingStorageKey = 'calendar_system_id_mapping';

  // 映射表：本地事件ID -> 映射数据
  Map<String, Map<String, dynamic>> _mapping = {};

  /// 加载映射关系
  Future<void> loadMapping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingJson = prefs.getString(_mappingStorageKey);
      if (mappingJson != null) {
        final mappingData = jsonDecode(mappingJson) as Map<String, dynamic>;
        _mapping = mappingData.map(
          (key, value) => MapEntry(key, value as Map<String, dynamic>),
        );
        debugPrint('CalendarMappingManager: 加载映射关系完成，共 ${_mapping.length} 条');
      }
    } catch (e) {
      debugPrint('CalendarMappingManager: 加载映射关系失败: $e');
    }
  }

  /// 保存映射关系到持久化存储
  Future<void> saveMapping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingJson = jsonEncode(_mapping);
      await prefs.setString(_mappingStorageKey, mappingJson);
      debugPrint('CalendarMappingManager: 保存映射关系完成，共 ${_mapping.length} 条');
    } catch (e) {
      debugPrint('CalendarMappingManager: 保存映射关系失败: $e');
    }
  }

  /// 添加或更新映射关系
  /// @param localId 本地事件ID
  /// @param from 来源 ('todo' 或 'calendar')
  /// @param data 原始数据
  /// @param systemId 系统日历中的事件ID
  Future<void> addMapping({
    required String localId,
    required String from,
    required Map<String, dynamic> data,
    required String systemId,
  }) async {
    _mapping[localId] = {
      'from': from,
      'data': data,
      'systemId': systemId,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await saveMapping();
  }

  /// 根据本地ID获取系统事件ID
  String? getSystemEventId(String localId) {
    return _mapping[localId]?['systemId'] as String?;
  }

  /// 根据本地ID获取映射信息
  Map<String, dynamic>? getMapping(String localId) {
    return _mapping[localId];
  }

  /// 根据本地ID删除映射
  Future<void> removeMapping(String localId) async {
    _mapping.remove(localId);
    await saveMapping();
  }

  /// 获取所有映射
  Map<String, Map<String, dynamic>> get allMappings =>
      Map.unmodifiable(_mapping);

  /// 检查是否包含指定本地ID
  bool contains(String localId) => _mapping.containsKey(localId);

  /// 清空所有映射
  Future<void> clearMapping() async {
    _mapping.clear();
    await saveMapping();
  }
}
