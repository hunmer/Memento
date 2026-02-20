/// 日记插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerWeeklyWidget] - 4x1 七日周报组件
/// - [registerMonthlyDiaryListWidget] - 本月日记列表组件（支持多种公共小组件）
library;

// 导出所有公共模块
export 'data.dart';
export 'utils.dart';
export 'providers.dart';
export 'widgets.dart';

// 导出注册文件
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_weekly_widget.dart';
export 'register_monthly_diary_list.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_weekly_widget.dart';
import 'register_monthly_diary_list.dart';

/// 注册所有日记插件的小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerWeeklyWidget(registry);
  registerMonthlyDiaryListWidget(registry);
}
