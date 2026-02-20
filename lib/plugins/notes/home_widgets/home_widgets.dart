/// 笔记插件主页小组件注册入口
///
/// 此文件负责注册所有笔记插件的主页小组件
library;

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';

import 'register_icon_widget.dart' show registerIconWidget;
import 'register_overview_widget.dart' show registerOverviewWidget;
import 'register_notes_list_widget.dart' show registerNotesListWidget;

/// 笔记插件的主页小组件注册
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerNotesListWidget(registry);
}
