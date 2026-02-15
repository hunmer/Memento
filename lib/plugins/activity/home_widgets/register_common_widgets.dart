/// 活动插件 - 公共组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'providers.dart';

/// 注册公共小组件（活动小组件 - 支持公共小组件样式）
void registerCommonWidgets(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_common_widgets',
      pluginId: 'activity',
      name: 'activity_commonWidgetsName'.tr,
      description: 'activity_commonWidgetsDesc'.tr,
      icon: Icons.dashboard,
      color: Colors.pink,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize(), const CustomSize(width: -1, height: -1)],
      category: 'home_categoryRecord'.tr,
      commonWidgetsProvider: provideCommonWidgets,
      builder: (context, config) {
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const [
                'activity_added',
                'activity_updated',
                'activity_deleted',
                'activity_cache_updated', // 缓存刷新完成事件
              ],
              onEvent: () => setState(() {}),
              child: buildCommonWidgetsWidget(context, config),
            );
          },
        );
      },
    ),
  );
}
