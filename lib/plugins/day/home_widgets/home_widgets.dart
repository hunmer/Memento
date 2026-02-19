/// 纪念日插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerMemorialSelectorWidget] - 纪念日选择器组件
/// - [registerDateRangeListWidget] - 日期范围列表组件
library;

// 导出数据模型
export 'data.dart';
// 导出工具函数
export 'utils.dart';
// 导出数据提供者
export 'providers.dart';
// 导出小组件组件
export 'widgets.dart';

// 导出注册文件
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_memorial_selector_widget.dart';
export 'register_date_range_list_widget.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_memorial_selector_widget.dart';
import 'register_date_range_list_widget.dart';

/// 注册所有纪念日插件的小组件
void register() {
  final registry = HomeWidgetRegistry();

  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerMemorialSelectorWidget(registry);
  registerDateRangeListWidget(registry);
}
