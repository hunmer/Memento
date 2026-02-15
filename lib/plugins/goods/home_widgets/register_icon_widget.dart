/// 物品管理插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 注册图标组件 (1x1)
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'goods_icon',
      pluginId: 'goods',
      name: 'goods_widgetName'.tr,
      description: 'goods_widgetDescription'.tr,
      icon: Icons.inventory_2,
      color: _goodsColor,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.inventory_2,
        color: _goodsColor,
        name: 'goods_widgetName'.tr,
      ),
    ),
  );
}
