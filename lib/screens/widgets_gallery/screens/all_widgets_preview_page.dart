import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 导入所有 example widgets
import 'package:Memento/screens/widgets_gallery/screens/half_circle_gauge_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/segmented_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/circular_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/multi_metric_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/task_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/circular_metrics_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/curve_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/activity_rings_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/monthly_progress_with_dots_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/icon_circular_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/nutrition_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/task_progress_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/rounded_task_progress_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/milestone_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/watch_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/mood_tracker_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/chart_icon_display_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stress_level_monitor_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/sleep_tracking_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/sleep_duration_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/modern_egfr_health_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/medication_tracker_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/hydration_tracker_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weight_tracking_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/blood_pressure_tracker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/activity_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/habit_streak_tracker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weekly_steps_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/route_tracking_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weekly_dot_tracker_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/event_calendar_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_events_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_schedule_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/timeline_schedule_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/journal_prompt_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_reflection_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/line_chart_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/trend_line_chart_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/smooth_line_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/vertical_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stacked_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stacked_bar_chart_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stacked_ring_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/monthly_bar_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/ranked_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/contribution_heatmap_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/bar_chart_stats_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weekly_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/dual_range_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/donut_chart_stats_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/mini_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/trend_value_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/trend_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weight_trend_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/dual_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weekly_bars_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/screen_time_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/vertical_bar_chart_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/sleep_stage_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/performance_bar_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/portfolio_stacked_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/revenue_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/article_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/task_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/notes_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/profile_card_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/split_image_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/news_update_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/news_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/color_tag_task_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/holiday_rental_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/rental_preview_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/inbox_message_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/message_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/upcoming_tasks_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/social_profile_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/social_activity_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/vertical_property_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/rounded_task_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_todo_list_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/rounded_reminders_list_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/earnings_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/spending_trend_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/expense_comparison_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/modern_rounded_spending_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/budget_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/account_balance_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/category_stack_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/wallet_balance_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/modern_rounded_balance_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/monthly_bill_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/expense_donut_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/audio_waveform_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/music_player_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/dual_slider_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/score_card_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/colorful_shortcuts_grid_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weather_forecast_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/timeline_status_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/storage_breakdown_widget_example.dart';

/// 小组件预览项数据模型
class WidgetPreviewItem {
  final String category;
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  WidgetPreviewItem({
    required this.category,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

/// 所有小组件预览页面 - 使用垂直标签页展示
class AllWidgetsPreviewPage extends StatefulWidget {
  final List<WidgetPreviewItem> widgetItems;

  const AllWidgetsPreviewPage({super.key, required this.widgetItems});

  @override
  State<AllWidgetsPreviewPage> createState() => _AllWidgetsPreviewPageState();
}

class _AllWidgetsPreviewPageState extends State<AllWidgetsPreviewPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.widgetItems.length,
      vsync: this,
    );
    // 默认选中第一个
    if (widget.widgetItems.isNotEmpty) {
      _tabController.animateTo(0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('所有小组件预览 (${widget.widgetItems.length})'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 顶部水平 TabBar - 可滚动
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: ExtendedTabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: widget.widgetItems.map((item) {
                return Tab(
                  icon: Icon(item.icon, size: 18),
                  text: item.title,
                );
              }).toList(),
            ),
          ),
          // 下方 TabBarView 展示预览
          Expanded(
            child: ExtendedTabBarView(
              controller: _tabController,
              children: widget.widgetItems.map((item) {
                return _buildWidgetPreviewContent(item);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个小组件的预览内容
  Widget _buildWidgetPreviewContent(WidgetPreviewItem item) {
    // 获取对应的 Widget
    final widget = _WidgetRegistry.getWidget(item.route);

    return Column(
      children: [
        // 顶部标题栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: '复制类名',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: item.subtitle));
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Widget 内容区域
        Expanded(
          child:
              widget != null
                  ? Padding(padding: const EdgeInsets.all(16), child: widget)
                  : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '未找到组件',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '路由: ${item.route}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }
}

/// Widget 注册表 - 从路由路径获取对应的 Widget
class _WidgetRegistry {
  static final Map<String, Widget Function()> _widgets = {
    // 进度类
    '/widgets_gallery/half_circle_gauge_widget':
        () => const HalfCircleGaugeWidgetExample(),
    '/widgets_gallery/segmented_progress_card':
        () => const SegmentedProgressCardExample(),
    '/widgets_gallery/circular_progress_card':
        () => const CircularProgressCardExample(),
    '/widgets_gallery/multi_metric_progress_card':
        () => const MultiMetricProgressCardExample(),
    '/widgets_gallery/task_progress_card':
        () => const TaskProgressCardExample(),
    '/widgets_gallery/circular_metrics_card':
        () => const CircularMetricsCardExample(),
    '/widgets_gallery/curve_progress_card':
        () => const CurveProgressCardExample(),
    '/widgets_gallery/activity_rings_card':
        () => const ActivityRingsCardExample(),
    '/widgets_gallery/monthly_progress_with_dots_card':
        () => const MonthlyProgressWithDotsCardExample(),
    '/widgets_gallery/icon_circular_progress_card':
        () => const IconCircularProgressCardExample(),
    '/widgets_gallery/nutrition_progress_card':
        () => SplitColumnProgressBarCardExample(),
    '/widgets_gallery/task_progress_list_card':
        () => const TaskProgressListCardExample(),
    '/widgets_gallery/rounded_task_progress_widget':
        () => const RoundedTaskProgressWidgetExample(),
    // 追踪类
    '/widgets_gallery/milestone_card': () => const MilestoneCardExample(),
    '/widgets_gallery/watch_progress_card':
        () => const WatchProgressCardExample(),
    '/widgets_gallery/mood_tracker_widget':
        () => const MoodTrackerWidgetExample(),
    '/widgets_gallery/mood_chart_card': () => const ChartIconDisplayCardExample(),
    '/widgets_gallery/stress_level_monitor':
        () => const StressLevelMonitorExample(),
    '/widgets_gallery/sleep_tracking_card':
        () => VerticalCircularProgressCardExample(),
    '/widgets_gallery/sleep_duration_card':
        () => const SleepDurationCardExample(),
    '/widgets_gallery/modern_egfr_health_widget':
        () => const ModernFlipCounterCardExample(),
    '/widgets_gallery/medication_tracker_widget':
        () => const SquarePillProgressCardExample(),
    '/widgets_gallery/hydration_tracker_widget':
        () => const HydrationTrackerWidgetExample(),
    '/widgets_gallery/weight_tracking_widget':
        () => const WeightTrackingWidgetExample(),
    '/widgets_gallery/blood_pressure_tracker':
        () => const BloodPressureTrackerExample(),
    '/widgets_gallery/activity_progress_card':
        () => CardDotProgressDisplayExample(),
    '/widgets_gallery/habit_streak_tracker':
        () => const HabitStreakTrackerExample(),
    '/widgets_gallery/weekly_steps_progress_card':
        () => const WeeklyStepsProgressCardExample(),
    '/widgets_gallery/route_tracking_card':
        () => const RouteTrackingCardExample(),
    '/widgets_gallery/weekly_dot_tracker_card':
        () => const WeeklyDotTrackerCardExample(),
    // 日历类
    '/widgets_gallery/event_calendar_widget':
        () => const EventCalendarWidgetExample(),
    '/widgets_gallery/daily_events_card': () => const DailyEventsCardExample(),
    '/widgets_gallery/daily_schedule_card':
        () => const DailyScheduleCardExample(),
    '/widgets_gallery/timeline_schedule_card':
        () => const TimelineScheduleCardExample(),
    '/widgets_gallery/journal_prompt_card':
        () => const JournalPromptCardExample(),
    '/widgets_gallery/daily_reflection_card':
        () => const DailyReflectionCardExample(),
    // 图表类
    '/widgets_gallery/line_chart_trend_card':
        () => const LineChartTrendCardExample(),
    '/widgets_gallery/trend_line_chart_widget':
        () => const TrendLineChartWidgetExample(),
    '/widgets_gallery/smooth_line_chart_card':
        () => const SmoothLineChartCardExample(),
    '/widgets_gallery/vertical_bar_chart_card':
        () => const VerticalBarChartCardExample(),
    '/widgets_gallery/stacked_bar_chart_card':
        () => const StackedBarChartCardExample(),
    '/widgets_gallery/stacked_bar_chart_widget':
        () => const StackedBarChartWidgetExample(),
    '/widgets_gallery/stacked_ring_chart':
        () => const StackedRingChartExample(),
    '/widgets_gallery/monthly_bar_chart': () => const MonthlyBarChartExample(),
    '/widgets_gallery/ranked_bar_chart_card':
        () => const RankedBarChartCardExample(),
    '/widgets_gallery/contribution_heatmap_card':
        () => const ContributionHeatmapCardExample(),
    '/widgets_gallery/bar_chart_stats_card':
        () => const BarChartStatsCardExample(),
    '/widgets_gallery/daily_bar_chart_card':
        () => const DailyBarChartCardExample(),
    '/widgets_gallery/weekly_bar_chart_card':
        () => const WeeklyBarChartCardExample(),
    '/widgets_gallery/dual_range_chart_card':
        () => const DualRangeChartCardExample(),
    '/widgets_gallery/donut_chart_stats_card':
        () => const DonutChartStatsCardExample(),
    '/widgets_gallery/mini_trend_card': () => const MiniTrendCardExample(),
    '/widgets_gallery/trend_value_card': () => const TrendValueCardExample(),
    '/widgets_gallery/trend_list_card': () => const TrendListCardExample(),
    '/widgets_gallery/weight_trend_chart':
        () => CardTrendLineChartExample(),
    '/widgets_gallery/dual_bar_chart_card':
        () => const DualBarChartCardExample(),
    '/widgets_gallery/weekly_bars_card': () => const WeeklyBarsCardExample(),
    '/widgets_gallery/screen_time_chart': () => const ScreenTimeChartExample(),
    '/widgets_gallery/vertical_bar_chart_widget':
        () => const VerticalBarChartExample(),
    '/widgets_gallery/sleep_stage_chart': () => const SleepStageChartExample(),
    '/widgets_gallery/performance_bar_chart':
        () => const PerformanceBarChartExample(),
    '/widgets_gallery/portfolio_stacked_chart':
        () => const PortfolioStackedChartExample(),
    '/widgets_gallery/revenue_trend_card':
        () => const RevenueTrendCardExample(),
    // 内容类
    '/widgets_gallery/article_list_card': () => const ArticleListCardExample(),
    '/widgets_gallery/task_list_card': () => const TaskListCardExample(),
    '/widgets_gallery/notes_list_card': () => const NotesListCardExample(),
    '/widgets_gallery/profile_card_widget':
        () => const ProfileCardWidgetExample(),
    '/widgets_gallery/split_image_card': () => const SplitImageCardExample(),
    '/widgets_gallery/news_update_card': () => const NewsUpdateCardExample(),
    '/widgets_gallery/news_card': () => const NewsCardExample(),
    '/widgets_gallery/color_tag_task_card':
        () => const ColorTagTaskCardExample(),
    '/widgets_gallery/holiday_rental_card':
        () => const HolidayRentalCardExample(),
    '/widgets_gallery/rental_preview_card':
        () => const RentalPreviewCardExample(),
    '/widgets_gallery/inbox_message_card':
        () => const InboxMessageCardExample(),
    '/widgets_gallery/message_list_card': () => const MessageListCardExample(),
    '/widgets_gallery/upcoming_tasks_widget':
        () => const UpcomingTasksWidgetExample(),
    '/widgets_gallery/social_profile_card':
        () => const SocialProfileCardExample(),
    '/widgets_gallery/social_activity_card':
        () => const SocialActivityCardExample(),
    '/widgets_gallery/vertical_property_card':
        () => const VerticalPropertyCardExample(),
    '/widgets_gallery/rounded_task_list_card':
        () => const RoundedTaskListCardExample(),
    '/widgets_gallery/daily_todo_list_widget':
        () => const DailyTodoListWidgetExample(),
    '/widgets_gallery/rounded_reminders_list':
        () => const RoundedRemindersListExample(),
    // 财务类
    '/widgets_gallery/earnings_trend_card':
        () => const EarningsTrendCardExample(),
    '/widgets_gallery/spending_trend_chart':
        () => const SpendingTrendChartExample(),
    '/widgets_gallery/expense_comparison_chart':
        () => const ExpenseComparisonChartExample(),
    '/widgets_gallery/modern_rounded_spending_widget':
        () => const ModernRoundedSpendingWidgetExample(),
    '/widgets_gallery/budget_trend_card': () => const BudgetTrendCardExample(),
    '/widgets_gallery/account_balance_card':
        () => const AccountBalanceCardExample(),
    '/widgets_gallery/category_stack_widget':
        () => const CategoryStackWidgetExample(),
    '/widgets_gallery/wallet_balance_card':
        () => const WalletBalanceCardExample(),
    '/widgets_gallery/modern_rounded_balance_widget':
        () => const ModernRoundedBalanceWidgetExample(),
    '/widgets_gallery/monthly_bill_card': () => const MonthlyBillCardExample(),
    '/widgets_gallery/expense_donut_chart':
        () => const ExpenseDonutChartExample(),
    // 媒体类
    '/widgets_gallery/audio_waveform_widget':
        () => const AudioWaveformWidgetExample(),
    '/widgets_gallery/music_player_card': () => const MusicPlayerCardExample(),
    // 工具类
    '/widgets_gallery/dual_slider_widget':
        () => const DualSliderWidgetExample(),
    '/widgets_gallery/score_card_widget': () => const ScoreCardWidgetExample(),
    '/widgets_gallery/colorful_shortcuts_grid':
        () => const ColorfulShortcutsGridExample(),
    '/widgets_gallery/weather_forecast_card':
        () => const WeatherForecastCardExample(),
    '/widgets_gallery/timeline_status_card':
        () => const TimelineStatusCardExample(),
    '/widgets_gallery/storage_breakdown_widget':
        () => const StorageBreakdownWidgetExample(),
  };

  static Widget? getWidget(String route) {
    final builder = _widgets[route];
    return builder?.call();
  }

}
