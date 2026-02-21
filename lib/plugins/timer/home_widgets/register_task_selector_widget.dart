/// 计时器插件 - 计时器选择器组件注册
library;

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'utils.dart';
import 'widgets.dart';
import '../models/timer_task.dart';
import '../timer_plugin.dart';

/// 注册计时器选择器小组件 - 快速访问指定计时器详情
void registerTaskSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'timer_task_selector',
      pluginId: 'timer',
      name: 'timer_quickAccess'.tr,
      description: 'timer_quickAccessDesc'.tr,
      icon: Icons.timer,
      color: Colors.blueGrey,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      selectorId: 'timer.task',
      dataRenderer: renderTimerData,
      navigationHandler: navigateToTimerDetail,
      dataSelector: extractTimerData,
      builder: (context, config) => GenericSelectorWidget(
        widgetDefinition: registry.getWidget('timer_task_selector')!,
        config: config,
      ),
    ),
  );
}

/// 渲染计时器数据
Widget renderTimerData(
  BuildContext context,
  dynamic result,
  Map<String, dynamic> config,
) {
  final taskId = getTaskIdFromResult(result);

  if (taskId == null) {
    return HomeWidget.buildErrorWidget(context, '计时器ID不存在');
  }

  // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const [
          'timer_item_changed',
          'timer_task_changed',
          'timer_item_progress',
        ],
        onEvent: () => setState(() {}),
        child: buildTimerWidget(context, taskId),
      );
    },
  );
}

/// 构建计时器小组件内容（获取最新数据）
Widget buildTimerWidget(BuildContext context, String taskId) {
  final theme = Theme.of(context);

  // 从 PluginManager 获取最新的计时器数据
  final plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
  if (plugin == null) {
    return HomeWidget.buildErrorWidget(context, '计时器插件未加载');
  }

  final tasks = plugin.getTasks();
  final task = tasks.cast<TimerTask?>().firstWhere(
    (t) => t?.id == taskId,
    orElse: () => null,
  );

  if (task == null) {
    return HomeWidget.buildErrorWidget(context, '计时器不存在');
  }

  final taskColor = task.color;

  // 获取计时器信息
  final timerItems = task.timerItems;
  String timerType = '';
  if (timerItems.isNotEmpty) {
    final firstTimer = timerItems.first;
    final type = firstTimer.type.index;
    final duration = firstTimer.duration.inSeconds;
    timerType = getTimerTypeDescription(type, duration);
  }

  return SizedBox.expand(
    child: GestureDetector(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标
          Icon(
            task.icon,
            size: 32,
            color: taskColor,
          ),
          const SizedBox(height: 8),
          // 计时器名称
          Text(
            task.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // 计时类型 badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: taskColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              timerType,
              style: theme.textTheme.labelSmall?.copyWith(color: taskColor),
            ),
          ),
          const SizedBox(height: 8),
          // 计时显示 (00:00) - 实时更新
          TimerDisplayWidget(taskId: taskId, taskColor: taskColor),
        ],
      ),
    ),
  );
}

/// 导航到计时器详情页面
void navigateToTimerDetail(
  BuildContext context,
  dynamic result,
) {
  final taskId = getTaskIdFromResult(result);
  if (taskId == null) return;

  NavigationHelper.pushNamed(
    context,
    '/timer_details',
    arguments: {'taskId': taskId},
  );
}
