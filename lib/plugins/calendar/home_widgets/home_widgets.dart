/// 日历插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerQuickAddWidget] - 1x1 快速添加事件组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerEventListWidget] - 2x2 七天事件列表组件
library;

// 导出数据提供者
export 'providers.dart';

// 导出注册文件
export 'register_icon_widget.dart';
export 'register_quick_add_widget.dart';
export 'register_overview_widget.dart';
export 'register_event_list_widget.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_quick_add_widget.dart';
import 'register_overview_widget.dart';
import 'register_event_list_widget.dart';

/// 注册所有日历插件的小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerQuickAddWidget(registry);
  registerOverviewWidget(registry);
  registerEventListWidget(registry);
}
