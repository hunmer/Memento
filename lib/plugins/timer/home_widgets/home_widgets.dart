/// 计时器插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerTaskSelectorWidget] - 计时器选择器组件
/// - [registerTimerListWidget] - 计时器列表组件（公共小组件）
library;

export 'data.dart';
export 'utils.dart';
export 'providers.dart';
export 'widgets.dart';

// 注册文件
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_task_selector_widget.dart';
export 'register_timer_list_widget.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_task_selector_widget.dart';
import 'register_timer_list_widget.dart';

/// 注册所有插件的小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerTaskSelectorWidget(registry);
  registerTimerListWidget(registry);
}
