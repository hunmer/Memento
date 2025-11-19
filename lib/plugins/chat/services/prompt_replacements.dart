import 'package:flutter/material.dart';
import '../chat_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Chat插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class ChatPromptReplacements {
  final ChatPlugin _plugin;

  ChatPromptReplacements(this._plugin);

  /// 获取消息列表并格式化为文本
  ///
  /// 参数:
  /// - channelId: 频道ID (可选, 留空则获取所有频道的消息)
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式, 默认今天)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式, 默认今天)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, totalChannels, avgPerChannel } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无content字段)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getMessages(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final channelId = params['channelId'] as String?;
      final dateRange = _parseDateRange(params);

      // 2. 获取消息数据
      final messages = await _getMessagesInRange(
        channelId,
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      // 3. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          messages,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertMessagesByMode(messages, mode, channelId);
      }

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取消息数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取消息数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取频道列表并格式化
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计 { sum: { total, totalMessages } }
  /// - compact: 简化频道信息 { sum: {...}, recs: [...] }
  /// - full: 完整频道数据
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getChannels(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;

      // 2. 获取所有频道
      final channels = _plugin.channelService.channels;

      // 3. 转换为 JSON 列表
      final channelJsonList = channels.map((c) => c.toJson()).toList();

      // 4. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          channelJsonList,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertChannelsByMode(channels, mode);
      }

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取频道列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取频道列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取消息统计数据
  ///
  /// 参数:
  /// - channelId: 频道ID (可选, 留空则统计所有频道)
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 100,
  ///     "byType": { "sent": 60, "received": 40 },
  ///     "byChannel": { "channel1": 50, "channel2": 50 }
  ///   }
  /// }
  Future<String> getStatistics(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final channelId = params['channelId'] as String?;
      final dateRange = _parseDateRange(params);

      // 2. 获取消息数据
      final messages = await _getMessagesInRange(
        channelId,
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      // 3. 构建统计数据
      final statistics = _buildStatistics(messages);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(statistics);
    } catch (e) {
      debugPrint('获取消息统计失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取消息统计时出错',
        'details': e.toString(),
      });
    }
  }

  /// 解析日期范围参数
  Map<String, DateTime> _parseDateRange(Map<String, dynamic> params) {
    final String? startDateStr = params['startDate'] as String?;
    final String? endDateStr = params['endDate'] as String?;

    DateTime? startDate;
    DateTime? endDate;

    // 解析日期字符串
    if (startDateStr != null) {
      startDate = _parseDate(startDateStr);
    }

    if (endDateStr != null) {
      endDate = _parseDate(endDateStr);
    }

    // 如果没有提供日期，使用当天
    if (startDate == null && endDate == null) {
      final now = DateTime.now();
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (startDate != null && endDate == null) {
      // 如果只提供了开始日期，结束日期设为开始日期的当天结束
      endDate = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
    } else if (startDate == null && endDate != null) {
      // 如果只提供了结束日期，开始日期设为结束日期的当天开始
      startDate = DateTime(endDate.year, endDate.month, endDate.day);
    }

    return {
      'startDate': startDate!,
      'endDate': endDate!,
    };
  }

  /// 尝试多种格式解析日期字符串
  DateTime _parseDate(String dateStr) {
    // 尝试解析 yyyy/MM/dd 格式
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    // 尝试解析 yyyy-MM-dd 格式
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    // 尝试使用DateTime.parse
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // 如果所有尝试都失败，抛出异常
    throw FormatException('无法解析日期: $dateStr');
  }

  /// 获取指定日期范围和频道的消息
  Future<List<Map<String, dynamic>>> _getMessagesInRange(
    String? channelId,
    DateTime start,
    DateTime end,
  ) async {
    List<Map<String, dynamic>> allMessages = [];

    // 如果指定了频道ID，只获取该频道的消息
    if (channelId != null && channelId.isNotEmpty) {
      final channelMessages = await _plugin.channelService.getChannelMessages(channelId);
      if (channelMessages != null) {
        // 过滤时间范围
        final filteredMessages = channelMessages.where((msg) {
          return (msg.date.isAfter(start) || msg.date.isAtSameMomentAs(start)) &&
              (msg.date.isBefore(end) || msg.date.isAtSameMomentAs(end));
        });

        // 转换为 JSON
        for (final msg in filteredMessages) {
          allMessages.add(await msg.toJson());
        }
      }
    } else {
      // 获取所有频道的消息
      for (final channel in _plugin.channelService.channels) {
        final channelMessages = channel.messages.where((msg) {
          return (msg.date.isAfter(start) || msg.date.isAtSameMomentAs(start)) &&
              (msg.date.isBefore(end) || msg.date.isAtSameMomentAs(end));
        });

        // 转换为 JSON
        for (final msg in channelMessages) {
          final msgJson = await msg.toJson();
          // 确保消息包含频道ID
          msgJson['channelId'] = channel.id;
          allMessages.add(msgJson);
        }
      }
    }

    // 按时间排序
    allMessages.sort((a, b) {
      final aDate = DateTime.parse(a['date'] as String);
      final bDate = DateTime.parse(b['date'] as String);
      return aDate.compareTo(bDate);
    });

    return allMessages;
  }

  /// 根据模式转换消息数据
  Map<String, dynamic> _convertMessagesByMode(
    List<Map<String, dynamic>> messages,
    AnalysisMode mode,
    String? channelId,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildMessageSummary(messages, channelId);
      case AnalysisMode.compact:
        return _buildMessageCompact(messages);
      case AnalysisMode.full:
        return _buildMessageFull(messages);
    }
  }

  /// 构建消息摘要数据 (summary模式)
  Map<String, dynamic> _buildMessageSummary(
    List<Map<String, dynamic>> messages,
    String? channelId,
  ) {
    if (messages.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'totalChannels': 0,
        'avgPerChannel': 0,
      });
    }

    // 统计不同频道的消息数
    final Map<String, int> channelCounts = {};
    for (final msg in messages) {
      final cId = msg['channelId'] as String? ?? 'unknown';
      channelCounts[cId] = (channelCounts[cId] ?? 0) + 1;
    }

    final avgPerChannel = channelId != null
        ? messages.length.toDouble()
        : messages.length / channelCounts.length;

    return FieldUtils.buildSummaryResponse({
      'total': messages.length,
      'totalChannels': channelCounts.length,
      'avgPerChannel': avgPerChannel.round(),
    });
  }

  /// 构建消息紧凑数据 (compact模式)
  Map<String, dynamic> _buildMessageCompact(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0},
        [],
      );
    }

    // 简化消息记录（移除 content 字段）
    final compactRecords = messages.map((msg) {
      final record = {
        'id': msg['id'],
        'channelId': msg['channelId'] ?? 'unknown',
        'type': msg['type'],
        'ts': msg['date'],
        'user': msg['user'],
      };

      // 只添加非空字段
      if (msg['editedAt'] != null) {
        record['edited'] = msg['editedAt'];
      }
      if (msg['replyToId'] != null) {
        record['replyTo'] = msg['replyToId'];
      }
      if (msg['fixedSymbol'] != null) {
        record['fixed'] = msg['fixedSymbol'];
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': messages.length},
      compactRecords,
    );
  }

  /// 构建消息完整数据 (full模式)
  Map<String, dynamic> _buildMessageFull(List<Map<String, dynamic>> messages) {
    return FieldUtils.buildFullResponse(messages);
  }

  /// 根据模式转换频道数据
  Map<String, dynamic> _convertChannelsByMode(
    List<dynamic> channels,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildChannelSummary(channels);
      case AnalysisMode.compact:
        return _buildChannelCompact(channels);
      case AnalysisMode.full:
        return _buildChannelFull(channels);
    }
  }

  /// 构建频道摘要数据 (summary模式)
  Map<String, dynamic> _buildChannelSummary(List<dynamic> channels) {
    int totalMessages = 0;
    for (final channel in channels) {
      totalMessages += (channel.messages as List).length;
    }

    return FieldUtils.buildSummaryResponse({
      'total': channels.length,
      'totalMessages': totalMessages,
    });
  }

  /// 构建频道紧凑数据 (compact模式)
  Map<String, dynamic> _buildChannelCompact(List<dynamic> channels) {
    final compactRecords = channels.map((channel) {
      return {
        'id': channel.id,
        'title': channel.title,
        'msgCnt': channel.messages.length,
        'priority': channel.priority,
        'groups': channel.groups,
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': channels.length,
        'totalMessages': channels.fold<int>(0, (sum, c) => sum + (c.messages.length as int)),
      },
      compactRecords,
    );
  }

  /// 构建频道完整数据 (full模式)
  Map<String, dynamic> _buildChannelFull(List<dynamic> channels) {
    final channelJsonList = channels.map((c) => c.toJson()).toList();
    return FieldUtils.buildFullResponse(channelJsonList);
  }

  /// 构建统计数据
  Map<String, dynamic> _buildStatistics(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'byType': {},
        'byChannel': {},
      });
    }

    // 按类型统计
    final Map<String, int> byType = {};
    // 按频道统计
    final Map<String, int> byChannel = {};

    for (final msg in messages) {
      final type = msg['type'] as String? ?? 'unknown';
      final channelId = msg['channelId'] as String? ?? 'unknown';

      byType[type] = (byType[type] ?? 0) + 1;
      byChannel[channelId] = (byChannel[channelId] ?? 0) + 1;
    }

    return FieldUtils.buildSummaryResponse({
      'total': messages.length,
      'byType': byType,
      'byChannel': byChannel,
    });
  }

  /// 释放资源
  void dispose() {}
}
