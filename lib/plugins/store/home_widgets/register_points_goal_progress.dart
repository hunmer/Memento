/// 积分商店插件 - 积分目标进度注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'widgets/points_goal_progress_widget.dart';
import '../store_plugin.dart';

/// 注册积分目标进度小组件
void registerPointsGoalProgressWidget(HomeWidgetRegistry registry) {
  // 积分目标进度小组件 - 1x2 显示进度条
  registry.register(
    HomeWidget(
      id: 'store_points_goal_progress',
      pluginId: 'store',
      name: '积分目标进度',
      description: '显示今日积分与目标的进度',
      icon: Icons.flag,
      color: Colors.orange,
      defaultSize: const MediumSize(), // 2x1
      supportedSizes: [
        const MediumSize(), // 2x1
        const LargeSize(), // 2x2
      ],
      category: 'home_categoryTools'.tr,
      selectorId: 'store.pointsGoalForm',
      dataRenderer: _renderPointsGoalProgress,
      navigationHandler: _navigateToPointsHistory,
      dataSelector: (data) {
        final dataMap = data[0] as Map<String, dynamic>;
        return {'goal': dataMap['goal'] as int};
      },
      builder: (context, config) {
        final dataMap = config['selectedData'] as Map<String, dynamic>? ?? {};
        return PointsGoalProgressWidget(config: dataMap);
      },
    ),
  );
}

/// 渲染积分目标进度
Widget _renderPointsGoalProgress(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // GenericSelectorWidget 会将 List 转换为合并的 Map
  // 所以 result.data 是 Map<String, dynamic> 类型
  final data = result.data;

  if (data is! Map<String, dynamic>) {
    return HomeWidget.buildErrorWidget(context, '数据格式错误');
  }

  final dataMap = data;
  final goal = dataMap['goal'] as int?;

  if (goal == null || goal <= 0) {
    return HomeWidget.buildErrorWidget(context, '目标值无效');
  }

  // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const ['store_points_changed'],
        onEvent: () => setState(() {}),
        child: _buildPointsGoalProgressWidget(context, goal),
      );
    },
  );
}

/// 构建积分目标进度小组件内容
Widget _buildPointsGoalProgressWidget(BuildContext context, int goal) {
  final theme = Theme.of(context);

  // 从 PluginManager 获取最新的积分数据
  final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
  if (plugin == null) {
    return HomeWidget.buildErrorWidget(
      context,
      'store_pluginNotAvailable'.tr,
    );
  }

  final todayPoints = plugin.controller.getTodayPoints();
  final progress = goal > 0 ? (todayPoints / goal).clamp(0.0, 1.0) : 0.0;
  final isCompleted = todayPoints >= goal;

  return Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // 导航到积分历史
        NavigationHelper.pushNamed(context, '/store/points_history');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.emoji_events : Icons.flag,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '今日积分目标',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isCompleted)
                  Icon(Icons.check_circle, color: Colors.black, size: 20),
              ],
            ),
            const SizedBox(height: 8),

            // 高进度条+文字内嵌显示
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 高进度条（文字内嵌）
                Stack(
                  children: [
                    // 背景条
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // 进度填充
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // 文字内嵌在进度条中
                    SizedBox(
                      height: 48,
                      child: Center(
                        child: Text(
                          '$todayPoints / $goal',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// 导航到积分历史
void _navigateToPointsHistory(
  BuildContext context,
  SelectorResult result,
) {
  NavigationHelper.pushNamed(context, '/store/points_history');
}
