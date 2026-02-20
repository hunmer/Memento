/// 日记插件 - 七日周报组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'providers.dart';

/// 注册七日周报小组件（支持多种公共组件样式）
void registerWeeklyWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'diary_weekly',
      pluginId: 'diary',
      name: 'diary_weeklyName'.tr,
      description: 'diary_weeklyDescription'.tr,
      icon: Icons.calendar_view_week,
      color: Colors.indigo,
      defaultSize: const Wide2Size(),
      supportedSizes: [const WideSize(), const Wide2Size()],
      category: 'home_categoryRecord'.tr,
      commonWidgetsProvider: provideWeeklyDiaryWidgets,
      builder: (context, config) {
        return buildWeeklyDiaryWidget(context, config);
      },
    ),
  );
}
