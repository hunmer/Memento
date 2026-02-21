/// 计时器插件 - 计时器列表小组件注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

// 导入 Providers
import 'package:Memento/plugins/timer/home_widgets/providers.dart' as timer;

/// 默认显示的公共小组件类型
const CommonWidgetId defaultWidgetType = CommonWidgetId.circularMetricsCard;

/// 计时器列表小组件（基于 LiveSelectorWidget）
///
/// 默认显示 circularMetricsCard 公共小组件，支持实时更新
class _TimerListLiveWidget extends LiveSelectorWidget {
  const _TimerListLiveWidget({
    super.key,
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'timer_task_changed',
    'timer_item_changed',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    return timer.TimerCommandWidgetsProvider.provideCommonWidgets({});
  }

  @override
  String get widgetTag => 'TimerListWidget';

  @override
  Widget buildCommonWidget(
    BuildContext context,
    CommonWidgetId widgetId,
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CommonWidgetBuilder.build(
      context,
      widgetId,
      props,
      size,
      inline: true,
    );
  }
}

/// 注册 2x2 计时器列表小组件（公共小组件，无配置）
void registerTimerListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'timer_list',
      pluginId: 'timer',
      name: 'timer_listWidgetName'.tr,
      description: 'timer_listWidgetDesc'.tr,
      icon: Icons.timer,
      color: Colors.orange,
      defaultSize: const LargeSize(),
      supportedSizes: const [LargeSize()],
      category: 'home_categoryTools'.tr,
      commonWidgetsProvider: (data) async {
        return timer.TimerCommandWidgetsProvider.provideCommonWidgets(data);
      },
      builder: (context, config) {
        return _TimerListLiveWidget(
          config: _ensureConfigHasCommonWidget(config),
          widgetDefinition: registry.getWidget('timer_list')!,
        );
      },
    ),
  );
}

/// 确保 config 包含默认的公共小组件配置
Map<String, dynamic> _ensureConfigHasCommonWidget(
  Map<String, dynamic> config,
) {
  final newConfig = Map<String, dynamic>.from(config);
  if (!newConfig.containsKey('selectorWidgetConfig')) {
    newConfig['selectorWidgetConfig'] = {
      'commonWidgetId': defaultWidgetType.name,
      'usesCommonWidget': true,
      'commonWidgetProps': {},
    };
  }
  return newConfig;
}
