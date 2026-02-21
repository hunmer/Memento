/// WebView插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - [registerCardSelectorWidget] - URL 卡片选择器小组件
/// - [registerEmbeddedWidget] - 内置网页小组件
library;

export 'data.dart';
export 'utils.dart';
export 'providers.dart';
export 'widgets.dart';

// 注册文件
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_card_selector.dart';
export 'register_embedded_widget.dart';
export 'register_card_list_widget.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_card_selector.dart';
import 'register_embedded_widget.dart';
import 'register_card_list_widget.dart';

/// 注册所有WebView插件的小组件
void register() {
  final registry = HomeWidgetRegistry();
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerCardSelectorWidget(registry);
  registerEmbeddedWidget(registry);
  registerCardListWidget(registry);
}
