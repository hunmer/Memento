import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:get/get.dart';
import 'diary_plugin.dart';

/// 日记插件的主页小组件注册
class DiaryHomeWidgets {
  /// 注册所有日记插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'diary_icon',
      pluginId: 'diary',
      name: 'diary_widgetName'.tr,
      description: 'diary_widgetDescription'.tr,
      icon: Icons.book,
      color: Colors.indigo,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryRecord'.tr,
        builder:
            (context, config) =>
                GenericIconWidget(
                  icon: Icons.book,
                  color: Colors.indigo,
                  name: 'diary_widgetName'.tr,
                ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'diary_overview',
      pluginId: 'diary',
      name: 'diary_overviewName'.tr,
      description: 'diary_overviewDescription'.tr,
      icon: Icons.menu_book,
      color: Colors.indigo,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
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
          label: 'diary_todayWordCount'.tr,
          value: '$todayCount',
          highlight: todayCount > 0,
          color: Colors.indigo,
        ),
        StatItemData(
          id: 'month_word_count',
          label: 'diary_monthWordCount'.tr,
          value: '$monthCount',
          highlight: false,
        ),
        StatItemData(
          id: 'month_progress',
          label: 'diary_monthProgress'.tr,
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
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'diary',
        pluginName: 'diary_name'.tr,
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
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
