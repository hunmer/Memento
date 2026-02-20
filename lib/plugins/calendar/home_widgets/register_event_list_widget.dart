/// 日历插件 - 事件列表小组件注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

// 导入 CommandWidgetsProvider
import 'package:Memento/plugins/calendar/home_widgets/providers/command_widgets_provider.dart'
    as cmd;

/// 默认显示的公共小组件类型
const CommonWidgetId defaultWidgetType = CommonWidgetId.dailyEventsCard;

/// 日历插件颜色
const Color _calendarColor = Color.fromARGB(255, 211, 91, 91);

/// 日历事件列表小组件（基于 LiveSelectorWidget）
///
/// 默认显示 dailyEventsCard 公共小组件，支持实时更新
class _CalendarEventListLiveWidget extends LiveSelectorWidget {
  const _CalendarEventListLiveWidget({
    super.key,
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'calendar_event_added',
    'calendar_event_updated',
    'calendar_event_deleted',
    'calendar_event_completed',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    return cmd.CalendarCommandWidgetsProvider.provideCommonWidgets({});
  }

  @override
  String get widgetTag => 'CalendarEventListWidget';

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

/// 注册 2x2 日历事件列表小组件（公共小组件，支持配置）
void registerEventListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'calendar_event_list',
      pluginId: 'calendar',
      name: 'calendar_eventListWidgetName'.tr,
      description: 'calendar_eventListWidgetDesc'.tr,
      icon: Icons.event,
      color: _calendarColor,
      defaultSize: const LargeSize(),
      supportedSizes: const [
        LargeSize(),
        Large3Size(),
        Wide2Size(),
        Wide3Size(),
      ],
      category: 'home_categoryTools'.tr,
      commonWidgetsProvider: (data) async {
        return cmd.CalendarCommandWidgetsProvider.provideCommonWidgets(data);
      },
      builder: (context, config) {
        return _CalendarEventListLiveWidget(
          config: _ensureConfigHasCommonWidget(config),
          widgetDefinition: registry.getWidget('calendar_event_list')!,
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
