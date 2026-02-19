/// 打卡插件 - 多选签到项目小组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'providers.dart';
import 'utils.dart';

/// 注册多选签到项目小组件 - 显示多个签到项目的打卡状态
void registerItemsSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'checkin_items_selector',
      pluginId: 'checkin',
      name: 'checkin_multiQuickAccess'.tr,
      description: 'checkin_multiQuickAccessDesc'.tr,
      icon: Icons.dashboard,
      color: Colors.teal,
      defaultSize: const LargeSize(),
      supportedSizes: [
        const LargeSize(),
        const CustomSize(width: -1, height: -1),
      ],
      category: 'home_categoryRecord'.tr,
      selectorId: 'checkin.items',
      navigationHandler: _navigateToCheckinItems,
      dataSelector: extractCheckinsData,
      // 公共小组件提供者
      commonWidgetsProvider: provideCommonWidgetsForMultiple,
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

/// 导航到签到项目列表（多选模式）
void _navigateToCheckinItems(
  BuildContext context,
  SelectorResult result,
) {
  // 多选模式默认导航到签到主列表
  NavigationHelper.pushNamed(context, '/checkin');
}
