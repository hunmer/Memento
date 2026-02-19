/// 习惯追踪插件 - 活动统计小组件注册（事件携带数据模式）
///
/// 支持日期范围（本日/本周/本月/本年）和显示数量配置
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'utils.dart' show pluginColor;
import 'providers.dart' show provideActivityStatsWidgets;
import 'utils.dart';
import '../controllers/habit_controller.dart';
import 'package:Memento/core/plugin_manager.dart';

/// 导航到习惯插件
void _navigateToHabits(BuildContext context, SelectorResult result) {
  final plugin = PluginManager.instance.getPlugin('habits');
  if (plugin == null) return;

  // 记录插件打开历史
  PluginManager.instance.recordPluginOpen(plugin);

  // 跳转到习惯插件
  NavigationHelper.openContainerWithHero(
    context,
    (_) => plugin.buildMainView(context),
    heroTag: 'habits_activity_stats',
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// 注册活动统计小组件
void registerActivityStatsWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'habits_activity_stats',
      pluginId: 'habits',
      name: 'habits_activityStatsName'.tr,
      description: 'habits_activityStatsDescription'.tr,
      icon: Icons.analytics,
      color: pluginColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,

      selectorId: 'habits.activity_stats.config',
      commonWidgetsProvider: provideActivityStatsWidgets,
      navigationHandler: _navigateToHabits,

      builder: (context, config) {
        // 使用专用的 StatefulWidget 来持有缓存的事件数据
        return _ActivityStatsStatefulWidget(
          config: config,
          widgetDefinition: registry.getWidget('habits_activity_stats')!,
        );
      },
    ),
  );
}

/// 内部 StatefulWidget 用于持有缓存的事件数据
class _ActivityStatsStatefulWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final HomeWidget widgetDefinition;

  const _ActivityStatsStatefulWidget({
    required this.config,
    required this.widgetDefinition,
  });

  @override
  State<_ActivityStatsStatefulWidget> createState() =>
      _ActivityStatsStatefulWidgetState();
}

class _ActivityStatsStatefulWidgetState
    extends State<_ActivityStatsStatefulWidget> {
  /// 缓存的公共小组件数据（性能优化：直接使用事件携带的数据）
  Map<String, Map<String, dynamic>>? _cachedCommonWidgetsData;

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const [
        'habits_cache_updated', // 监听习惯缓存更新事件（携带数据）
        'habit_completion_record_saved', // 完成记录保存事件
        'habit_timer_stopped', // 计时器停止事件
      ],
      onEventWithData: (args) {
        // 处理缓存更新事件（携带数据）
        if (args is HabitCacheUpdatedEventArgs) {
          debugPrint(
            '[ActivityStatsWidget] Received habits_cache_updated: ${args.habits.length} habits',
          );
          setState(() {
            // 清空缓存，下次构建时重新计算
            _cachedCommonWidgetsData = null;
          });
        }
        // 处理其他事件（不携带数据）
        else {
          debugPrint('[ActivityStatsWidget] Received event: ${args.eventName}');
          setState(() {
            _cachedCommonWidgetsData = null;
          });
        }
      },
      child: _buildActivityStatsContent(
        context,
        widget.config,
        widget.widgetDefinition,
      ),
    );
  }

  /// 构建活动统计内容
  Widget _buildActivityStatsContent(
    BuildContext context,
    Map<String, dynamic> config,
    HomeWidget widgetDefinition,
  ) {
    // 解析选择器配置
    final selectorConfig =
        config['selectorWidgetConfig'] as Map<String, dynamic>?;

    if (selectorConfig == null) {
      return _buildUnconfiguredWidget(context);
    }

    final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
    if (commonWidgetId == null) {
      return _buildUnconfiguredWidget(context);
    }

    // 查找对应的 CommonWidgetId 枚举
    final widgetIdEnum = CommonWidgetId.values.asNameMap()[commonWidgetId];
    if (widgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(
        context,
        '未知的公共小组件类型: $commonWidgetId',
      );
    }

    // 获取小组件尺寸
    final size =
        config['widgetSize'] as HomeWidgetSize? ?? widgetDefinition.defaultSize;

    // 使用 FutureBuilder 异步获取数据
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: _getActivityStatsDataSync(selectorConfig),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return HomeWidget.buildErrorWidget(
            context,
            '加载失败: ${snapshot.error}',
          );
        }

        final commonWidgetsData = snapshot.data ?? {};

        // 缓存数据以供下次使用
        _cachedCommonWidgetsData ??= commonWidgetsData;

        final props = commonWidgetsData[commonWidgetId];
        if (props == null) {
          return HomeWidget.buildErrorWidget(context, '无法获取统计数据');
        }

        // 合并保存的配置和实时数据
        final savedProps =
            selectorConfig['commonWidgetProps'] as Map<String, dynamic>? ?? {};
        final finalProps = {...savedProps, ...props};

        return CommonWidgetBuilder.build(
          context,
          widgetIdEnum,
          finalProps,
          size,
          inline: true,
        );
      },
    );
  }

  /// 同步获取活动统计数据（内部使用 Completer 转换异步操作）
  Future<Map<String, Map<String, dynamic>>> _getActivityStatsDataSync(
    Map<String, dynamic> selectorConfig,
  ) async {
    // 如果有缓存，直接返回
    if (_cachedCommonWidgetsData != null) {
      return _cachedCommonWidgetsData!;
    }

    try {
      final plugin = PluginManager.instance.getPlugin('habits');
      if (plugin == null) {
        debugPrint('[ActivityStatsWidget] Plugin not found');
        return {};
      }

      final dateRangeStr = selectorConfig['dateRange'] as String? ?? 'week';
      final maxCount = (selectorConfig['maxCount'] as int?)?.clamp(1, 10) ?? 5;

      // 直接调用异步方法获取数据
      final commonWidgetsData = await provideActivityStatsWidgets({
        'dateRange': dateRangeStr,
        'maxCount': maxCount,
      });

      return commonWidgetsData;
    } catch (e) {
      debugPrint('[ActivityStatsWidget] 获取数据失败: $e');
      return {};
    }
  }

  Widget _buildUnconfiguredWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '请配置统计小组件',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
