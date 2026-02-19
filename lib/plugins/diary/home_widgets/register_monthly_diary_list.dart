/// 日记插件 - 本月日记列表组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'providers.dart';

/// 注册本月日记列表小组件
void registerMonthlyDiaryListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'diary_monthly_list',
      pluginId: 'diary',
      name: '本月日记列表',
      description: '展示本月的日记列表，支持多种小组件样式',
      icon: Icons.calendar_month,
      color: Colors.indigo,
      defaultSize: const LargeSize(),
      supportedSizes: [
        const LargeSize(),
        const CustomSize(width: -1, height: -1),
      ],
      category: 'home_categoryRecord'.tr,
      commonWidgetsProvider: provideMonthlyDiaryListWidgets,
      builder: (context, config) {
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const [
                'diary_entry_created',
                'diary_entry_updated',
                'diary_entry_deleted',
              ],
              onEvent: () => setState(() {}),
              child: buildMonthlyDiaryListWidget(context, config),
            );
          },
        );
      },
    ),
  );
}
