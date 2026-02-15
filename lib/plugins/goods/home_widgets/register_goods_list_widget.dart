/// 物品管理插件 - 物品列表小组件注册
///
/// 注册物品列表小组件，支持仓库、标签、购入日期、过期日期过滤
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'utils.dart' show goodsColor;
import 'providers.dart';

/// 注册物品列表小组件
void registerGoodsListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'goods_list_widget',
      pluginId: 'goods',
      name: 'goods_listWidgetName'.tr,
      description: 'goods_listWidgetDescription'.tr,
      icon: Icons.view_list,
      color: goodsColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const CustomSize(width: -1, height: -1), const LargeSize()],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'goods.list.config',

      // 公共组件提供者
      commonWidgetsProvider: provideGoodsListWidgets,

      builder: (context, config) {
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const ['goods_item_added', 'goods_item_deleted'],
              onEvent: () => setState(() {}),
              child: GenericSelectorWidget(
                widgetDefinition: registry.getWidget('goods_list_widget')!,
                config: config,
              ),
            );
          },
        );
      },
    ),
  );
}
