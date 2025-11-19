/// 字段过滤预设配置
///
/// 提供常用的过滤配置模板，方便快速使用。
library;

import 'filter_options.dart';

/// 过滤预设
class FilterPresets {
  FilterPresets._(); // 私有构造函数

  /// 默认预设：完整数据
  static const FilterOptions full = FilterOptions(
    mode: FilterMode.full,
  );

  /// 紧凑模式：移除冗长字段
  static const FilterOptions compact = FilterOptions(
    mode: FilterMode.compact,
    generateSummary: true,
  );

  /// 摘要模式：仅统计数据
  static const FilterOptions summary = FilterOptions(
    mode: FilterMode.summary,
    generateSummary: true,
  );

  /// 列表视图：ID + 标题 + 日期
  static const FilterOptions listView = FilterOptions(
    mode: FilterMode.compact,
    fields: ['id', 'title', 'date', 'createdAt', 'updatedAt'],
    generateSummary: true,
  );

  /// 卡片视图：基础信息 + 图标
  static const FilterOptions cardView = FilterOptions(
    mode: FilterMode.compact,
    fields: ['id', 'title', 'icon', 'color', 'category', 'tags'],
    generateSummary: false,
  );

  /// 时间线视图：时间 + 标题 + 简短描述
  static FilterOptions timelineView = FilterOptions(
    mode: FilterMode.compact,
    fields: [
      'id',
      'title',
      'startTime',
      'endTime',
      'date',
      'duration',
      'category',
      'tags'
    ],
    textLengthLimits: const {'description': 50, 'content': 50},
    generateSummary: true,
  );

  /// 统计分析：仅数值字段
  static const FilterOptions analytics = FilterOptions(
    mode: FilterMode.compact,
    fields: [
      'id',
      'date',
      'amount',
      'duration',
      'quantity',
      'count',
      'category'
    ],
    generateSummary: true,
  );

  /// 搜索结果：高亮字段 + 简短内容
  static FilterOptions searchResult = FilterOptions(
    mode: FilterMode.compact,
    fields: [
      'id',
      'title',
      'category',
      'tags',
      'date',
      'description',
      'content'
    ],
    textLengthLimits: const {'description': 100, 'content': 100},
    generateSummary: true,
  );

  /// 导出数据：完整但截断长文本
  static FilterOptions export = FilterOptions(
    mode: FilterMode.full,
    textLengthLimits: const {
      'description': 500,
      'content': 1000,
      'notes': 500,
    },
  );

  /// 移动端视图：精简数据
  static const FilterOptions mobile = FilterOptions(
    mode: FilterMode.compact,
    excludeFields: [
      'description',
      'content',
      'notes',
      'metadata',
      'detail',
      'settings'
    ],
    abbreviateFieldNames: true,
    generateSummary: true,
  );

  /// 获取预设配置
  ///
  /// [name] 预设名称
  ///
  /// 返回对应的过滤选项，如果未找到则返回 full
  static FilterOptions getPreset(String name) {
    switch (name.toLowerCase()) {
      case 'full':
      case 'f':
        return full;
      case 'compact':
      case 'c':
        return compact;
      case 'summary':
      case 's':
      case 'sum':
        return summary;
      case 'list':
      case 'listview':
        return listView;
      case 'card':
      case 'cardview':
        return cardView;
      case 'timeline':
        return timelineView;
      case 'analytics':
      case 'stats':
        return analytics;
      case 'search':
        return searchResult;
      case 'export':
        return export;
      case 'mobile':
      case 'm':
        return mobile;
      default:
        return full;
    }
  }

  /// 获取所有预设名称
  static List<String> getAllPresetNames() {
    return [
      'full',
      'compact',
      'summary',
      'listView',
      'cardView',
      'timelineView',
      'analytics',
      'searchResult',
      'export',
      'mobile',
    ];
  }
}
