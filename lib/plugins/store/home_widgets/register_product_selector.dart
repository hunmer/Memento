/// 积分商店插件 - 商品选择器注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/store/store_plugin.dart';

/// 商品选择器小组件（基于 LiveSelectorWidget）
///
/// 默认显示 goodsItemSelector 公共小组件，支持实时更新
class _ProductSelectorLiveWidget extends LiveSelectorWidget {
  const _ProductSelectorLiveWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'store_cache_updated',
  ];

  @override
  Future<Map<String, Map<String, dynamic>>> getLiveData(Map<String, dynamic> config) async {
    return _provideCommonWidgets({});
  }

  @override
  String get widgetTag => 'ProductSelectorWidget';

  @override
  Widget buildCommonWidget(
    BuildContext context,
    CommonWidgetId widgetId,
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CommonWidgetBuilder.build(
      context,
      widgetId,
      props,
      size,
      inline: true,
    );
  }
}

/// 提供商品选择器公共小组件数据
Future<Map<String, Map<String, dynamic>>> _provideCommonWidgets(
  Map<String, dynamic> data,
) async {
  final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
  if (plugin == null) return {};

  final controller = plugin.controller;
  final products = controller.products.map((p) => p.toJson()).toList();
  final archivedProducts = controller.archivedProducts.map((p) => p.toJson()).toList();

  // 合并商品和存档商品
  final allProducts = [...products, ...archivedProducts];

  // 默认显示前 3 个有库存的商品
  final inStockProducts = allProducts
      .where((p) => (p['stock'] as int? ?? 0) > 0)
      .take(3)
      .map((p) => {
            'id': p['id'] as String,
            'name': p['name'] as String,
            'description': p['description'] as String? ?? '',
            'price': p['price'] as int,
            'stock': p['stock'] as int,
            'image': p['image'] as String?,
          })
      .toList();

  return {
    'storeProductSelector': {
      'products': inStockProducts,
      'productCount': inStockProducts.length,
    },
  };
}

/// 注册商品选择器小组件（公共小组件，无配置）
void registerProductSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'store_product_selector',
      pluginId: 'store',
      name: 'store_productQuickAccess'.tr,
      description: 'store_productQuickAccessDesc'.tr,
      icon: Icons.shopping_bag,
      color: Colors.pinkAccent,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryTools'.tr,
      commonWidgetsProvider: _provideCommonWidgets,
      builder: (context, config) {
        return _ProductSelectorLiveWidget(
          config: _ensureConfigHasCommonWidget(config, CommonWidgetId.storeProductSelector),
          widgetDefinition: registry.getWidget('store_product_selector')!,
        );
      },
    ),
  );
}

/// 确保 config 包含默认的公共小组件配置
Map<String, dynamic> _ensureConfigHasCommonWidget(
  Map<String, dynamic> config,
  CommonWidgetId defaultWidgetId,
) {
  final newConfig = Map<String, dynamic>.from(config);
  if (!newConfig.containsKey('selectorWidgetConfig')) {
    newConfig['selectorWidgetConfig'] = {
      'commonWidgetId': defaultWidgetId.name,
      'usesCommonWidget': true,
      'commonWidgetProps': {},
    };
  }
  return newConfig;
}
