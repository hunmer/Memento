import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'activity_plugin.dart';
import 'screens/activity_edit_screen.dart';

/// 活动插件的主页小组件注册
class ActivityHomeWidgets {
  /// 注册所有活动插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'activity_icon',
        pluginId: 'activity',
        name: 'activity_widgetName'.tr,
        description: 'activity_widgetDescription'.tr,
        icon: Icons.timeline,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.timeline,
              color: Colors.pink,
              name: 'activity_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'activity_overview',
        pluginId: 'activity',
        name: 'activity_overviewName'.tr,
        description: 'activity_overviewDescription'.tr,
        icon: Icons.access_time,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 1x1 创建活动快捷入口 - 直接跳转
    registry.register(
      HomeWidget(
        id: 'activity_create_shortcut',
        pluginId: 'activity',
        name: 'activity_createActivityShortcut'.tr,
        description: 'activity_createActivityShortcutDesc'.tr,
        icon: Icons.add_circle,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => const ActivityCreateShortcutWidget(),
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return [];

      final activityCount = plugin.getTodayActivityCountSync();
      final activityDuration = plugin.getTodayActivityDurationSync();
      final remainingTime = plugin.getTodayRemainingTime();

      return [
        StatItemData(
          id: 'today_activities',
          label: 'activity_todayActivities'.tr,
          value: '$activityCount',
          highlight: activityCount > 0,
          color: Colors.pink,
        ),
        StatItemData(
          id: 'today_duration',
          label: 'activity_todayDuration'.tr,
          value: '${(activityDuration / 60).toStringAsFixed(1)}H',
          highlight: false,
        ),
        StatItemData(
          id: 'remaining_time',
          label: 'activity_remainingTime'.tr,
          value: '${(remainingTime / 60).toStringAsFixed(1)}H',
          highlight: remainingTime < 120,
          color: Colors.red,
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
        pluginId: 'activity',
        pluginName: 'activity_name'.tr,
        pluginIcon: Icons.access_time,
        pluginDefaultColor: Colors.pink,
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

/// 创建活动快捷入口小组件
///
/// 点击后直接打开活动创建界面,无需选择器
class ActivityCreateShortcutWidget extends StatelessWidget {
  const ActivityCreateShortcutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCreateActivity(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink.withOpacity(0.1),
                Colors.pink.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_circle,
                  size: 32,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 12),

              // 主标题
              Text(
                'activity_createActivity'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // 副标题
              Text(
                'activity_quickCreateActivityDesc'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到活动创建界面
  void _navigateToCreateActivity(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) {
        toastService.showToast('activity_loadFailed'.tr);
        return;
      }

      final activityService = plugin.activityService;
      final now = DateTime.now();

      // 打开活动编辑界面(创建模式)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => ActivityEditScreen(
                activityService: activityService,
                selectedDate: now,
                onTagsUpdated: (tags) async {
                  await activityService.saveRecentTags(tags);
                },
              ),
        ),
      );
    } catch (e) {
      toastService.showToast('activity_operationFailed'.tr);
      debugPrint('[ActivityCreateShortcut] 打开创建界面失败: $e');
    }
  }
}
