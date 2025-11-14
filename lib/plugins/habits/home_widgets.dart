import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/widgets/generic_plugin_widget.dart';
import '../../screens/home_screen/models/plugin_widget_config.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'habits_plugin.dart';
import 'l10n/habits_localizations.dart';

/// 习惯追踪插件的主页小组件注册
class HabitsHomeWidgets {
  /// 注册所有习惯追踪插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'habits_icon',
      pluginId: 'habits',
      name: '习惯追踪',
      description: '快速打开习惯追踪',
      icon: Icons.auto_awesome,
      color: Colors.amber,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.auto_awesome,
        color: Colors.amber,
        name: '习惯',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'habits_overview',
      pluginId: 'habits',
      name: '习惯概览',
      description: '显示习惯和技能统计',
      icon: Icons.trending_up,
      color: Colors.amber,
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
      final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) return [];

      final habitController = plugin.getHabitController();
      final skillController = plugin.getSkillController();
      final timerController = plugin.timerController;

      final habitCount = habitController.getHabits().length;
      final skillCount = skillController.getSkills().length;
      final activeTimers = timerController.getActiveTimers();
      final activeTimerCount = activeTimers.values.where((v) => v).length;

      return [
        StatItemData(
          id: 'habits_count',
          label: '习惯数',
          value: '$habitCount',
          highlight: habitCount > 0,
          color: Colors.amber,
        ),
        StatItemData(
          id: 'skills_count',
          label: '技能数',
          value: '$skillCount',
          highlight: false,
        ),
        StatItemData(
          id: 'active_timers_count',
          label: '活动计时器',
          value: '$activeTimerCount',
          highlight: activeTimerCount > 0,
          color: Colors.orange,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      final l10n = HabitsLocalizations.of(context);

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
        pluginIcon: Icons.auto_awesome,
        pluginDefaultColor: Colors.amber,
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
