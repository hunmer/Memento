import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'checkin_plugin.dart';

/// 打卡插件的主页小组件注册
class CheckinHomeWidgets {
  /// 注册所有打卡插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'checkin_icon',
      pluginId: 'checkin',
      name: 'checkin_widgetName'.tr,
      description: 'checkin_widgetDescription'.tr,
      icon: Icons.checklist,
      color: Colors.teal,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.checklist,
        color: Colors.teal,
        name: 'checkin_widgetName'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'checkin_overview',
      pluginId: 'checkin',
      name: 'checkin_overviewName'.tr,
      description: 'checkin_overviewDescription'.tr,
      icon: Icons.checklist_rtl,
      color: Colors.teal,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));

    // 签到项目选择器小组件 - 快速访问指定签到项目
    registry.register(HomeWidget(
      id: 'checkin_item_selector',
      pluginId: 'checkin',
      name: 'checkin_quickAccess'.tr,
      description: 'checkin_quickAccessDesc'.tr,
      icon: Icons.access_time,
      color: Colors.teal,
      defaultSize: HomeWidgetSize.medium,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,
      selectorId: 'checkin.item',
      dataRenderer: _renderCheckinItemData,
      navigationHandler: _navigateToCheckinItem,
      builder: (context, config) => GenericSelectorWidget(
        widgetDefinition: registry.getWidget('checkin_item_selector')!,
        config: config,
      ),
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {

      final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
      if (plugin == null) return [];

      final todayCheckins = plugin.getTodayCheckins();
      final totalItems = plugin.checkinItems.length;
      final totalCheckins = plugin.getTotalCheckins();

      return [
        StatItemData(
          id: 'today_checkin',
          label: 'checkin_todayCheckin'.tr,
          value: '$todayCheckins/$totalItems',
          highlight: todayCheckins > 0,
          color: Colors.teal,
        ),
        StatItemData(
          id: 'total_count',
          label: 'checkin_totalCheckinCount'.tr,
          value: '$totalCheckins',
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
        pluginId: 'checkin',
        pluginName: 'checkin_name'.tr,
        pluginIcon: Icons.checklist,
        pluginDefaultColor: Colors.teal,
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

  // ===== 签到项目选择器小组件相关方法 =====

  /// 渲染签到项目数据
  static Widget _renderCheckinItemData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    if (result.data == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final itemData = result.data as Map<String, dynamic>;
    final name = itemData['name'] as String? ?? '未知项目';
    final group = itemData['group'] as String?;
    final iconCode = itemData['icon'] as int? ?? 57455;
    final colorValue = itemData['color'] as int? ?? 4280391411;

    // 获取今日打卡状态
    bool isCheckedToday = false;
    try {
      final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
      if (plugin != null) {
        final items = plugin.checkinItems;
        final item = items.firstWhere(
          (i) => i.id == itemData['id'],
          orElse: () => throw Exception('not found'),
        );
        isCheckedToday = item.isCheckedToday();
      }
    } catch (e) {
      isCheckedToday = false;
    }

    final itemColor = Color(colorValue);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: itemColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group ?? '未分类',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCheckedToday
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCheckedToday ? '已打卡' : '未打卡',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCheckedToday ? Colors.green : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    IconData(iconCode, fontFamily: 'MaterialIcons'),
                    color: itemColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const Spacer(),
                Text(
                  'tapToCheckin'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 导航到签到项目详情
  static void _navigateToCheckinItem(
    BuildContext context,
    SelectorResult result,
  ) {
    final itemData = result.data as Map<String, dynamic>;
    final itemId = itemData['id'] as String?;

    if (itemId != null) {
      NavigationHelper.pushNamed(
        context,
        '/checkin',
        arguments: {'itemId': itemId},
      );
    }
  }
}
