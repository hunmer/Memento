import 'package:flutter/material.dart';
import '../contact_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Contact插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class ContactPromptReplacements {
  final ContactPlugin _plugin;

  ContactPromptReplacements(this._plugin);

  /// 获取联系人数据并格式化为文本
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - tag: 标签筛选 (可选)
  /// - uncontactedDays: 未联系天数筛选 (可选)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, groups }, topGroups: [...] }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无notes/address)
  /// - full: 完整数据 (包含所有字段)
  Future<String> getContacts(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final String? tag = params['tag'] as String?;
      final int? uncontactedDays = params['uncontactedDays'] as int?;

      // 2. 获取所有联系人数据
      final contacts = await _plugin.controller.getAllContacts();

      // 3. 应用筛选
      var filteredContacts = contacts;

      if (tag != null && tag.isNotEmpty) {
        filteredContacts = filteredContacts.where((c) => c.tags.contains(tag)).toList();
      }

      if (uncontactedDays != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: uncontactedDays));
        filteredContacts = filteredContacts.where(
          (c) => c.lastContactTime.isBefore(cutoffDate),
        ).toList();
      }

      // 4. 根据模式转换数据
      final result = await _convertByMode(filteredContacts, mode);

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取联系人数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取联系人数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取分组统计
  ///
  /// 返回格式:
  /// {
  ///   "groups": [
  ///     {"name": "家人", "count": 5},
  ///     {"name": "同事", "count": 12}
  ///   ]
  /// }
  Future<String> getGroups(Map<String, dynamic> params) async {
    try {
      final contacts = await _plugin.controller.getAllContacts();
      final Map<String, int> groupCounts = {};

      for (final contact in contacts) {
        for (final tag in contact.tags) {
          groupCounts[tag] = (groupCounts[tag] ?? 0) + 1;
        }
      }

      final groups = groupCounts.entries
          .map((e) => {'name': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return FieldUtils.toJsonString({'groups': groups});
    } catch (e) {
      debugPrint('获取分组统计失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取分组统计时出错',
        'details': e.toString(),
      });
    }
  }

  /// 根据模式转换数据
  Future<Map<String, dynamic>> _convertByMode(
    List contacts,
    AnalysisMode mode,
  ) async {
    switch (mode) {
      case AnalysisMode.summary:
        return await _buildSummary(contacts);
      case AnalysisMode.compact:
        return await _buildCompact(contacts);
      case AnalysisMode.full:
        return await _buildFull(contacts);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 50,
  ///     "groups": 5
  ///   },
  ///   "topGroups": [
  ///     {"tag": "同事", "cnt": 20},
  ///     {"tag": "朋友", "cnt": 15}
  ///   ]
  /// }
  Future<Map<String, dynamic>> _buildSummary(List contacts) async {
    if (contacts.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'groups': 0,
      });
    }

    // 统计标签
    final Map<String, int> tagCounts = {};
    for (final contact in contacts) {
      for (final tag in contact.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // 生成标签排行（按数量降序）
    final topGroups = tagCounts.entries.map((entry) {
      return {
        'tag': entry.key,
        'cnt': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

    // 只保留前5个标签
    final topGroupsLimited = topGroups.take(5).toList();

    return FieldUtils.buildSummaryResponse({
      'total': contacts.length,
      'groups': tagCounts.length,
      if (topGroupsLimited.isNotEmpty) 'topGroups': topGroupsLimited,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 50 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "name": "张三",
  ///       "phone": "13800138000",
  ///       "email": "",
  ///       "group": "同事"
  ///     }
  ///   ]
  /// }
  Future<Map<String, dynamic>> _buildCompact(List contacts) async {
    if (contacts.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0},
        [],
      );
    }

    // 简化记录（移除 notes, address, customFields 字段）
    final compactRecords = contacts.map((contact) {
      final record = {
        'id': contact.id,
        'name': contact.name,
        'phone': contact.phone,
      };

      // 只添加非空字段
      if (contact.tags != null && contact.tags.isNotEmpty) {
        record['tags'] = contact.tags;
      }

      // 添加最后联系时间（相对时间）
      final daysSince = DateTime.now().difference(contact.lastContactTime).inDays;
      if (daysSince > 0) {
        record['lastContact'] = '${daysSince}天前';
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': contacts.length},
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: 包含所有联系人的完整数据
  Future<Map<String, dynamic>> _buildFull(List contacts) async {
    final fullRecords = <Map<String, dynamic>>[];

    for (final contact in contacts) {
      final contactMap = contact.toJson();

      // 添加交互记录数量
      final interactions = await _plugin.controller.getInteractionsByContactId(contact.id);
      contactMap['interactionCount'] = interactions.length;

      // 转换时间戳为可读格式
      contactMap['createdTime'] = FieldUtils.formatDateTime(contact.createdTime);
      contactMap['lastContactTime'] = FieldUtils.formatDateTime(contact.lastContactTime);

      fullRecords.add(contactMap);
    }

    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 释放资源
  void dispose() {}
}
