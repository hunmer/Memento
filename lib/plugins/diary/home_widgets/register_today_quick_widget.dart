/// 日记插件 - 今日快捷入口组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册今日日记快捷入口小组件（1x1）
void registerTodayQuickWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'diary_today_quick',
      pluginId: 'diary',
      name: 'diary_todayQuickName'.tr,
      description: 'diary_todayQuickDescription'.tr,
      icon: Icons.edit_calendar,
      color: Colors.indigo,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryRecord'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.edit_calendar,
            color: Colors.indigo,
            name: 'diary_todayQuickName'.tr,
          ),
    ),
  );
}
