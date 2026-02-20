/// 习惯追踪插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerHabitHeatmapWidget] - 习惯热力图选择器组件
/// - [registerActivityStatsWidget] - 活动统计公共小组件
/// - [registerHabitStatsWidget] - 习惯统计公共小组件
library;

export 'data.dart';
export 'utils.dart';
export 'providers.dart';
export 'widgets.dart';

// 注册文件
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_habit_heatmap.dart';
export 'register_activity_stats_widget.dart';
export 'register_habit_stats_widget.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_habit_heatmap.dart';
import 'register_activity_stats_widget.dart';
import 'register_habit_stats_widget.dart';

/// 注册所有习惯追踪插件的小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerHabitHeatmapWidget(registry);
  registerHabitStatsWidget(registry);
  registerActivityStatsWidget(registry);
}
