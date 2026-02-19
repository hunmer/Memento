/// 物品管理插件 - 物品列表小组件注册
///
/// 注册物品列表小组件，支持仓库、标签、购入日期、过期日期过滤
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
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

      // 公共组件提供者（用于配置时预览）
      commonWidgetsProvider: provideGoodsListWidgets,

      // 导航处理器：点击时打开物品列表页面
      navigationHandler: _navigateToGoodsList,

      // 数据选择器：提取过滤器参数
      dataSelector: _extractFilterData,

      builder: (context, config) {
        return _GoodsListLiveSelectorWidget(
          widgetDefinition: registry.getWidget('goods_list_widget')!,
          config: config,
        );
      },
    ),
  );
}

/// 导航到物品列表页面
void _navigateToGoodsList(
  BuildContext context,
  SelectorResult result,
) {
  final data = result.data as Map<String, dynamic>?;
  if (data == null) {
    debugPrint('[GoodsListWidget] 过滤器数据为空');
    return;
  }

  // 获取过滤器参数
  final warehouseId = data['warehouseId'] as String?;
  final tags = data['tags'] as List<dynamic>?;
  final startDate = data['startDate'] as String?;
  final endDate = data['endDate'] as String?;

  // 导航到物品列表页面，传递过滤器参数
  NavigationHelper.pushNamed(
    context,
    '/goods',
    arguments: {
      'filterWarehouseId': warehouseId,
      'filterTags': tags,
      'filterStartDate': startDate,
      'filterEndDate': endDate,
      'showGoodsTab': true, // 显示物品标签页而不是仓库标签页
    },
  );
}

/// 提取过滤器数据
Map<String, dynamic> _extractFilterData(List<dynamic> data) {
  // 数据格式为 [{warehouseId: ..., tags: [...], startDate: ..., endDate: ...}]
  if (data.isEmpty) return {};
  final item = data.first as Map<String, dynamic>;
  return item;
}

/// 物品列表小组件 - 实时数据选择器版本
///
/// 使用 LiveSelectorWidget 基类，减少重复代码
class _GoodsListLiveSelectorWidget extends LiveSelectorWidget {
  const _GoodsListLiveSelectorWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'goods_item_added',
    'goods_item_deleted',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) {
    return provideGoodsListWidgets(config);
  }

  @override
  String get widgetTag => 'GoodsListWidget';

  /// 自定义空状态（显示"暂无物品"）
  @override
  Widget buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'goods_noItems'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
