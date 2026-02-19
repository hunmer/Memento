/// 习惯追踪插件 - 小组件配置模型
///
/// 统一处理各种数据格式，隐藏解析细节
library;

import 'package:flutter/foundation.dart';

/// 习惯统计小组件配置
class HabitStatsWidgetConfig {
  /// 习惯ID
  final String habitId;

  /// 公共小组件ID
  final String commonWidgetId;

  /// 公共小组件属性
  final Map<String, dynamic> commonWidgetProps;

  /// 最后更新时间（可选）
  final DateTime? lastUpdated;

  const HabitStatsWidgetConfig({
    required this.habitId,
    required this.commonWidgetId,
    this.commonWidgetProps = const {},
    this.lastUpdated,
  });

  /// 从动态配置中解析（支持多种格式）
  ///
  /// 支持的格式：
  /// - {selectedData: {data: [{habitId, commonWidgetId, commonWidgetProps}]}}
  /// - {data: [{habitId, commonWidgetId, commonWidgetProps}]}
  /// - {habitId, commonWidgetId, commonWidgetProps}
  /// - {id, commonWidgetId, commonWidgetProps}
  static HabitStatsWidgetConfig? fromDynamic(dynamic config) {
    if (config == null) return null;

    Map<String, dynamic>? dataMap;

    // 格式1: 从 selectedData.data 中提取（保存的配置结构）
    if (config is Map && config.containsKey('selectedData')) {
      final selectedData = config['selectedData'];
      if (selectedData is Map && selectedData.containsKey('data')) {
        final dataList = selectedData['data'];
        if (dataList is List && dataList.isNotEmpty) {
          dataMap = dataList[0] as Map<String, dynamic>?;
        }
      }
    }
    // 格式2: 从 data 数组中提取
    else if (config is Map && config.containsKey('data')) {
      final dataList = config['data'];
      if (dataList is List && dataList.isNotEmpty) {
        dataMap = dataList[0] as Map<String, dynamic>?;
      }
    }
    // 格式3/4: 直接是数据Map
    else if (config is Map) {
      dataMap = Map<String, dynamic>.from(config);
    }

    if (dataMap == null) {
      debugPrint('[HabitStatsWidgetConfig] 无法解析配置: $config');
      return null;
    }

    // 提取 habitId
    final habitId = dataMap['habitId']?.toString() ?? dataMap['id']?.toString();
    if (habitId == null || habitId.isEmpty) {
      debugPrint('[HabitStatsWidgetConfig] 缺少 habitId: $dataMap');
      return null;
    }

    // 提取 commonWidgetId
    final commonWidgetId = dataMap['commonWidgetId']?.toString();
    if (commonWidgetId == null || commonWidgetId.isEmpty) {
      debugPrint('[HabitStatsWidgetConfig] 缺少 commonWidgetId: $dataMap');
      return null;
    }

    // 提取 commonWidgetProps
    final commonWidgetProps = dataMap['commonWidgetProps'] is Map
        ? Map<String, dynamic>.from(dataMap['commonWidgetProps'] as Map)
        : <String, dynamic>{};

    // 提取 lastUpdated
    DateTime? lastUpdated;
    if (dataMap['lastUpdated'] != null) {
      final lastUpdatedStr = dataMap['lastUpdated']?.toString();
      if (lastUpdatedStr != null && lastUpdatedStr.isNotEmpty) {
        try {
          lastUpdated = DateTime.parse(lastUpdatedStr);
        } catch (_) {
          // 忽略解析错误
        }
      }
    }

    return HabitStatsWidgetConfig(
      habitId: habitId,
      commonWidgetId: commonWidgetId,
      commonWidgetProps: commonWidgetProps,
      lastUpdated: lastUpdated,
    );
  }

  /// 只提取 habitId（用于只需要习惯ID的场景）
  static String? extractHabitId(dynamic config) {
    final parsed = fromDynamic(config);
    return parsed?.habitId;
  }

  /// 转换为 Map（用于序列化）
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'habitId': habitId,
      'commonWidgetId': commonWidgetId,
      'commonWidgetProps': commonWidgetProps,
    };
    if (lastUpdated != null) {
      map['lastUpdated'] = lastUpdated!.toIso8601String();
    }
    return map;
  }

  @override
  String toString() {
    return 'HabitStatsWidgetConfig(habitId: $habitId, widget: $commonWidgetId)';
  }
}

/// 活动统计小组件配置
class ActivityStatsWidgetConfig {
  /// 日期范围：day/week/month/year
  final String dateRange;

  /// 最大显示数量
  final int maxCount;

  const ActivityStatsWidgetConfig({
    required this.dateRange,
    this.maxCount = 5,
  });

  /// 从动态配置中解析
  static ActivityStatsWidgetConfig? fromDynamic(dynamic config) {
    if (config == null) return null;

    String dateRange = 'week';
    int maxCount = 5;

    // 尝试直接解析
    if (config is Map) {
      dateRange = config['dateRange']?.toString() ?? 'week';
      maxCount = (config['maxCount'] as int?)?.clamp(1, 10) ?? 5;
    }

    return ActivityStatsWidgetConfig(
      dateRange: dateRange,
      maxCount: maxCount,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'dateRange': dateRange,
      'maxCount': maxCount,
    };
  }

  @override
  String toString() {
    return 'ActivityStatsWidgetConfig(dateRange: $dateRange, maxCount: $maxCount)';
  }
}
