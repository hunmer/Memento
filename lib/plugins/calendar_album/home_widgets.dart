import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'calendar_album_plugin.dart';

/// 日历相册插件的主页小组件注册
class CalendarAlbumHomeWidgets {
  static const Color _pluginColor = Color.fromARGB(255, 245, 210, 52);

  /// 注册所有日历相册插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'calendar_album_icon',
      pluginId: 'calendar_album',
      name: '日历相册',
      description: '快速打开日历相册',
      icon: Icons.notes_rounded,
      color: _pluginColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.notes_rounded,
        color: _pluginColor,
        name: '日记相册',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'calendar_album_overview',
      pluginId: 'calendar_album',
      name: '日历相册概览',
      description: '显示日记和标签统计',
      icon: Icons.calendar_today,
      color: _pluginColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '记录',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('calendar_album')
          as CalendarAlbumPlugin?;
      if (plugin == null) return [];

      final l10n = CalendarAlbumLocalizations.of(context);
      final todayCount = plugin.calendarController?.getTodayEntriesCount();
      final sevenDayCount =
          plugin.calendarController?.getLast7DaysEntriesCount();
      final allEntriesCount = plugin.calendarController!.getAllEntriesCount();
      final tagCount = plugin.tagController?.tags.length;

      return [
        StatItemData(
          id: 'today_diary',
          label: l10n.todayDiary,
          value: '$todayCount',
          highlight: todayCount! > 0,
          color: _pluginColor,
        ),
        StatItemData(
          id: 'seven_day_diary',
          label: l10n.sevenDaysDiary,
          value: '$sevenDayCount',
          highlight: false,
        ),
        StatItemData(
          id: 'all_diaries',
          label: l10n.allDiaries,
          value: '$allEntriesCount',
          highlight: false,
        ),
        StatItemData(
          id: 'tag_count',
          label: l10n.tagCount,
          value: '$tagCount',
          highlight: false,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      final l10n = CalendarAlbumLocalizations.of(context);

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
        pluginName: l10n.name,
        pluginIcon: Icons.notes_rounded,
        pluginDefaultColor: _pluginColor,
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
