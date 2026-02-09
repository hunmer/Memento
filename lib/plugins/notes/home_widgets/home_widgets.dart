/// 笔记插件主页小组件注册入口
///
/// 此文件负责注册所有笔记插件的主页小组件
library;

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';

import 'register_icon_widget.dart' show registerIconWidget;
import 'register_quick_create_widget.dart' show registerQuickCreateWidget;
import 'register_overview_widget.dart' show registerOverviewWidget;
import 'register_folder_selector_widget.dart' show registerFolderSelectorWidget;

/// 笔记插件的主页小组件注册
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerQuickCreateWidget(registry);
  registerOverviewWidget(registry);
  registerFolderSelectorWidget(registry);
}
