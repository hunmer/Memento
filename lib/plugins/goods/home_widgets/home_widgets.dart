/// 物品管理插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerWarehouseSelectorWidget] - 仓库选择器组件
/// - [registerItemSelectorWidget] - 物品选择器组件
/// - [registerGoodsListWidget] - 物品列表组件（带过滤器）
library;

export 'utils.dart';
export 'providers.dart';
export 'widgets.dart';

// 注册文件
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_warehouse_selector.dart';
export 'register_item_selector.dart';
export 'register_goods_list_widget.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_warehouse_selector.dart';
import 'register_item_selector.dart';
import 'register_goods_list_widget.dart';

/// 注册所有物品管理插件的小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerWarehouseSelectorWidget(registry);
  registerItemSelectorWidget(registry);
  registerGoodsListWidget(registry);
}
