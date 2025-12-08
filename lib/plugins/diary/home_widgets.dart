import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'diary_plugin.dart';
import 'l10n/diary_localizations.dart';

/// 日记插件的主页小组件注册
class DiaryHomeWidgets {
  /// 注册所有日记插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'diary_icon',
      pluginId: 'diary',
      name: '日记',
      description: '快速打开日记',
      icon: Icons.book,
      color: Colors.indigo,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
        builder:
            (context, config) =>
                const GenericIconWidget(
                  icon: Icons.book,
                  color: Colors.indigo,
                  name: '日记',
                ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'diary_overview',
      pluginId: 'diary',
      name: '日记概览',
      description: '显示今日字数和本月进度',
      icon: Icons.menu_book,
      color: Colors.indigo,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '记录',
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats() {
    try {
      final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
      if (plugin == null) return [];

      // 同步获取统计数据
      final todayCount = plugin.getTodayWordCountSync();
      final monthCount = plugin.getMonthWordCountSync();
      final monthProgress = plugin.getMonthProgressSync();

      return [
        StatItemData(
          id: 'today_word_count',
          label: '今日字数',
          value: '$todayCount',
          highlight: todayCount > 0,
          color: Colors.indigo,
        ),
        StatItemData(
          id: 'month_word_count',
          label: '本月字数',
          value: '$monthCount',
          highlight: false,
        ),
        StatItemData(
          id: 'month_progress',
          label: '本月进度',
          value: '${monthProgress.$1}/${monthProgress.$2}',
          highlight: monthProgress.$1 > 0,
          color: Colors.indigo,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      final l10n = DiaryLocalizations.of(context);

      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats();

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.name,
        pluginIcon: Icons.menu_book,
        pluginDefaultColor: Colors.indigo,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
