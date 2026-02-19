/// 活动插件 - 七天图表组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'providers.dart';

/// 注册七天活动统计图表小组件
void registerWeeklyChartWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_weekly_chart',
      pluginId: 'activity',
      name: '七天活动统计',
      description: '展示近七天的活动时长统计，支持多种图表样式',
      icon: Icons.bar_chart,
      color: Colors.pink,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize(), const CustomSize(width: -1, height: -1)],
      category: 'home_categoryRecord'.tr,
      commonWidgetsProvider: provideWeeklyChartWidgets,
      builder: (context, config) {
        return _WeeklyChartStatefulWidget(config: config);
      },
    ),
  );
}

/// 周图表专用 StatefulWidget，监听 activity_cache_updated 事件（携带数据）
class _WeeklyChartStatefulWidget extends StatefulWidget {
  final Map<String, dynamic> config;

  const _WeeklyChartStatefulWidget({required this.config});

  @override
  State<_WeeklyChartStatefulWidget> createState() => _WeeklyChartStatefulWidgetState();
}

class _WeeklyChartStatefulWidgetState extends State<_WeeklyChartStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const [
        'activity_cache_updated', // 监听缓存更新事件
      ],
      onEventWithData: (args) {
        // 事件触发时重建组件，获取最新数据
        if (args is ActivityCacheUpdatedEventArgs) {
          setState(() {});
        }
      },
      child: buildCommonWidgetsWidget(context, widget.config),
    );
  }
}
