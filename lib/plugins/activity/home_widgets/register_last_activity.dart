/// 活动插件 - 上次活动组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'providers.dart' show provideLastActivityWidgets;

/// 注册上次活动小组件（1x2）
void registerLastActivityWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_last_activity',
      pluginId: 'activity',
      name: '上次活动',
      description: '显示距离上次活动经过的时间和上次活动的时间',
      icon: Icons.history,
      color: Colors.pink,
      defaultSize: const MediumSize(), // 2x1
      supportedSizes: [const MediumSize()],
      category: 'home_categoryRecord'.tr,

      // 公共组件提供者（用于配置时预览）
      commonWidgetsProvider: provideLastActivityWidgets,

      // 导航处理器：点击时打开活动编辑界面
      navigationHandler: _navigateToActivity,

      // 数据选择器：提取配置参数
      dataSelector: _extractConfigData,

      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('activity_last_activity')!,
          config: config,
        );
      },
    ),
  );
}

/// 导航到活动编辑界面
void _navigateToActivity(
  BuildContext context,
  SelectorResult result,
) {
  NavigationHelper.pushNamed(
    context,
    '/activity',
  );
}

/// 提取配置数据
Map<String, dynamic> _extractConfigData(List<dynamic> data) {
  // 上次活动小组件不需要选择数据，返回空配置
  return {};
}
