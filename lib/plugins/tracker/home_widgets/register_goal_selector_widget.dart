/// 目标追踪插件 - 目标选择器组件注册（快速访问指定目标详情）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'providers.dart';
import 'widgets.dart';
import 'utils.dart';
import '../tracker_plugin.dart';

/// 注册目标选择器小组件
void registerGoalSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'tracker_goal_selector',
      pluginId: 'tracker',
      name: 'tracker_quickAccess'.tr,
      description: 'tracker_quickAccessDesc'.tr,
      icon: Icons.track_changes,
      color: Colors.red,
      defaultSize: const MediumSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,
      selectorId: 'tracker.goal',
      dataRenderer: renderGoalData,
      navigationHandler: navigateToGoalDetail,
      dataSelector: extractGoalData,

      // 公共小组件提供者
      commonWidgetsProvider: provideCommonWidgets,

      builder: (context, config) {
        // 使用专用的 StatefulWidget 来持有缓存的事件数据
        return _GoalSelectorStatefulWidget(
          config: config,
          widgetDefinition: registry.getWidget('tracker_goal_selector')!,
        );
      },
    ),
  );
}

/// 内部 StatefulWidget 用于持有缓存的事件数据
class _GoalSelectorStatefulWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final HomeWidget widgetDefinition;

  const _GoalSelectorStatefulWidget({
    required this.config,
    required this.widgetDefinition,
  });

  @override
  State<_GoalSelectorStatefulWidget> createState() =>
      _GoalSelectorStatefulWidgetState();
}

class _GoalSelectorStatefulWidgetState extends State<_GoalSelectorStatefulWidget> {
  /// 缓存的目标列表（性能优化：直接使用事件携带的数据）
  List<Goal>? _cachedGoals;

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const [
        'tracker_cache_updated', // 监听目标缓存更新事件
      ],
      onEventWithData: (args) {
        if (args is TrackerCacheUpdatedEventArgs) {
          setState(() {
            _cachedGoals = args.goals; // 直接使用事件数据
          });
        }
      },
      child: _buildGoalSelectorContent(
        context,
        widget.config,
        widget.widgetDefinition,
        _cachedGoals,
      ),
    );
  }

  /// 构建目标选择器内容
  /// [cachedGoals] 事件携带的缓存数据（性能优化），为 null 时从插件获取
  Widget _buildGoalSelectorContent(
    BuildContext context,
    Map<String, dynamic> config,
    HomeWidget widgetDefinition,
    List<Goal>? cachedGoals,
  ) {
    try {
      // 解析选择器配置
      final selectorConfig =
          config['selectorWidgetConfig'] as Map<String, dynamic>?;
      if (selectorConfig == null) {
        return HomeWidget.buildErrorWidget(context, '配置错误：缺少 selectorWidgetConfig');
      }

      final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
      if (commonWidgetId == null) {
        return HomeWidget.buildErrorWidget(
          context,
          '配置错误：缺少 commonWidgetId',
        );
      }

      // 查找对应的 CommonWidgetId 枚举
      final widgetIdEnum = CommonWidgetId.values.asNameMap()[commonWidgetId];
      if (widgetIdEnum == null) {
        return HomeWidget.buildErrorWidget(context, '未知的公共小组件类型: $commonWidgetId');
      }

      // 获取小组件尺寸
      final size = config['widgetSize'] as HomeWidgetSize? ??
          widgetDefinition.defaultSize;

      // 优先使用事件携带的缓存数据（性能优化），否则从插件获取
      final latestProps = _getGoalSelectorDataSync(
        commonWidgetId,
        selectorConfig,
        cachedGoals,
      );

      if (latestProps == null) {
        return HomeWidget.buildErrorWidget(context, '无法获取目标数据');
      }

      // 合并保存的配置和实时数据（实时数据优先覆盖保存的配置）
      final mergedProps = {
        ...selectorConfig['commonWidgetProps'] as Map<String, dynamic>? ?? {},
        ...latestProps,
      };

      // 添加 custom 尺寸的实际宽高到 props 中
      final finalProps = Map<String, dynamic>.from(mergedProps);
      if (size == const CustomSize(width: -1, height: -1)) {
        finalProps['customWidth'] = config['customWidth'] as int?;
        finalProps['customHeight'] = config['customHeight'] as int?;
      }

      // 传递 _pixelCategory 以支持响应式布局
      final pixelCategory = config['_pixelCategory'] as SizeCategory?;
      if (pixelCategory != null) {
        finalProps['_pixelCategory'] = pixelCategory;
      }

      return CommonWidgetBuilder.build(
        context,
        widgetIdEnum,
        finalProps,
        size,
        inline: true,
      );
    } catch (e) {
      debugPrint('[GoalSelectorWidget] 构建失败: $e');
      return HomeWidget.buildErrorWidget(context, '构建失败: $e');
    }
  }

  /// 同步获取目标选择器小组件数据
  /// [cachedGoals] 事件携带的缓存数据（性能优化），为 null 时从插件获取
  Map<String, dynamic>? _getGoalSelectorDataSync(
    String commonWidgetId,
    Map<String, dynamic> selectorConfig,
    List<Goal>? cachedGoals,
  ) {
    try {
      // 优先使用事件携带的缓存数据（性能优化）
      List<Goal> goals;
      if (cachedGoals != null) {
        goals = cachedGoals;
      } else {
        // 回退：从插件同步获取（首次构建或向后兼容）
        final plugin = PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
        if (plugin == null) return null;
        goals = plugin.controller.goals;
      }

      // 从配置中提取目标 ID
      final selectedData = selectorConfig['selectedData'] as Map<String, dynamic>?;
      if (selectedData == null || !selectedData.containsKey('data')) {
        return null;
      }

      final dataArray = selectedData['data'] as List<dynamic>?;
      if (dataArray == null || dataArray.isEmpty) {
        return null;
      }

      // 提取目标数据
      final goalData = extractGoalData(dataArray);
      final goalId = goalData['id'] as String?;

      // 在目标列表中查找最新的目标数据
      Goal? latestGoal;
      if (goalId != null) {
        try {
          latestGoal = goals.firstWhere(
            (g) => g.id == goalId,
          );
        } catch (e) {
          // 目标可能已被删除
          latestGoal = null;
        }
      }

      if (latestGoal == null) {
        return null;
      }

      // 使用最新的目标数据调用 provideCommonWidgets
      // 将 Goal 对象转换为 Map 格式
      final dataMap = {
        'id': latestGoal.id,
        'name': latestGoal.name,
        'icon': latestGoal.icon,
        'iconColor': latestGoal.iconColor,
        'currentValue': latestGoal.currentValue,
        'targetValue': latestGoal.targetValue,
        'unitType': latestGoal.unitType,
      };

      // 由于 provideCommonWidgets 是异步的，我们需要同步版本
      // 这里我们直接计算公共小组件需要的数据
      final name = dataMap['name'] as String? ?? '目标';
      final currentValue = (dataMap['currentValue'] as double?) ?? 0.0;
      final targetValue = (dataMap['targetValue'] as double?) ?? 1.0;
      final unitType = (dataMap['unitType'] as String?) ?? '';
      final progress = (targetValue > 0 ? (currentValue / targetValue) : 0).clamp(0.0, 1.0);
      final percentage = (progress * 100).toInt();

      // 返回对应公共小组件的数据
      switch (commonWidgetId) {
        case 'circularProgressCard':
          return {
            'title': name,
            'subtitle': '已完 $currentValue / $targetValue $unitType',
            'percentage': percentage.toDouble(),
            'progress': progress,
          };
        case 'activityProgressCard':
          return {
            'title': name,
            'subtitle': '今日进度',
            'value': currentValue,
            'unit': unitType,
            'activities': 1,
            'totalProgress': 10,
            'completedProgress': (percentage / 10).clamp(0, 10).toInt(),
          };
        case 'milestoneCard':
          return {
            'imageUrl': null,
            'title': name,
            'date': formatDate(DateTime.now()),
            'daysCount': percentage,
            'value': currentValue.toStringAsFixed(1),
            'unit': unitType,
            'suffix': '/ $targetValue',
          };
        case 'iconCircularProgressCard':
          return {
            'progress': progress,
            'icon': 0xe25b, // Icons.track_changes codePoint
            'title': name,
            'subtitle': '已完 $currentValue / $targetValue $unitType',
            'showNotification': false,
          };
        case 'halfGaugeCard':
          return {
            'title': name,
            'totalBudget': targetValue,
            'remaining': (targetValue - currentValue).clamp(0, double.infinity),
            'currency': unitType,
          };
        case 'monthlyProgressDotsCard':
          return {
            'month': '${DateTime.now().month}月',
            'currentDay': DateTime.now().day,
            'totalDays': daysInMonth(DateTime.now()),
            'percentage': percentage,
          };
        default:
          return null;
      }
    } catch (e) {
      debugPrint('[GoalSelectorWidget] 获取数据失败: $e');
      return null;
    }
  }
}
