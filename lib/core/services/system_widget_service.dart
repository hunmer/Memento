import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:universal_platform/universal_platform.dart';
import 'dart:convert';

/// 系统桌面小组件数据同步服务
///
/// 负责将各插件的统计数据同步到 Android 系统桌面小组件
class SystemWidgetService {
  static final SystemWidgetService _instance = SystemWidgetService._internal();
  factory SystemWidgetService() => _instance;
  SystemWidgetService._internal();

  static SystemWidgetService get instance => _instance;

  /// SharedPreferences 的前缀名
  static const String _appGroupId = 'group.github.hunmer.memento';

  /// 初始化 home_widget
  Future<void> initialize() async {
    // 只在 iOS 平台上设置 App Group ID，因为 setAppGroupId 只在 iOS 上有效
    if (UniversalPlatform.isIOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }
  }

  /// 更新插件小组件数据
  ///
  /// [pluginId] 插件ID
  /// [data] 小组件数据
  Future<void> updateWidgetData(String pluginId, PluginWidgetData data) async {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for $pluginId');
      return;
    }

    try {
      final jsonData = jsonEncode(data.toJson());
      await HomeWidget.saveWidgetData<String>('${pluginId}_widget_data', jsonData);

      // 触发小组件更新
      await updateWidget(pluginId);
    } catch (e) {
      debugPrint('Failed to update widget data for $pluginId: $e');
    }
  }

  /// 更新指定插件的所有小组件
  Future<void> updateWidget(String pluginId) async {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      return;
    }

    final providerName = _getProviderName(pluginId);
    if (providerName != null) {
      try {
        await HomeWidget.updateWidget(
          androidName: providerName,
          iOSName: providerName,
        );
      } catch (e) {
        debugPrint('Failed to update widget $pluginId: $e');
      }
    }
  }

  /// 更新所有插件的小组件
  Future<void> updateAllWidgets() async {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping updateAllWidgets');
      return;
    }

    final providers = [
      'TodoWidgetProvider',
      'TimerWidgetProvider',
      'BillWidgetProvider',
      'CalendarWidgetProvider',
      'ActivityWidgetProvider',
      'TrackerWidgetProvider',
      'HabitsWidgetProvider',
      'DiaryWidgetProvider',
      'CheckinWidgetProvider',
      'NodesWidgetProvider',
      'DatabaseWidgetProvider',
      'ContactWidgetProvider',
      'DayWidgetProvider',
      'GoodsWidgetProvider',
      'NotesWidgetProvider',
      'StoreWidgetProvider',
      'OpenaiWidgetProvider',
      'AgentChatWidgetProvider',
      'CalendarAlbumWidgetProvider',
      'ChatWidgetProvider',
    ];

    for (final provider in providers) {
      try {
        await HomeWidget.updateWidget(
          androidName: provider,
          iOSName: provider,
        );
      } catch (e) {
        debugPrint('Failed to update widget $provider: $e');
      }
    }
  }

  /// 获取插件对应的 WidgetProvider 名称
  String? _getProviderName(String pluginId) {
    final providerMap = {
      'todo': 'TodoWidgetProvider',
      'timer': 'TimerWidgetProvider',
      'bill': 'BillWidgetProvider',
      'calendar': 'CalendarWidgetProvider',
      'activity': 'ActivityWidgetProvider',
      'tracker': 'TrackerWidgetProvider',
      'habits': 'HabitsWidgetProvider',
      'diary': 'DiaryWidgetProvider',
      'checkin': 'CheckinWidgetProvider',
      'nodes': 'NodesWidgetProvider',
      'database': 'DatabaseWidgetProvider',
      'contact': 'ContactWidgetProvider',
      'day': 'DayWidgetProvider',
      'goods': 'GoodsWidgetProvider',
      'notes': 'NotesWidgetProvider',
      'store': 'StoreWidgetProvider',
      'openai': 'OpenaiWidgetProvider',
      'agent_chat': 'AgentChatWidgetProvider',
      'calendar_album': 'CalendarAlbumWidgetProvider',
      'chat': 'ChatWidgetProvider',
    };
    return providerMap[pluginId];
  }

  /// 处理小组件点击事件
  Future<Uri?> getInitialUri() async {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      return null;
    }

    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint('Failed to get initial URI from widget: $e');
      return null;
    }
  }

  /// 监听小组件点击事件
  Stream<Uri?> get widgetClicked {
    // 只在支持的平台上运行（Android 和 iOS）
    if (!_isWidgetSupported()) {
      return Stream.empty();
    }

    try {
      return HomeWidget.widgetClicked;
    } catch (e) {
      debugPrint('Failed to get widget clicked stream: $e');
      return Stream.empty();
    }
  }

  /// 检查当前平台是否支持小组件
  bool isWidgetSupported() {
    return UniversalPlatform.isAndroid || UniversalPlatform.isIOS;
  }

  /// 检查当前平台是否支持小组件（私有方法）
  bool _isWidgetSupported() {
    return isWidgetSupported();
  }
}

/// 插件小组件数据模型
class PluginWidgetData {
  /// 插件ID
  final String pluginId;

  /// 插件名称
  final String pluginName;

  /// 图标 codePoint
  final int iconCodePoint;

  /// 主题色值
  final int colorValue;

  /// 统计项列表
  final List<WidgetStatItem> stats;

  /// 最后更新时间
  final DateTime lastUpdated;

  PluginWidgetData({
    required this.pluginId,
    required this.pluginName,
    required this.iconCodePoint,
    required this.colorValue,
    required this.stats,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'pluginId': pluginId,
    'pluginName': pluginName,
    'iconCodePoint': iconCodePoint,
    'colorValue': colorValue,
    'stats': stats.map((s) => s.toJson()).toList(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory PluginWidgetData.fromJson(Map<String, dynamic> json) {
    return PluginWidgetData(
      pluginId: json['pluginId'] as String,
      pluginName: json['pluginName'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      stats: (json['stats'] as List)
          .map((s) => WidgetStatItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// 小组件统计项
class WidgetStatItem {
  /// 统计项ID
  final String id;

  /// 显示标签
  final String label;

  /// 统计值
  final String value;

  /// 是否高亮
  final bool highlight;

  /// 自定义颜色 (可选)
  final int? colorValue;

  WidgetStatItem({
    required this.id,
    required this.label,
    required this.value,
    this.highlight = false,
    this.colorValue,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'highlight': highlight,
    if (colorValue != null) 'colorValue': colorValue,
  };

  factory WidgetStatItem.fromJson(Map<String, dynamic> json) {
    return WidgetStatItem(
      id: json['id'] as String,
      label: json['label'] as String,
      value: json['value'] as String,
      highlight: json['highlight'] as bool? ?? false,
      colorValue: json['colorValue'] as int?,
    );
  }
}
