import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:intl/intl.dart';
import 'activity_plugin.dart';
import 'screens/activity_edit_screen.dart';
import 'models/activity_record.dart';

/// 活动插件的主页小组件注册
class ActivityHomeWidgets {
  /// 注册所有活动插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'activity_icon',
        pluginId: 'activity',
        name: 'activity_widgetName'.tr,
        description: 'activity_widgetDescription'.tr,
        icon: Icons.timeline,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.timeline,
              color: Colors.pink,
              name: 'activity_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'activity_overview',
        pluginId: 'activity',
        name: 'activity_overviewName'.tr,
        description: 'activity_overviewDescription'.tr,
        icon: Icons.access_time,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 1x1 创建活动快捷入口 - 直接跳转
    registry.register(
      HomeWidget(
        id: 'activity_create_shortcut',
        pluginId: 'activity',
        name: 'activity_createActivityShortcut'.tr,
        description: 'activity_createActivityShortcutDesc'.tr,
        icon: Icons.add_circle,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => const ActivityCreateShortcutWidget(),
      ),
    );

    // 1x2 上次活动小组件 - 显示距离上次活动的时间
    registry.register(
      HomeWidget(
        id: 'activity_last_activity',
        pluginId: 'activity',
        name: '上次活动',
        description: '显示距离上次活动经过的时间和上次活动的时间',
        icon: Icons.history,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.medium, // 2x1
        supportedSizes: [HomeWidgetSize.medium],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => const ActivityLastActivityWidget(),
      ),
    );
    // 活动小组件 - 支持公共小组件样式（不需要选择数据）
    registry.register(
      HomeWidget(
        id: 'activity_common_widgets',
        pluginId: 'activity',
        name: 'activity_commonWidgetsName'.tr,
        description: 'activity_commonWidgetsDesc'.tr,
        icon: Icons.dashboard,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large, HomeWidgetSize.custom],
        category: 'home_categoryRecord'.tr,
        commonWidgetsProvider: _provideCommonWidgets,
        builder: (context, config) {
          return StatefulBuilder(
            builder: (context, setState) {
              return EventListenerContainer(
                events: const [
                  'activity_added',
                  'activity_updated',
                  'activity_deleted',
                ],
                onEvent: () => setState(() {}),
                child: _buildCommonWidgetsWidget(context, config),
              );
            },
          );
        },
      ),
    );

    // 七天活动统计小组件 - 支持多种图表展示
    registry.register(
      HomeWidget(
        id: 'activity_weekly_chart',
        pluginId: 'activity',
        name: '七天活动统计',
        description: '展示近七天的活动时长统计，支持多种图表样式',
        icon: Icons.bar_chart,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large, HomeWidgetSize.custom],
        category: 'home_categoryRecord'.tr,
        commonWidgetsProvider: _provideWeeklyChartWidgets,
        builder: (context, config) {
          return StatefulBuilder(
            builder: (context, setState) {
              return EventListenerContainer(
                events: const [
                  'activity_added',
                  'activity_updated',
                  'activity_deleted',
                ],
                onEvent: () => setState(() {}),
                child: _buildCommonWidgetsWidget(context, config),
              );
            },
          );
        },
      ),
    );

    // 标签七天活动统计小组件 - 支持多种图表展示
    registry.register(
      HomeWidget(
        id: 'activity_tag_weekly_chart',
        pluginId: 'activity',
        name: '标签七天统计',
        description: '展示指定标签近七天的活动时长统计，支持多种图表样式',
        icon: Icons.tag,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large, HomeWidgetSize.custom],
        category: 'home_categoryRecord'.tr,
        selectorId: 'activity.tag',
        dataSelector: _extractTagWeeklyWidgetData,
        dataRenderer: _renderTagWeeklyChartData,
        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('activity_tag_weekly_chart')!,
            config: config,
          );
        },
      ),
    );
  }

  /// 从选择器数据中提取标签统计数据
  static Map<String, dynamic> _extractTagWeeklyWidgetData(
    List<dynamic> dataArray,
  ) {
    if (dataArray.isEmpty || dataArray[0] == null) {
      return {'tag': null};
    }
    final tagData = dataArray[0] as Map<String, dynamic>;
    return {'tag': tagData['tag'] as String?};
  }

  /// 渲染标签周统计图表数据
  static Widget _renderTagWeeklyChartData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final data =
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : {};
    final tag = data['tag'] as String?;

    if (tag == null) {
      return _buildNoTagSelectedWidget(context);
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'activity_added',
            'activity_updated',
            'activity_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildTagWeeklyChartWidget(context, tag),
        );
      },
    );
  }

  /// 构建未选择标签时的提示组件
  static Widget _buildNoTagSelectedWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tag, size: 48, color: Colors.pink.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            '请选择标签',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '长按卡片选择标签以查看统计',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签周统计图表组件
  static Widget _buildTagWeeklyChartWidget(BuildContext context, String tag) {
    final plugin =
        PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
    if (plugin == null) {
      return HomeWidget.buildErrorWidget(context, '插件未加载');
    }

    // 获取过去7天的数据并按标签过滤
    final now = DateTime.now();
    final tagColor = _getColorFromTagForWidgets(tag);
    final weekDayLabels = ['一', '二', '三', '四', '五', '六', '日'];

    // 获取7天数据
    final sevenDaysData = <_DayActivityData>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final allActivities = plugin.getActivitiesForDateSync(date);
      // 按标签过滤
      final filteredActivities =
          allActivities.where((a) => a.tags.contains(tag)).toList();
      final totalMinutes = filteredActivities.fold<int>(
        0,
        (sum, a) => sum + a.durationInMinutes,
      );
      sevenDaysData.add(
        _DayActivityData(
          date: date,
          totalMinutes: totalMinutes,
          activityCount: filteredActivities.length,
        ),
      );
    }

    // 计算统计数据
    final totalWeekMinutes = sevenDaysData.fold<int>(
      0,
      (sum, d) => sum + d.totalMinutes,
    );
    final avgMinutes = totalWeekMinutes / 7;
    final maxMinutes = sevenDaysData
        .map((d) => d.totalMinutes)
        .reduce((a, b) => a > b ? a : b);

    // 获取今天和昨天的数据用于对比
    final todayMinutes = sevenDaysData.last.totalMinutes.toDouble();
    final yesterdayMinutes =
        sevenDaysData[sevenDaysData.length - 2].totalMinutes.toDouble();
    final changePercent =
        yesterdayMinutes > 0
            ? ((todayMinutes - yesterdayMinutes) / yesterdayMinutes * 100)
                .floor()
            : 0;

    // 格式化日期范围
    final startDate = DateFormat('MM月dd日').format(sevenDaysData.first.date);
    final endDate = DateFormat('MM月dd日').format(sevenDaysData.last.date);

    // 准备图表数据
    final weeklyDurations =
        sevenDaysData.map((d) => d.totalMinutes.toDouble()).toList();
    final weeklyNormalized =
        maxMinutes > 0
            ? weeklyDurations.map((d) => d / maxMinutes).toList()
            : List.filled(7, 0.0);

    final weekDayLabelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      child: Column(
        children: [
          // MiniTrendCard - 迷你趋势图
          _buildMiniTrendCard(
            context,
            tag,
            tagColor,
            avgMinutes,
            weekDayLabels,
            weeklyNormalized,
          ),
          const SizedBox(height: 12),
          // TrendValueCard - 趋势数值卡片
          _buildTrendValueCard(
            context,
            tag,
            tagColor,
            avgMinutes,
            changePercent,
            weeklyNormalized,
            startDate,
            endDate,
          ),
          const SizedBox(height: 12),
          // WeeklyBarsCard - 周柱状图
          _buildWeeklyBarsCard(
            context,
            tag,
            tagColor,
            avgMinutes,
            weeklyNormalized,
          ),
          const SizedBox(height: 12),
          // EarningsTrendCard - 收益趋势样式卡片
          _buildEarningsTrendCard(
            context,
            tag,
            totalWeekMinutes,
            changePercent,
            weeklyDurations,
            maxMinutes,
          ),
          const SizedBox(height: 12),
          // SpendingTrendChart - 支出趋势对比样式卡片
          _buildSpendingTrendChart(
            context,
            tag,
            startDate,
            endDate,
            weeklyDurations,
            maxMinutes,
          ),
        ],
      ),
    );
  }

  /// 构建 MiniTrendCard 组件
  static Widget _buildMiniTrendCard(
    BuildContext context,
    String tag,
    Color tagColor,
    double avgMinutes,
    List<String> weekDayLabels,
    List<double> dailyValues,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.label, size: 28, color: tagColor),
              const SizedBox(width: 8),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 52,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          avgMinutes.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color,
                            height: 1.0,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '分钟',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '日均活动时长',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              // 迷你趋势图
              SizedBox(
                width: 140,
                child: Column(
                  children: [
                    SizedBox(
                      height: 60,
                      child: CustomPaint(
                        size: const Size(140, 60),
                        painter: _MiniTrendPainter(
                          data: dailyValues,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          weekDayLabels.map((day) {
                            return Text(
                              day,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9CA3AF),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建 TrendValueCard 组件
  static Widget _buildTrendValueCard(
    BuildContext context,
    String tag,
    Color tagColor,
    double avgMinutes,
    int changePercent,
    List<double> dailyValues,
    String startDate,
    String endDate,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.error;

    final chartData = dailyValues.map((v) => v * 100).toList();
    final trendUp = changePercent >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '$tag 活动趋势',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      trendUp
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                      color: trendUp ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${changePercent.abs()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avgMinutes.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.0,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Text(
                    '分钟/天',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              Container(
                width: 140,
                height: 80,
                padding: const EdgeInsets.only(top: 8),
                child: CustomPaint(
                  size: const Size(140, 80),
                  painter: _SmoothTrendPainter(
                    data: chartData,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startDate,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              Text(
                endDate,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建 WeeklyBarsCard 组件
  static Widget _buildWeeklyBarsCard(
    BuildContext context,
    String tag,
    Color tagColor,
    double avgMinutes,
    List<double> dailyValues,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.error;
    final weekDayLabels = ['一', '二', '三', '四', '五', '六', '日'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                '$tag 周统计',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 柱状图
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final value = dailyValues[index];
              return Column(
                children: [
                  // 柱子
                  Container(
                    width: 24,
                    height: 100 * value.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weekDayLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '日均: ${avgMinutes.toStringAsFixed(1)} 分钟',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建 EarningsTrendCard 样式组件
  static Widget _buildEarningsTrendCard(
    BuildContext context,
    String tag,
    int totalMinutes,
    int changePercent,
    List<double> weeklyDurations,
    int maxMinutes,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.error;
    final trendUp = changePercent >= 0;

    // 转换数据为图表格式
    final chartData =
        weeklyDurations.map((d) {
          return maxMinutes > 0
              ? (d / maxMinutes * 100).clamp(0.0, 100.0)
              : 0.0;
        }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.cardColor, theme.cardColor.withOpacity(0.95)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '$tag 总时长',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (trendUp ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: trendUp ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    Text(
                      '${changePercent.abs()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${(totalMinutes / 60).toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '小时',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 折线图
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width - 120, 100),
              painter: _EarningsLinePainter(
                data: chartData,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 SpendingTrendChart 样式组件
  static Widget _buildSpendingTrendChart(
    BuildContext context,
    String tag,
    String startDate,
    String endDate,
    List<double> weeklyDurations,
    int maxMinutes,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.error;

    // 转换数据为对比格式
    final currentMonthData =
        weeklyDurations.map((d) {
          return maxMinutes > 0 ? d : 0.0;
        }).toList();
    final previousMonthData = List.generate(7, (index) {
      // 模拟上周数据（基于当前数据的80%）
      return index > 0 ? currentMonthData[index - 1] * 0.8 : 0.0;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                '$tag 对比趋势',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本周',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
              Text(
                '上周',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 趋势对比图
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width - 120, 120),
              painter: _ComparisonTrendPainter(
                currentData: currentMonthData,
                previousData: previousMonthData,
                currentColor: primaryColor,
                previousColor:
                    theme.textTheme.bodySmall?.color?.withOpacity(0.4) ??
                    Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startDate,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              Text(
                endDate,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return [];

      final activityCount = plugin.getTodayActivityCountSync();
      final activityDuration = plugin.getTodayActivityDurationSync();
      final remainingTime = plugin.getTodayRemainingTime();

      return [
        StatItemData(
          id: 'today_activities',
          label: 'activity_todayActivities'.tr,
          value: '$activityCount',
          highlight: activityCount > 0,
          color: Colors.pink,
        ),
        StatItemData(
          id: 'today_duration',
          label: 'activity_todayDuration'.tr,
          value: '${(activityDuration / 60).toStringAsFixed(1)}H',
          highlight: false,
        ),
        StatItemData(
          id: 'remaining_time',
          label: 'activity_remainingTime'.tr,
          value: '${(remainingTime / 60).toStringAsFixed(1)}H',
          highlight: remainingTime < 120,
          color: Colors.red,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
      return StatefulBuilder(
        builder: (context, setState) {
          return EventListenerContainer(
            events: const [
              'activity_added',
              'activity_updated',
              'activity_deleted',
            ],
            onEvent: () => setState(() {}),
            child: _buildOverviewContent(context, widgetConfig),
          );
        },
      );
    } catch (e) {
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
  }

  /// 构建概览小组件内容（获取最新数据）
  static Widget _buildOverviewContent(
    BuildContext context,
    PluginWidgetConfig widgetConfig,
  ) {
    // 获取可用的统计项数据（每次重建时重新获取）
    final availableItems = _getAvailableStats(context);

    // 使用通用小组件
    return GenericPluginWidget(
      pluginId: 'activity',
      pluginName: 'activity_name'.tr,
      pluginIcon: Icons.access_time,
      pluginDefaultColor: Colors.pink,
      availableItems: availableItems,
      config: widgetConfig,
    );
  }

  /// 构建公共小组件显示
  static Widget _buildCommonWidgetsWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final selectorConfig =
        config['selectorWidgetConfig'] as Map<String, dynamic>?;
    if (selectorConfig == null) {
      return HomeWidget.buildErrorWidget(
        context,
        '配置错误：缺少 selectorWidgetConfig',
      );
    }

    final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
    final commonWidgetProps =
        selectorConfig['commonWidgetProps'] as Map<String, dynamic>?;

    if (commonWidgetId == null || commonWidgetProps == null) {
      return HomeWidget.buildErrorWidget(
        context,
        '配置错误：缺少 commonWidgetId 或 commonWidgetProps',
      );
    }

    // 查找对应的 CommonWidgetId 枚举
    final widgetIdEnum = CommonWidgetId.values.asNameMap()[commonWidgetId];
    if (widgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(
        context,
        '未知的公共小组件类型: $commonWidgetId',
      );
    }

    // 获取元数据以确定默认尺寸
    final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);

    return CommonWidgetBuilder.build(
      context,
      widgetIdEnum,
      commonWidgetProps,
      metadata.defaultSize,
    );
  }

  /// 构建动态热力图小组件（支持事件触发时重新获取数据）
  static Widget _buildDynamicHeatmapWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    // 解析选择器配置
    final selectorConfig =
        config['selectorWidgetConfig'] as Map<String, dynamic>?;
    if (selectorConfig == null) {
      return HomeWidget.buildErrorWidget(
        context,
        '配置错误：缺少 selectorWidgetConfig',
      );
    }

    // 检查是否使用了公共小组件
    final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
    if (commonWidgetId == null || commonWidgetId != 'activityHeatmapCard') {
      return HomeWidget.buildErrorWidget(context, '配置错误：未配置活动热力图组件');
    }

    // 获取选择器数据
    final selectedData =
        selectorConfig['selectedData'] as Map<String, dynamic>?;
    if (selectedData == null) {
      return HomeWidget.buildErrorWidget(context, '无法获取选择的数据');
    }

    // 获取小组件定义
    final registry = HomeWidgetRegistry();
    final widgetDef = registry.getWidget('activity_heatmap');
    if (widgetDef == null || widgetDef.commonWidgetsProvider == null) {
      return HomeWidget.buildErrorWidget(context, '小组件定义错误');
    }

    // 从 selectedData 中提取时间粒度配置
    Map<String, dynamic> data = {};
    if (selectedData.containsKey('data')) {
      final dataArray = selectedData['data'];
      if (dataArray is List && dataArray.isNotEmpty) {
        final rawData = dataArray[0];
        if (rawData is Map<String, dynamic>) {
          data = rawData;
        } else if (rawData != null && rawData is Map) {
          data = Map<String, dynamic>.from(rawData);
        }
      }
    }

    // 动态调用 commonWidgetsProvider 获取最新数据
    final availableWidgets = widgetDef.commonWidgetsProvider!(data);
    final latestProps = availableWidgets['activityHeatmapCard'];

    if (latestProps == null) {
      return HomeWidget.buildErrorWidget(context, '无法获取最新数据');
    }

    // 使用公共组件构建器渲染
    final commonWidgetIdEnum = CommonWidgetId.activityHeatmapCard;
    final metadata = CommonWidgetsRegistry.getMetadata(commonWidgetIdEnum);

    return CommonWidgetBuilder.build(
      context,
      commonWidgetIdEnum,
      latestProps,
      metadata.defaultSize,
    );
  }

  /// 导航处理函数
  static void _navigateToActivityMain(
    BuildContext context,
    SelectorResult result,
  ) {
    try {
      Navigator.push(
        context,
        NavigationHelper.createRoute(const ActivityMainView()),
      );
    } catch (e) {
      toastService.showToast('activity_operationFailed'.tr);
      debugPrint('[ActivityHomeWidgets] 导航失败: $e');
    }
  }

  /// 构建动态今日活动统计小组件（支持事件触发时重新获取数据）
  static Widget _buildDynamicTodayPieChartWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    // 获取小组件定义
    final registry = HomeWidgetRegistry();
    final widgetDef = registry.getWidget('activity_today_pie_chart');
    if (widgetDef == null || widgetDef.commonWidgetsProvider == null) {
      return HomeWidget.buildErrorWidget(context, '小组件定义错误');
    }

    // 动态调用 commonWidgetsProvider 获取最新数据
    final availableWidgets = widgetDef.commonWidgetsProvider!({});
    final latestProps = availableWidgets['activityTodayPieChartCard'];

    if (latestProps == null) {
      return HomeWidget.buildErrorWidget(context, '无法获取最新数据');
    }

    // 使用公共组件构建器渲染
    final commonWidgetIdEnum = CommonWidgetId.activityTodayPieChartCard;
    final metadata = CommonWidgetsRegistry.getMetadata(commonWidgetIdEnum);

    return CommonWidgetBuilder.build(
      context,
      commonWidgetIdEnum,
      latestProps,
      metadata.defaultSize,
    );
  }

  /// 公共小组件提供者函数（同步版本）
  static Map<String, Map<String, dynamic>> _provideCommonWidgets(
    Map<String, dynamic> data,
  ) {
    // 获取今日活动数据
    final plugin =
        PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
    if (plugin == null) return {};

    final now = DateTime.now();

    // 同步获取今日活动（使用缓存）
    final todayActivities = plugin.getTodayActivitiesSync();

    // 同步获取昨日活动（使用缓存）
    final yesterdayActivities = plugin.getYesterdayActivitiesSync();

    // 计算今日统计数据
    final todayActivityCount = todayActivities.length;
    final todayDurationMinutes = todayActivities.fold<int>(
      0,
      (sum, a) => sum + a.durationInMinutes,
    );
    final remainingMinutes = plugin.getTodayRemainingTime();

    // 按标签统计
    final tagStats = <String, int>{};
    for (final activity in todayActivities) {
      for (final tag in activity.tags) {
        tagStats[tag] = (tagStats[tag] ?? 0) + activity.durationInMinutes;
      }
    }

    // 按标签分类活动
    final activitiesByTag = <String, List<ActivityRecord>>{};
    for (final activity in todayActivities) {
      for (final tag in activity.tags) {
        activitiesByTag.putIfAbsent(tag, () => []).add(activity);
      }
    }

    // 计算今日活动中的最长时长
    final maxDurationMinutes =
        todayActivities.isEmpty
            ? 60.0
            : todayActivities
                .map((a) => a.durationInMinutes.toDouble())
                .reduce((a, b) => a > b ? a : b);

    return {
      // 分段进度卡片：按标签统计时长
      'segmentedProgressCard': {
        'title': '今日活动',
        'subtitle': '$todayActivityCount个活动',
        'currentValue': todayDurationMinutes.toDouble(),
        'targetValue': (12 * 60).toDouble(), // 12小时目标
        'unit': '分钟',
        'segments':
            tagStats.entries
                .map(
                  (e) => {
                    'label': e.key,
                    'value': e.value.toDouble(),
                    'display': _formatDurationForDisplay(e.value),
                    'color': _getColorFromTagForWidgets(e.key).value,
                  },
                )
                .toList(),
      },

      // 任务进度卡片：显示今日活动进度
      'taskProgressCard': {
        'title': '今日活动',
        'subtitle': '$todayActivityCount个记录',
        'completedTasks': now.hour,
        'totalTasks': 24,
        'progressLabel': '今日时间',
        'pendingLabel': '活动列表',
        'maxPendingTasks': null,
        'pendingTasks':
            todayActivities
                .map(
                  (a) =>
                      '${a.title.isEmpty ? '未命名活动' : a.title} · ${_formatTimeRangeStatic(a.startTime, a.endTime)}',
                )
                .toList(),
      },

      // 营养进度卡片：左侧今日剩余时间，右侧活动列表
      'nutritionProgressCard': {
        'leftData': {
          'current': (24 * 60 - remainingMinutes).toDouble(),
          'total': (24 * 60).toDouble(),
          'unit': '分钟',
        },
        'leftConfig': {
          'icon': '⏰',
          'label': '今日剩余',
          'subtext': '${(remainingMinutes / 60).toStringAsFixed(1)}小时',
        },
        'rightItems':
            todayActivities
                .take(4)
                .map(
                  (a) => {
                    'icon': '📝',
                    'name': a.title.isEmpty ? '未命名活动' : a.title,
                    'current': a.durationInMinutes.toDouble(),
                    'total': maxDurationMinutes, // 使用今日最长活动时长作为总值
                    'color': Colors.blue.value,
                    'subtitle':
                        '${_formatTimeStatic(a.startTime)} - ${_formatTimeStatic(a.endTime)}',
                  },
                )
                .toList(),
      },

      // 观看进度卡片：显示活动列表
      'watchProgressCard': {
        'userName': '今日活动',
        'lastWatched': '',
        'enableHeader': false,
        'progressLabel': '已用时间',
        'currentCount': now.hour,
        'totalCount': 24,
        'items':
            todayActivities
                .map(
                  (a) => {
                    'title': a.title.isEmpty ? '未命名活动' : a.title,
                    'subtitle':
                        '${_formatTimeStatic(a.startTime)} - ${_formatTimeStatic(a.endTime)}',
                    'thumbnailUrl': null,
                  },
                )
                .toList(),
      },

      // 每日日程卡片：今日活动和昨日活动
      'dailyScheduleCard': {
        'todayDate': '${now.month}月${now.day}日',
        'todayEvents':
            todayActivities
                .map((a) => _convertActivityToEventData(a))
                .toList(),
        'tomorrowEvents':
            yesterdayActivities
                .map((a) => _convertActivityToEventData(a))
                .toList(),
      },

      // 支出分类环形图：按标签统计活动时长
      'expenseDonutChart': {
        'badgeLabel': '活动',
        'timePeriod': '${now.month}月${now.day}日',
        'totalAmount': todayDurationMinutes.toDouble() / 60,
        'totalUnit': '小时',
        'categories':
            tagStats.entries
                .map(
                  (e) => {
                    'label': e.key,
                    'percentage': todayDurationMinutes > 0
                        ? (e.value / todayDurationMinutes * 100)
                        : 0.0,
                    'color': _getColorFromTagForWidgets(e.key).value,
                    'subtitle': _formatActivitiesTimeRange(activitiesByTag[e.key] ?? []),
                  },
                )
                .toList(),
      },

      // 任务列表卡片
      'taskListCard': {
        'title': '今日活动',
        'count': todayActivityCount,
        'countLabel': '个活动',
        'items':
            todayActivities
                .map((a) => a.title.isEmpty ? '未命名活动' : a.title)
                .toList(),
        'moreCount': 0,
      },

      // 彩色标签任务列表卡片
      'colorTagTaskCard': {
        'taskCount': todayActivityCount,
        'label': '今日活动',
        'tasks':
            todayActivities.map((a) {
              final primaryTag = a.tags.isNotEmpty ? a.tags.first : '默认';
              final timeRange = _formatTimeRangeStatic(a.startTime, a.endTime);
              return {
                'title': '($timeRange)',
                'color': _getColorFromTagForWidgets(primaryTag).value,
                'tag': a.title.isEmpty ? '未命名活动' : a.title,
              };
            }).toList(),
        'moreCount': 0,
      },

      // 即将到来的任务小组件：显示接下来的活动
      'upcomingTasksWidget': {
        'title': '活动',
        'taskCount': todayActivityCount,
        'moreCount': 0,
        'tasks':
            todayActivities
                .take(4)
                .map(
                  (a) => {
                    'title': a.title.isEmpty ? '未命名活动' : a.title,
                    'color': a.tags.isNotEmpty
                        ? _getColorFromTagForWidgets(a.tags.first).value
                        : Colors.pink.value,
                    'tag': _formatTimeRangeStatic(a.startTime, a.endTime),
                  },
                )
                .toList(),
      },

      // 圆角任务列表卡片
      'roundedTaskListCard': {
        'headerText': '今日活动',
        'tasks':
            todayActivities
                .map(
                  (a) => {
                    'title': a.title.isEmpty ? '未命名活动' : a.title,
                    'subtitle': _formatTimeRangeStatic(a.startTime, a.endTime),
                    'date': '${now.month}月${now.day}日',
                  },
                )
                .toList(),
      },

      // 圆角提醒事项列表
      'roundedRemindersList': {
        'title': '今日活动',
        'count': todayActivityCount,
        'items':
            todayActivities
                .map(
                  (a) => {
                    'text': a.title.isEmpty ? '未命名活动' : a.title,
                    'isCompleted': true,
                  },
                )
                .toList(),
      },

      // 现代圆角消费卡片：显示活动时长
      'modernRoundedSpendingWidget': {
        'title': '今日活动',
        'currentAmount': todayDurationMinutes.toDouble(),
        'budgetAmount': (12 * 60).toDouble(), // 12小时目标
        'unit': '分钟',
        'categories':
            tagStats.entries
                .map(
                  (e) => {
                    'name': e.key,
                    'amount': e.value.toDouble(),
                    'color': _getColorFromTagForWidgets(e.key).value,
                  },
                )
                .toList(),
        'categoryItems':
            activitiesByTag.entries
                .map(
                  (e) => {
                    'categoryName': e.key,
                    'items':
                        e.value
                            .take(5)
                            .map(
                              (a) => {
                                'title': a.title.isEmpty ? '未命名活动' : a.title,
                                'subtitle': '${a.durationInMinutes}分钟',
                              },
                            )
                            .toList(),
                  },
                )
                .toList(),
      },

      // 分类堆叠消费卡片
      'categoryStackWidget': {
        'title': '今日活动分布',
        'currentAmount': todayDurationMinutes.toDouble(),
        'targetAmount': (12 * 60).toDouble(),
        'categories':
            tagStats.entries
                .map(
                  (e) => {
                    'name': e.key,
                    'amount': e.value.toDouble(),
                    'color': _getColorFromTagForWidgets(e.key).value,
                  },
                )
                .toList(),
      },

      // 时间线日程卡片：显示昨天和今天的活动
      'timelineScheduleCard': _buildTimelineScheduleCardData(
        todayActivities,
        yesterdayActivities,
        now,
      ),

      // 活动热力图卡片
      'activityHeatmapCard': _buildHeatmapCardData(todayActivities, data),

      // 今日活动统计卡片
      'activityTodayPieChartCard': {
        'tagStats': tagStats,
        'totalDuration': todayDurationMinutes,
      },
    };
  }

  /// 构建活动热力图卡片数据
  static Map<String, dynamic> _buildHeatmapCardData(
    List<ActivityRecord> activities,
    Map<String, dynamic> selectorData,
  ) {
    // 获取时间粒度（从选择器数据或使用默认值60分钟）
    int timeGranularity = 60;
    if (selectorData.containsKey('timeGranularity')) {
      timeGranularity = selectorData['timeGranularity'] as int? ?? 60;
    }

    // 计算时间槽数据
    final timeSlots = _calculateTimeSlotDataForWidget(
      activities,
      timeGranularity,
    );

    // 计算总时长
    final totalMinutes = activities.fold<int>(
      0,
      (sum, a) => sum + a.durationInMinutes,
    );

    // 计算活跃小时数
    final activeHours = _calculateActiveHoursForWidget(activities);

    // 转换时间槽数据为 Map 格式
    final timeSlotsList =
        timeSlots
            .map(
              (slot) => {
                'hour': slot.hour,
                'minute': slot.minute,
                'durationMinutes': slot.durationMinutes,
                'tagDurations': slot.tagDurations,
              },
            )
            .toList();

    return {
      'timeGranularity': timeGranularity,
      'timeSlots': timeSlotsList,
      'totalMinutes': totalMinutes,
      'activeHours': activeHours,
    };
  }

  /// 计算指定时间粒度的数据（用于公共组件）
  static List<_TimeSlotDataWrapper> _calculateTimeSlotDataForWidget(
    List<ActivityRecord> activities,
    int granularityMinutes,
  ) {
    final totalSlots = (24 * 60) ~/ granularityMinutes;
    final slots = <_TimeSlotDataWrapper>[];
    final now = DateTime.now();

    for (int i = 0; i < totalSlots; i++) {
      final hour = (i * granularityMinutes) ~/ 60;
      final minute = (i * granularityMinutes) % 60;

      final slotStart = DateTime(now.year, now.month, now.day, hour, minute);
      final slotEnd = slotStart.add(Duration(minutes: granularityMinutes));

      int totalMinutes = 0;
      final Map<String, int> tagDurations = {};

      for (final activity in activities) {
        if (activity.startTime.isBefore(slotEnd) &&
            activity.endTime.isAfter(slotStart)) {
          final effectiveStart =
              activity.startTime.isBefore(slotStart)
                  ? slotStart
                  : activity.startTime;
          final effectiveEnd =
              activity.endTime.isAfter(slotEnd) ? slotEnd : activity.endTime;

          if (effectiveEnd.isAfter(effectiveStart)) {
            final minutes = effectiveEnd.difference(effectiveStart).inMinutes;
            totalMinutes += minutes;

            // 收集每个标签的时长
            for (final tag in activity.tags) {
              tagDurations[tag] = (tagDurations[tag] ?? 0) + minutes;
            }
          }
        }
      }

      slots.add(
        _TimeSlotDataWrapper(
          hour: hour,
          minute: minute,
          durationMinutes: totalMinutes,
          tagDurations: tagDurations,
        ),
      );
    }

    return slots;
  }

  /// 计算活跃小时数（用于公共组件）
  static int _calculateActiveHoursForWidget(List<ActivityRecord> activities) {
    final activeHours = <int>{};
    for (final activity in activities) {
      final startHour = activity.startTime.hour;
      final endHour = activity.endTime.hour;

      for (int h = startHour; h <= endHour; h++) {
        final hourStart = DateTime(
          activity.startTime.year,
          activity.startTime.month,
          activity.startTime.day,
          h,
          0,
        );
        final hourEnd = hourStart.add(const Duration(hours: 1));

        if (activity.startTime.isBefore(hourEnd) &&
            activity.endTime.isAfter(hourStart)) {
          activeHours.add(h);
        }
      }
    }
    return activeHours.length;
  }

  /// 七天活动统计图表小组件提供者
  static Map<String, Map<String, dynamic>> _provideWeeklyChartWidgets(
    Map<String, dynamic> data,
  ) {
    final plugin =
        PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
    if (plugin == null) return {};

    // 获取过去7天的活动数据
    final now = DateTime.now();
    final sevenDaysData = <_DayActivityData>[];
    final weekDayLabels = ['一', '二', '三', '四', '五', '六', '日'];
    final weekDayLabelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final activities = plugin.getActivitiesForDateSync(date);
      final totalMinutes = activities.fold<int>(
        0,
        (sum, a) => sum + a.durationInMinutes,
      );
      sevenDaysData.add(_DayActivityData(
        date: date,
        totalMinutes: totalMinutes,
        activityCount: activities.length,
      ));
    }

    // 计算统计数据
    final totalWeekMinutes = sevenDaysData.fold<int>(
      0,
      (sum, d) => sum + d.totalMinutes,
    );
    final avgMinutes = totalWeekMinutes / 7;
    final maxMinutes =
        sevenDaysData.map((d) => d.totalMinutes).reduce((a, b) => a > b ? a : b);

    // 为各种图表组件准备数据
    final weeklyDurations = sevenDaysData.map((d) => d.totalMinutes.toDouble()).toList();
    final weeklyNormalized = maxMinutes > 0
        ? weeklyDurations.map((d) => d / maxMinutes).toList()
        : List.filled(7, 0.0);

    // 格式化日期范围
    final startDate = DateFormat('MM月dd日').format(sevenDaysData.first.date);
    final endDate = DateFormat('MM月dd日').format(sevenDaysData.last.date);

    // 获取今天和昨天的数据用于对比
    final todayMinutes = sevenDaysData.last.totalMinutes.toDouble();
    final yesterdayMinutes = sevenDaysData[sevenDaysData.length - 2].totalMinutes.toDouble();
    final changePercent = yesterdayMinutes > 0
            ? ((todayMinutes - yesterdayMinutes) / yesterdayMinutes * 100)
                .floor()
        : 0.0;

    return {
      // StressLevelMonitor (CardBarChartMonitor) - 压力水平监测样式
      'stressLevelMonitor': {
        'title': '活动时长',
        'icon': 'timeline',
        'currentScore': avgMinutes / 60, // 转换为小时
        'status': _getActivityStatus(avgMinutes),
        'scoreUnit': '小时/天',
        'weeklyData': sevenDaysData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return {
            'day': weekDayLabelsEn[(now.subtract(Duration(days: 6 - index)).weekday - 1) % 7],
            'value': maxMinutes > 0 ? data.totalMinutes / maxMinutes : 0.0,
            'isSelected': index == 6,
          };
        }).toList(),
      },

      // LineChartTrendCard - 折线图趋势卡片
      'lineChartTrendCard': {
        'title': '活动时长趋势',
        'subtitle': '$startDate - $endDate',
        'date': DateFormat('yyyy-MM-dd').format(now),
        'totalValue': totalWeekMinutes,
        'changePercent': changePercent,
        'value': avgMinutes / 60, // 平均值（小时）
        'label': '日均活动',
        'unit': '小时',
        'inline': false,
        'dataPoints':
            sevenDaysData.map((d) {
              final normalized =
                  maxMinutes > 0 ? d.totalMinutes / maxMinutes : 0.0;
              return normalized * 100; // 转换为0-100的百分比
        }).toList(),
      },

      // SmoothLineChartCard - 平滑折线图卡片
      'smoothLineChartCard': {
        'title': '活动时长',
        'subtitle': '近7天统计',
        'date': DateFormat('MM月dd日').format(now),
        'currentValue': avgMinutes.toStringAsFixed(1),
        'targetValue': '${(12 * 60).toStringAsFixed(0)}', // 12小时目标
        'unit': '分钟',
        'maxValue': 120.0, // 匹配 y 值范围 0-120
        'timeLabels': weekDayLabels, // 星期标签
        'dataPoints': sevenDaysData.asMap().entries.map((entry) {
          final value = entry.value.totalMinutes;
          final normalized = maxMinutes > 0 ? value / maxMinutes : 0.0;
          return {
            'x': (entry.key * 53.33).clamp(0.0, 320.0),
            'y': (120 - normalized * 100).clamp(0.0, 120.0),
          };
        }).toList(),
      },

      // BarChartStatsCard - 柱状图统计卡片
      'barChartStatsCard': {
        'title': '活动统计',
        'dateRange': '$startDate - $endDate',
        'averageValue': avgMinutes / 60, // 转换为小时
        'unit': '小时',
        'icon': 'timeline',
        'iconColor': Colors.pink.value,
        'data': sevenDaysData.map((d) => d.totalMinutes / 60).toList(),
        'labels': List.generate(7, (index) {
          final date = now.subtract(Duration(days: 6 - index));
          return weekDayLabels[(date.weekday - 1) % 7];
        }),
        'maxValue': maxMinutes / 60, // 转换为小时
      },

      // WeeklyBarsCard - 周柱状图卡片
      'weeklyBarsCard': {
        'title': '周活动统计',
        'icon': 'bar_chart',
        'currentValue': avgMinutes / 60, // 转为小时
        'unit': '小时',
        'status': '日均',
        'dailyValues': maxMinutes > 0
            ? sevenDaysData.map((d) => d.totalMinutes / maxMinutes).toList()
            : List.filled(7, 0.0),
      },

      // ExpenseComparisonChart - 支出对比图表
      'expenseComparisonChart': {
        'title': '活动对比',
        'currentAmount': todayMinutes / 60, // 转为小时
        'unit': '小时',
        'changePercent': changePercent,
        'maxValue': 24.0, // 24小时
        'labels': List.generate(7, (index) {
          final date = now.subtract(Duration(days: 6 - index));
          return DateFormat('dd').format(date);
        }),
        'dailyData': sevenDaysData.asMap().entries.map((entry) {
          return {
            'lastMonth': entry.key > 0
                ? sevenDaysData[entry.key - 1].totalMinutes / 60
                : 0.0,
            'currentMonth': entry.value.totalMinutes / 60,
          };
        }).toList(),
      },

      // BloodPressureTracker (DualValueTrackerCardWrapper) - 双数值追踪卡片
      'bloodPressureTracker': {
        'title': '活动统计',
        'primaryValue': (todayMinutes / 60).toInt(),
        'secondaryValue': (avgMinutes / 60).toInt(),
        'status': _getActivityStatus(avgMinutes),
        'unit': '小时',
        'icon': 'timeline',
        'weekData': sevenDaysData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final normalized = maxMinutes > 0 ? data.totalMinutes / maxMinutes : 0.0;
          return {
            'label': weekDayLabelsEn[(now.subtract(Duration(days: 6 - index)).weekday - 1) % 7],
            'normalPercent': normalized,
            'elevatedPercent': 0.0,
          };
        }).toList(),
      },

      // TrendLineChartCard (TrendLineChartCardWrapper) - 趋势折线图卡片
      'trendLineChartCard': {
        'title': '活动趋势',
        'icon': 'show_chart',
        'value': avgMinutes / 60, // 转为小时
        'dataPoints': sevenDaysData.asMap().entries.map((entry) {
          final value = entry.value.totalMinutes;
          final normalized = maxMinutes > 0 ? value / maxMinutes : 0.0;
          return {
            'x': (entry.key * 53.33).clamp(0.0, 320.0),
            'y': (120 - normalized * 100).clamp(0.0, 120.0),
          };
        }).toList(),
        'timeLabels': sevenDaysData.asMap().entries.map((entry) {
          return weekDayLabelsEn[(now.subtract(Duration(days: 6 - entry.key)).weekday - 1) % 7];
        }).toList(),
        'primaryColor': Colors.pink.value,
        'valueColor': Colors.pinkAccent.value,
      },

      // ModernRoundedBalanceCard - 现代圆角余额卡片
      'modernRoundedBalanceCard': {
        'title': '活动总时长',
        'balance': totalWeekMinutes / 60, // 转换为小时
        'available': avgMinutes / 60, // 平均时长
        'weeklyData': weeklyNormalized,
      },
    };
  }

  /// 从选择器数据提取热力图配置
  static Map<String, dynamic> extractHeatmapConfig(List<dynamic> dataArray) {
    int granularity = 60; // 默认值
    final item = dataArray[0];

    // 提取 rawData
    if (item is SelectableItem) {
      granularity = item.rawData as int;
    } else if (item is int) {
      granularity = item;
    }

    return {'timeGranularity': granularity};
  }
}

/// 创建活动快捷入口小组件（1x1）
class ActivityCreateShortcutWidget extends StatelessWidget {
  const ActivityCreateShortcutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(0.0, constraints.maxHeight);
        final iconSize = size * 0.4;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToCreateActivity(context),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle, size: iconSize, color: Colors.pink),
                  SizedBox(height: size * 0.05),
                  Text(
                    'activity_createActivity'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: (size * 0.12).clamp(10.0, 14.0),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToCreateActivity(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) {
        toastService.showToast('activity_loadFailed'.tr);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ActivityEditScreen()),
      );
    } catch (e) {
      toastService.showToast('activity_operationFailed'.tr);
      debugPrint('[ActivityCreateShortcut] 打开创建界面失败: $e');
    }
  }
}

/// 上次活动小组件（2x1）
/// 显示距离上次活动经过的时间和上次活动的时间，点击跳转到活动编辑界面
class ActivityLastActivityWidget extends StatefulWidget {
  const ActivityLastActivityWidget({super.key});

  @override
  State<ActivityLastActivityWidget> createState() =>
      _ActivityLastActivityWidgetState();
}

class _ActivityLastActivityWidgetState
    extends State<ActivityLastActivityWidget> {
  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['activity_added', 'activity_updated', 'activity_deleted'],
      onEvent: () => setState(() {}),
      child: FutureBuilder<ActivityRecord?>(
        future: _getLastActivity(),
        builder: (context, snapshot) {
          final lastActivity = snapshot.data;

          if (lastActivity == null) {
            return _buildNoActivityWidget(context);
          }

          return _buildLastActivityWidget(context, lastActivity);
        },
      ),
    );
  }

  Future<ActivityRecord?> _getLastActivity() async {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return null;
      return await plugin.activityService.getLastActivity();
    } catch (e) {
      debugPrint('[ActivityLastActivity] 获取上次活动失败: $e');
      return null;
    }
  }

  Widget _buildNoActivityWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCreateActivity(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.pink, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '暂无活动记录',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '点击添加第一个活动',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle, color: Colors.pink, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastActivityWidget(
    BuildContext context,
    ActivityRecord activity,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final endTime = activity.endTime;
    final timeDiff = now.difference(endTime);

    // 格式化时间差
    String timeAgo;
    if (timeDiff.inMinutes < 1) {
      timeAgo = '刚刚';
    } else if (timeDiff.inHours < 1) {
      timeAgo = '${timeDiff.inMinutes}分钟前';
    } else if (timeDiff.inDays < 1) {
      timeAgo = '${timeDiff.inHours}小时前';
    } else {
      timeAgo = '${timeDiff.inDays}天前';
    }

    // 活动标题（如果没有标题则使用"未命名活动"）
    final title = activity.title.trim().isEmpty ? '未命名活动' : activity.title;

    // 计算持续时长
    final duration = activity.endTime.difference(activity.startTime);
    final durationText = _formatDuration(duration.inMinutes);

    // 构建副标题信息
    final List<String> subtitleParts = [];

    // 添加心情
    if (activity.mood != null && activity.mood!.isNotEmpty) {
      subtitleParts.add(activity.mood!);
    }

    // 添加标签
    if (activity.tags.isNotEmpty) {
      subtitleParts.add(activity.tags.join(', '));
    }

    // 添加持续时长
    subtitleParts.add(durationText);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCreateActivity(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '上次活动: $timeAgo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit, color: Colors.pink.withAlpha(150), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours小时$mins分钟';
    } else {
      return '$mins分钟';
    }
  }

  void _navigateToCreateActivity(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) {
        toastService.showToast('activity_loadFailed'.tr);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ActivityEditScreen()),
      );
    } catch (e) {
      toastService.showToast('activity_operationFailed'.tr);
      debugPrint('[ActivityLastActivity] 打开创建界面失败: $e');
    }
  }
}

/// 一天活动数据（用于7天统计）
class _DayActivityData {
  final DateTime date;
  final int totalMinutes;
  final int activityCount;

  const _DayActivityData({
    required this.date,
    required this.totalMinutes,
    required this.activityCount,
  });
}

/// 根据平均活动时长获取状态描述
String _getActivityStatus(double avgMinutes) {
  if (avgMinutes >= 720) return '非常活跃'; // 12小时以上
  if (avgMinutes >= 480) return '很活跃'; // 8小时以上
  if (avgMinutes >= 360) return '活跃'; // 6小时以上
  if (avgMinutes >= 240) return '适度活动'; // 4小时以上
  if (avgMinutes >= 120) return '轻度活动'; // 2小时以上
  if (avgMinutes >= 60) return '少量活动'; // 1小时以上
  return '需要更多活动';
}

/// 时间槽数据
class TimeSlotData {
  final int hour;
  final int minute;
  final int durationMinutes;

  /// 标签到时长的映射（用于确定主要标签颜色）
  final Map<String, int> tagDurations;

  TimeSlotData({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    this.tagDurations = const {},
  });

  /// 获取持续时间最长的标签
  String? get primaryTag {
    if (tagDurations.isEmpty) return null;
    return tagDurations.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// 格式化时间范围（静态版本）
String _formatTimeRangeStatic(DateTime start, DateTime end) {
  return '${_formatTimeStatic(start)} - ${_formatTimeStatic(end)}';
}

/// 格式化时间（HH:mm）（静态版本）
String _formatTimeStatic(DateTime time) {
  return DateFormat('HH:mm').format(time);
}

/// 从标签生成颜色（与 ActivityGridView 保持一致）
Color _getColorFromTagForWidgets(String tag) {
  final baseHue = (tag.hashCode % 360).abs().toDouble();
  return HSLColor.fromAHSL(1.0, baseHue, 0.6, 0.5).toColor();
}

/// 格式化时长为显示文本（如果超过60分钟转小时，带小数点）
String _formatDurationForDisplay(int minutes) {
  if (minutes >= 60) {
    final hours = minutes / 60;
    // 如果是整数小时，不显示小数
    if (hours == hours.truncateToDouble()) {
      return '${hours.toInt()}小时';
    }
    // 否则显示一位小数
    return '${hours.toStringAsFixed(1)}小时';
  }
  return '$minutes分钟';
}

/// 格式化活动列表的时间段为字符串
String _formatActivitiesTimeRange(List<ActivityRecord> activities) {
  if (activities.isEmpty) return '';

  // 按开始时间排序
  final sortedActivities = List<ActivityRecord>.from(activities);
  sortedActivities.sort((a, b) => a.startTime.compareTo(b.startTime));

  // 最多显示3个时间段
  final timeRanges = sortedActivities
      .take(3)
      .map((a) => _formatTimeRangeStatic(a.startTime, a.endTime))
      .toList();

  if (sortedActivities.length > 3) {
    return '${timeRanges.join('、')}...';
  }

  return timeRanges.join('、');
}

/// 将活动记录转换为 DailyScheduleCardWidget 的 EventData 格式
Map<String, dynamic> _convertActivityToEventData(ActivityRecord activity) {
  // 将 24 小时制转换为 12 小时制
  final startHour = activity.startTime.hour;
  final endHour = activity.endTime.hour;

  final startPeriod = startHour >= 12 ? 'PM' : 'AM';
  final endPeriod = endHour >= 12 ? 'PM' : 'AM';

  final startHour12 = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour);
  final endHour12 = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour);

  // 根据标签选择颜色
  String color = 'gray';
  if (activity.tags.isNotEmpty) {
    final primaryTag = activity.tags.first;
    color = _getColorNameFromTag(primaryTag);
  }

  return {
    'title': activity.title.isEmpty ? '未命名活动' : activity.title,
    'startTime': startHour12.toString().padLeft(2, '0'),
    'startPeriod': startPeriod,
    'endTime': endHour12.toString().padLeft(2, '0'),
    'endPeriod': endPeriod,
    'color': color,
    'location': null,
    'isAllDay': false,
  };
}

/// 根据标签获取颜色名称
String _getColorNameFromTag(String tag) {
  final colorValue = _getColorFromTagForWidgets(tag).value;

  // 简单映射：根据颜色值范围选择预设颜色
  if (colorValue == 0xFFF97316) return 'orange';
  if (colorValue == 0xFF4ADE80) return 'green';
  if (colorValue == 0xFF60A5FA) return 'blue';
  if (colorValue == 0xFFF87171) return 'red';
  return 'gray';
}

/// 时间槽数据包装类（用于公共组件数据传递）
class _TimeSlotDataWrapper {
  final int hour;
  final int minute;
  final int durationMinutes;
  final Map<String, int> tagDurations;

  _TimeSlotDataWrapper({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    this.tagDurations = const {},
  });
}

/// 构建时间线日程卡片数据
/// 显示今天和昨天的活动（ TimelineScheduleCard 组件使用）
Map<String, dynamic> _buildTimelineScheduleCardData(
  List<ActivityRecord> todayActivities,
  List<ActivityRecord> yesterdayActivities,
  DateTime now,
) {
  // 计算昨天的日期
  final yesterday = now.subtract(const Duration(days: 1));

  // 获取星期名称
  final todayWeekday = _getWeekdayName(now.weekday);
  final yesterdayWeekday = _getWeekdayName(yesterday.weekday);

  // 转换今日活动为 TimelineEvent 格式
  final todayEvents = todayActivities
      .map((a) => _convertActivityToTimelineEvent(a))
      .toList();

  // 转换昨日活动为 TimelineEvent 格式
  final yesterdayEvents = yesterdayActivities
      .map((a) => _convertActivityToTimelineEvent(a))
      .toList();

  return {
    'todayWeekday': todayWeekday,
    'todayDay': now.day,
    'tomorrowWeekday': yesterdayWeekday,
    'tomorrowDay': yesterday.day,
    'todayEvents': todayEvents,
    'tomorrowEvents': yesterdayEvents,
  };
}

/// 获取星期名称（中文）
String _getWeekdayName(int weekday) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return weekdays[(weekday - 1) % 7];
}

/// 将活动记录转换为 TimelineEvent 格式
Map<String, dynamic> _convertActivityToTimelineEvent(
  ActivityRecord activity,
) {
  // 获取主标签颜色
  final tagColor = activity.tags.isNotEmpty
      ? _getColorFromTagForWidgets(activity.tags.first)
      : Colors.pink;

  // 计算背景色和文本色
  final backgroundColorLight = tagColor.withOpacity(0.15);
  final backgroundColorDark = tagColor.withOpacity(0.25);
  final textColorLight = tagColor;
  final textColorDark = tagColor.withOpacity(0.9);

  // 格式化时间显示（如 "9:45AM"）
  final timeDisplay = _formatTimeToAMPM(activity.startTime);

  return {
    'hour': activity.startTime.hour,
    'title': activity.title.isEmpty ? '未命名活动' : activity.title,
    'time': timeDisplay,
    'color': tagColor.value,
    'backgroundColorLight': backgroundColorLight.value,
    'backgroundColorDark': backgroundColorDark.value,
    'textColorLight': textColorLight.value,
    'textColorDark': textColorDark.value,
    'subtextLight': const Color(0xFF8E8E93).value,
    'subtextDark': const Color(0xFF98989D).value,
  };
}

/// 格式化时间为 AM/PM 格式（如 "9:45AM"）
String _formatTimeToAMPM(DateTime time) {
  final hour = time.hour;
  final minute = time.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final minuteStr = minute.toString().padLeft(2, '0');
  return '$hour12:$minuteStr$period';
}

// ==================== 标签周统计图表画笔 ====================

/// 迷你趋势图画笔
class _MiniTrendPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniTrendPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartHeight = 60.0;
    final chartWidth = 140.0;
    final stepX = chartWidth / (data.length - 1);
    final maxValue = data
        .reduce((a, b) => a > b ? a : b)
        .clamp(0.01, double.infinity);

    // 绘制渐变填充
    final gradientPath = Path();
    gradientPath.moveTo(0, chartHeight);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        gradientPath.lineTo(x, y);
      } else {
        gradientPath.lineTo(x, y);
      }
    }
    gradientPath.lineTo(chartWidth, chartHeight);
    gradientPath.close();

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(gradientPath, fillPaint);

    // 绘制折线
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

/// 平滑趋势图画笔
class _SmoothTrendPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SmoothTrendPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartHeight = 80.0;
    final chartWidth = 140.0;
    final stepX = chartWidth / (data.length - 1);
    final maxValue = 100.0;

    // 绘制渐变填充
    final gradientPath = Path();
    gradientPath.moveTo(0, chartHeight);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        gradientPath.lineTo(x, y);
      } else {
        gradientPath.lineTo(x, y);
      }
    }
    gradientPath.lineTo(chartWidth, chartHeight);
    gradientPath.close();

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(gradientPath, fillPaint);

    // 绘制折线
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SmoothTrendPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

/// 收益趋势折线图画笔
class _EarningsLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _EarningsLinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartHeight = 100.0;
    final stepX = size.width / (data.length - 1);
    final maxValue = 100.0;

    // 绘制渐变填充
    final gradientPath = Path();
    gradientPath.moveTo(0, chartHeight);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        gradientPath.lineTo(x, y);
      } else {
        gradientPath.lineTo(x, y);
      }
    }
    gradientPath.lineTo(size.width, chartHeight);
    gradientPath.close();

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(gradientPath, fillPaint);

    // 绘制折线
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _EarningsLinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

/// 对比趋势图画笔（本周 vs 上周）
class _ComparisonTrendPainter extends CustomPainter {
  final List<double> currentData;
  final List<double> previousData;
  final Color currentColor;
  final Color previousColor;

  _ComparisonTrendPainter({
    required this.currentData,
    required this.previousData,
    required this.currentColor,
    required this.previousColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentData.isEmpty) return;

    final chartHeight = 120.0;
    final stepX = size.width / (currentData.length - 1);
    final maxValue = _getMaxValue().clamp(0.01, double.infinity);

    // 绘制上周数据（虚线）
    _drawDashedLine(
      canvas,
      previousData,
      stepX,
      chartHeight,
      maxValue,
      previousColor,
    );

    // 绘制本周数据（实线）
    _drawSolidLine(
      canvas,
      currentData,
      stepX,
      chartHeight,
      maxValue,
      currentColor,
    );
  }

  double _getMaxValue() {
    final currentMax =
        currentData.isEmpty ? 0.0 : currentData.reduce((a, b) => a > b ? a : b);
    final previousMax =
        previousData.isEmpty
            ? 0.0
            : previousData.reduce((a, b) => a > b ? a : b);
    return (currentMax > previousMax ? currentMax : previousMax) * 1.2;
  }

  void _drawDashedLine(
    Canvas canvas,
    List<double> data,
    double stepX,
    double chartHeight,
    double maxValue,
    Color color,
  ) {
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

    // 绘制虚线效果
    _drawDashedPath(canvas, path, paint, 8, 4);
  }

  void _drawSolidLine(
    Canvas canvas,
    List<double> data,
    double stepX,
    double chartHeight,
    double maxValue,
    Color color,
  ) {
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // 绘制数据点
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxValue) * chartHeight;
      canvas.drawCircle(Offset(x, y), 4.0, Paint()..color = color);
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    int dashLength,
    int gapLength,
  ) {
    final metrics = path.computeMetrics().first;
    double distance = 0.0;
    bool isDash = true;

    while (distance < metrics.length) {
      final tangent = metrics.getTangentForOffset(distance)!;
      if (isDash) {
        final dashEnd = (distance + dashLength).clamp(0.0, metrics.length);
        final dashTangent = metrics.getTangentForOffset(dashEnd)!;
        canvas.drawLine(tangent.position, dashTangent.position, paint);
        distance = dashEnd;
      } else {
        distance = (distance + gapLength).clamp(0.0, metrics.length);
      }
      isDash = !isDash;
    }
  }

  @override
  bool shouldRepaint(covariant _ComparisonTrendPainter oldDelegate) =>
      oldDelegate.currentData != currentData ||
      oldDelegate.previousData != previousData ||
      oldDelegate.currentColor != currentColor ||
      oldDelegate.previousColor != previousColor;
}
