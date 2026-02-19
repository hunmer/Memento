/// 聊天插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerChannelSelector] - 频道选择器组件
library;

// 导出子模块
export 'data.dart';
export 'utils.dart';
export 'providers.dart';
export 'builders.dart';
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_channel_selector.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_channel_selector.dart';

/// 注册所有聊天插件的小组件
///
/// 该函数会在应用初始化时被调用，注册所有聊天相关的主页小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerChannelSelector(registry);
}
