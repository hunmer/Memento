/// 打卡插件 - 签到项目选择器小组件注册
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

/// 注册签到项目选择器小组件 - 快速访问指定签到项目
void registerItemSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'checkin_item_selector',
      pluginId: 'checkin',
      name: 'checkin_quickAccess'.tr,
      description: 'checkin_quickAccessDesc'.tr,
      icon: Icons.access_time,
      color: Colors.teal,
      defaultSize: const MediumSize(),
      supportedSizes: [
        const MediumSize(),
        const CustomSize(width: -1, height: -1),
      ],
      category: 'home_categoryRecord'.tr,
      selectorId: 'checkin.item',
      navigationHandler: _navigateToCheckinItem,
      dataSelector: extractCheckinItemData,
      // 公共小组件提供者
      commonWidgetsProvider: provideCommonWidgets,
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
}

/// 导航到签到项目详情
void _navigateToCheckinItem(
  BuildContext context,
  SelectorResult result,
) {
  // 从 result.data 获取已转换的数据（由 dataSelector 处理）
  final data =
      result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : {};
  final itemId = data['id'] as String?;

  if (itemId != null) {
    NavigationHelper.pushNamed(
      context,
      '/checkin/item',
      arguments: {'itemId': itemId},
    );
  }
}
