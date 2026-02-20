/// 活动插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerLastActivityWidget] - 1x2 上次活动组件
/// - [registerCommonWidgets] - 公共小组件样式
/// - [registerWeeklyChartWidget] - 七天活动统计图表
/// - [registerTagWeeklyChartWidget] - 标签七天统计图表
library;

export 'data.dart';
export 'utils.dart';
export 'providers.dart';
export 'widgets.dart';

// 注册文件
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_last_activity.dart';
export 'register_common_widgets.dart';
export 'register_weekly_chart.dart';
export 'register_tag_weekly_chart.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_last_activity.dart';
import 'register_common_widgets.dart';
import 'register_weekly_chart.dart';
import 'register_tag_weekly_chart.dart';

/// 注册所有活动插件的小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerLastActivityWidget(registry);
  registerCommonWidgets(registry);
  registerWeeklyChartWidget(registry);
  registerTagWeeklyChartWidget(registry);
}
