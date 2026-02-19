/// 纪念日插件 - 纪念日选择器组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'providers.dart';

/// 注册纪念日快捷入口 - 选择纪念日后显示倒计时
void registerMemorialSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'day_memorial_selector',
      pluginId: 'day',
      name: 'day_memorialSelectorName'.tr,
      description: 'day_memorialSelectorDescription'.tr,
      icon: Icons.celebration,
      color: Colors.black87,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryRecord'.tr,
      selectorId: 'day.memorial',
      dataSelector: extractMemorialDayData,
      navigationHandler: navigateToMemorialDay,
      // 使用公共小组件提供者
      commonWidgetsProvider: provideMemorialDayCommonWidgets,
      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('day_memorial_selector')!,
          config: config,
        );
      },
    ),
  );
}
