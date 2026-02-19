/// 活动插件 - 标签图表组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/core/plugin_manager.dart';
import '../activity_plugin.dart';
import 'data.dart';
import 'utils.dart';
import 'providers.dart';

/// 注册标签七天活动统计图表小组件
void registerTagWeeklyChartWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_tag_weekly_chart',
      pluginId: 'activity',
      name: '标签七天统计',
      description: '展示指定标签近七天的活动时长统计，支持多种图表样式',
      icon: Icons.tag,
      color: Colors.pink,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize(), const CustomSize(width: -1, height: -1)],
      category: 'home_categoryRecord'.tr,
      selectorId: 'activity.tag',
      commonWidgetsProvider: provideTagWeeklyChartWidgets,
      builder: (context, config) {
        // 使用专用的 StatefulWidget 处理标签周统计小组件
        return _TagWeeklyChartWidget(config: config);
      },
    ),
  );
}

/// 标签周统计小组件专用 StatefulWidget
class _TagWeeklyChartWidget extends StatefulWidget {
  final Map<String, dynamic> config;

  const _TagWeeklyChartWidget({required this.config});

  @override
  State<_TagWeeklyChartWidget> createState() => _TagWeeklyChartWidgetState();
}

class _TagWeeklyChartWidgetState extends State<_TagWeeklyChartWidget> {
  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const [
        'activity_added',
        'activity_updated',
        'activity_deleted',
        'activity_cache_updated',
      ],
      onEvent: () => setState(() {}),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // 解析选择器配置
    final selectorConfig =
        widget.config['selectorWidgetConfig'] as Map<String, dynamic>?;
    if (selectorConfig == null) {
      return HomeWidget.buildErrorWidget(context, '配置错误：缺少 selectorWidgetConfig');
    }

    final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
    final commonWidgetProps = selectorConfig['commonWidgetProps'] as Map<String, dynamic>?;
    final selectorData = selectorConfig['data'] as List<dynamic>?;

    if (commonWidgetId == null) {
      return HomeWidget.buildErrorWidget(context, '配置错误：缺少 commonWidgetId');
    }

    // 查找对应的 CommonWidgetId 枚举
    final widgetIdEnum = CommonWidgetId.values.asNameMap()[commonWidgetId];
    if (widgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(context, '未知的公共小组件类型: $commonWidgetId');
    }

    // 获取元数据以确定默认尺寸
    final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);
    final size = widget.config['widgetSize'] as HomeWidgetSize? ?? metadata.defaultSize;

    // 获取标签周统计数据（每次重建时获取最新数据）
    final latestProps = _getTagWeeklyWidgetDataSync(
      commonWidgetId,
      commonWidgetProps,
      selectorData,
    );

    if (latestProps == null) {
      return HomeWidget.buildErrorWidget(context, '无法加载小组件数据');
    }

    return CommonWidgetBuilder.build(
      context,
      widgetIdEnum,
      latestProps,
      size,
      inline: true,
    );
  }

  /// 同步获取标签周统计数据（每次重建时调用）
  Map<String, dynamic>? _getTagWeeklyWidgetDataSync(
    String commonWidgetId,
    Map<String, dynamic>? commonWidgetProps,
    List<dynamic>? selectorData,
  ) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return null;

      // 优先从 commonWidgetProps 获取标签
      String? tag;
      if (commonWidgetProps != null) {
        tag = commonWidgetProps['tag'] as String?;
      }

      // 如果 commonWidgetProps 中没有标签，从 selectorData 获取
      if (tag == null) {
        if (selectorData == null || selectorData.isEmpty) return null;
        final firstItem = selectorData[0] as Map<String, dynamic>?;
        tag = firstItem?['tag'] as String?;
      }

      if (tag == null) return null;

      return _getTagWeeklyChartDataSync(
        commonWidgetId,
        tag,
        plugin,
      );
    } catch (e) {
      debugPrint('[TagWeeklyChartWidget] 获取数据失败: $e');
      return null;
    }
  }
}

/// 同步获取标签周图表数据
Map<String, dynamic>? _getTagWeeklyChartDataSync(
  String commonWidgetId,
  String tag,
  ActivityPlugin plugin,
) {
  final now = DateTime.now();
  final weekDayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  // 获取7天数据
  final sevenDaysData = <DayActivityData>[];
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final allActivities = plugin.getActivitiesForDateSync(date);
    final filteredActivities =
        allActivities.where((a) => a.tags.contains(tag)).toList();
    final totalMinutes = filteredActivities.fold<int>(
      0,
      (sum, a) => sum + a.durationInMinutes,
    );
    sevenDaysData.add(
      DayActivityData(
        date: date,
        totalMinutes: totalMinutes,
        activityCount: filteredActivities.length,
      ),
    );
  }

  final totalMinutes = sevenDaysData.fold<int>(
    0,
    (sum, d) => sum + d.totalMinutes,
  );
  final avgMinutes = totalMinutes / 7;
  final maxMinutes = sevenDaysData
      .map((d) => d.totalMinutes)
      .reduce((a, b) => a > b ? a : b);
  final weeklyDurations =
      sevenDaysData.map((d) => d.totalMinutes.toDouble()).toList();
  final weeklyNormalized =
      maxMinutes > 0
          ? weeklyDurations.map((d) => d / maxMinutes).toList()
          : List.filled(7, 0.0);

  final todayMinutes = sevenDaysData.last.totalMinutes.toDouble();
  final yesterdayMinutes =
      sevenDaysData[sevenDaysData.length - 2].totalMinutes.toDouble();
  final changePercent =
      yesterdayMinutes > 0
          ? ((todayMinutes - yesterdayMinutes) / yesterdayMinutes * 100).floor()
          : 0;

  final startDate = DateFormat('MM月dd日').format(sevenDaysData.first.date);
  final endDate = DateFormat('MM月dd日').format(sevenDaysData.last.date);

  // 确保 weeklyNormalized 有7个元素
  final normalizedData =
      weeklyNormalized.isNotEmpty ? weeklyNormalized : List.filled(7, 0.0);
  final chartDataForCards =
      normalizedData.isNotEmpty
          ? normalizedData
          : [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];

  // 常量
  const primaryColorValue = 0xFFE91E63; // 默认粉色
  final tagColor = getColorFromTag(tag);

  switch (commonWidgetId) {
    case 'miniTrendCard':
      return {
        'title': '日均活动时长',
        'tag': tag,
        'tagColor': tagColor.value,
        'primaryColor': primaryColorValue,
        'currentValue': avgMinutes,
        'unit': '分钟',
        'trendData': chartDataForCards,
        'weekDayLabels': weekDayLabels,
      };
    case 'trendValueCard':
      return {
        'title': '$tag 活动趋势',
        'tag': tag,
        'primaryColor': primaryColorValue.toString(),
        'value': avgMinutes,
        'unit': '分钟/天',
        'changePercent': changePercent,
        'chartData': chartDataForCards.map((v) => v * 100).toList(),
        'dateRange': '$startDate - $endDate',
      };
    case 'earningsTrendCard':
      return {
        'title': '$tag 总时长',
        'tag': tag,
        'primaryColor': primaryColorValue,
        'value': totalMinutes / 60,
        'currency': '小时',
        'changePercent': changePercent,
        'chartData':
            weeklyDurations.isNotEmpty
                ? weeklyDurations.map((d) {
                  return maxMinutes > 0
                      ? (d / maxMinutes * 100).clamp(0.0, 100.0)
                      : 0.0;
                }).toList()
                : List.filled(7, 0.0),
      };
    case 'spendingTrendChart':
      return {
        'title': '$tag 对比趋势',
        'tag': tag,
        'primaryColor': primaryColorValue,
        'dateRange': '$startDate - $endDate',
        'currentMonthData':
            weeklyDurations.isNotEmpty ? weeklyDurations : List.filled(7, 0.0),
        'previousMonthData': List.generate(7, (index) {
          return index > 0 ? weeklyDurations[index - 1] * 0.8 : 0.0;
        }),
        'maxValue': maxMinutes,
      };
    default:
      return null;
  }
}
