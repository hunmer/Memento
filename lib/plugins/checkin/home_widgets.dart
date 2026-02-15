library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'checkin_plugin.dart';
import 'models/checkin_item.dart';

part 'home_widget_data_providers.dart';
part 'home_widget_helpers.dart';

/// 打卡插件的主页小组件注册
class CheckinHomeWidgets {
  /// 注册所有打卡插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'checkin_icon',
        pluginId: 'checkin',
        name: 'checkin_widgetName'.tr,
        description: 'checkin_widgetDescription'.tr,
        icon: Icons.checklist,
        color: Colors.teal,
        defaultSize: const SmallSize(),
        supportedSizes: [const SmallSize()],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.checklist,
              color: Colors.teal,
              name: 'checkin_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'checkin_overview',
        pluginId: 'checkin',
        name: 'checkin_overviewName'.tr,
        description: 'checkin_overviewDescription'.tr,
        icon: Icons.checklist_rtl,
        color: Colors.teal,
        defaultSize: const LargeSize(),
        supportedSizes: [const LargeSize()],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 签到项目选择器小组件 - 快速访问指定签到项目
    registry.register(
      HomeWidget(
        id: 'checkin_item_selector',
        pluginId: 'checkin',
        name: 'checkin_quickAccess'.tr,
        description: 'checkin_quickAccessDesc'.tr,
        icon: Icons.access_time,
        color: Colors.teal,
        defaultSize: const MediumSize(),
        supportedSizes: [const MediumSize(), const CustomSize(width: -1, height: -1)],
        category: 'home_categoryRecord'.tr,
        selectorId: 'checkin.item',
        navigationHandler: _navigateToCheckinItem,
        dataSelector: _extractCheckinItemData,
        // 公共小组件提供者
        commonWidgetsProvider: _provideCommonWidgets,
        builder: (context, config) {
          // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
          return StatefulBuilder(
            builder: (context, setState) {
              return EventListenerContainer(
                events: const [
                  'checkin_completed', // 打卡完成
                  'checkin_cancelled', // 取消打卡
                  'checkin_reset', // 重置记录
                  'checkin_deleted', // 删除项目
                ],
                onEvent: () => setState(() {}),
                child: HomeWidget.buildDynamicSelectorWidget(
                  context,
                  config,
                  registry.getWidget('checkin_item_selector')!,
                ),
              );
            },
          );
        },
      ),
    );

    // 多选签到项目小组件 - 显示多个签到项目的打卡状态
    registry.register(
      HomeWidget(
        id: 'checkin_items_selector',
        pluginId: 'checkin',
        name: 'checkin_multiQuickAccess'.tr,
        description: 'checkin_multiQuickAccessDesc'.tr,
        icon: Icons.dashboard,
        color: Colors.teal,
        defaultSize: const LargeSize(),
        supportedSizes: [const LargeSize(), const CustomSize(width: -1, height: -1)],
        category: 'home_categoryRecord'.tr,
        selectorId: 'checkin.items',
        navigationHandler: _navigateToCheckinItems,
        dataSelector: _extractCheckinsData,
        // 公共小组件提供者
        commonWidgetsProvider: _provideCommonWidgetsForMultiple,
        builder: (context, config) {
          // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
          return StatefulBuilder(
            builder: (context, setState) {
              return EventListenerContainer(
                events: const [
                  'checkin_completed', // 打卡完成
                  'checkin_cancelled', // 取消打卡
                  'checkin_reset', // 重置记录
                  'checkin_deleted', // 删除项目
                ],
                onEvent: () => setState(() {}),
                child: HomeWidget.buildDynamicSelectorWidget(
                  context,
                  config,
                  registry.getWidget('checkin_items_selector')!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
