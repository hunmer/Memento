/// 积分商店插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerPointsGoalProgressWidget] - 积分目标进度小组件（公共小组件）
/// - [registerProductSelectorWidget] - 商品选择器小组件（公共小组件）
/// - [registerUserItemSelectorWidget] - 用户物品选择器小组件（公共小组件）
library;

// 导出模块
export 'data.dart';
export 'utils.dart';
export 'providers.dart';
export 'widgets.dart';

// 注册文件
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_points_goal_progress.dart';
export 'register_product_selector.dart';
export 'register_user_item_selector.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_points_goal_progress.dart';
import 'register_product_selector.dart';
import 'register_user_item_selector.dart';

/// 注册所有积分商店插件的小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerPointsGoalProgressWidget(registry);
  registerProductSelectorWidget(registry);
  registerUserItemSelectorWidget(registry);
}
