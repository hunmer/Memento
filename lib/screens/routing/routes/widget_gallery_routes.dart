import 'package:flutter/material.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/screens/widgets_gallery/widgets_gallery_screen.dart';
import 'package:Memento/screens/widgets_gallery/screens/color_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/icon_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/avatar_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/circle_icon_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/calendar_strip_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/image_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/location_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/backup_time_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/memento_editor_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/data_selector_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/enhanced_calendar_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/group_selector_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/simple_group_selector_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/tag_manager_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/statistics_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/custom_dialog_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/smooth_bottom_sheet_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/file_preview_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/app_drawer_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/home_widgets_gallery_screen.dart';
import 'package:Memento/screens/widgets_gallery/screens/all_widgets_preview_page.dart';
import 'package:Memento/screens/widgets_gallery/screens/half_circle_gauge_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/widget_config_editor_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/preset_edit_form_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/super_cupertino_navigation_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/segmented_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/milestone_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/circular_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/monthly_progress_with_dots_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/multi_metric_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/line_chart_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/article_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/vertical_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/trend_line_chart_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stacked_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stacked_bar_chart_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stacked_ring_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/monthly_bar_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/earnings_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/ranked_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/smooth_line_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/contribution_heatmap_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/audio_waveform_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/dual_slider_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/storage_breakdown_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/route_tracking_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/watch_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/bar_chart_stats_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/activity_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weekly_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/wallet_balance_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/habit_streak_tracker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/music_player_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/event_calendar_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/performance_bar_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/expense_donut_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/profile_card_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/portfolio_stacked_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/spending_trend_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/blood_pressure_tracker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/mood_tracker_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/stress_level_monitor_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_todo_list_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weight_tracking_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weekly_steps_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/dual_range_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weekly_dot_tracker_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/mini_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_events_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/score_card_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/category_stack_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/timeline_schedule_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/message_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_schedule_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/expense_comparison_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/activity_rings_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weekly_bars_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/medication_tracker_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/modern_egfr_health_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/modern_rounded_balance_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/dual_bar_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/timeline_status_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/sleep_stage_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/sleep_tracking_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/monthly_bill_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/journal_prompt_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/task_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/rounded_task_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/daily_reflection_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/mood_chart_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/modern_rounded_mood_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/modern_rounded_spending_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/hydration_tracker_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/trend_value_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/sleep_duration_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weight_trend_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/account_balance_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/budget_trend_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/icon_circular_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/color_tag_task_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/holiday_rental_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/donut_chart_stats_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/news_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/news_update_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/inbox_message_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/upcoming_tasks_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/notes_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/rounded_reminders_list_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/circular_metrics_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/colorful_shortcuts_grid_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/rental_preview_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/split_image_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/social_profile_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/curve_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/nutrition_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/trend_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/social_activity_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/screen_time_chart_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/vertical_property_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/task_progress_list_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/task_progress_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/rounded_task_progress_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/vertical_bar_chart_widget_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/weather_forecast_card_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/task_list_stat_card_example.dart';

/// 组件展示路由注册表
class WidgetGalleryRoutes implements RouteRegistry {
  @override
  String get name => 'WidgetGalleryRoutes';

  @override
  List<RouteDefinition> get routes => [
        // 组件展示主页
        RouteDefinition(
          path: '/widgets_gallery',
          handler: (settings) => RouteHelpers.createRoute(const WidgetsGalleryScreen(), settings: settings),
          description: '组件展示主页',
        ),
        RouteDefinition(
          path: 'widgets_gallery',
          handler: (settings) => RouteHelpers.createRoute(const WidgetsGalleryScreen(), settings: settings),
          description: '组件展示主页（别名）',
        ),

        // 各组件示例
        RouteDefinition(
          path: '/widgets_gallery/color_picker',
          handler: (settings) => RouteHelpers.createRoute(const ColorPickerExample(), settings: settings),
          description: '颜色选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/icon_picker',
          handler: (settings) => RouteHelpers.createRoute(const IconPickerExample(), settings: settings),
          description: '图标选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/avatar_picker',
          handler: (settings) => RouteHelpers.createRoute(const AvatarPickerExample(), settings: settings),
          description: '头像选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/circle_icon_picker',
          handler: (settings) => RouteHelpers.createRoute(const CircleIconPickerExample(), settings: settings),
          description: '圆形图标选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/calendar_strip_picker',
          handler: (settings) => RouteHelpers.createRoute(const CalendarStripPickerExample(), settings: settings),
          description: '日历条选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/image_picker',
          handler: (settings) => RouteHelpers.createRoute(const ImagePickerExample(), settings: settings),
          description: '图片选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/location_picker',
          handler: (settings) => RouteHelpers.createRoute(const LocationPickerExample(), settings: settings),
          description: '位置选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/backup_time_picker',
          handler: (settings) => RouteHelpers.createRoute(const BackupTimePickerExample(), settings: settings),
          description: '备份时间选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/memento_editor',
          handler: (settings) => RouteHelpers.createRoute(const MementoEditorExample(), settings: settings),
          description: '编辑器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/data_selector',
          handler: (settings) => RouteHelpers.createRoute(const DataSelectorExample(), settings: settings),
          description: '数据选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/enhanced_calendar',
          handler: (settings) => RouteHelpers.createRoute(const EnhancedCalendarExample(), settings: settings),
          description: '增强日历示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/group_selector',
          handler: (settings) => RouteHelpers.createRoute(const GroupSelectorExample(), settings: settings),
          description: '分组选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/simple_group_selector',
          handler: (settings) => RouteHelpers.createRoute(const SimpleGroupSelectorExample(), settings: settings),
          description: '简单分组选择器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/tag_manager',
          handler: (settings) => RouteHelpers.createRoute(const TagManagerExample(), settings: settings),
          description: '标签管理器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/statistics',
          handler: (settings) => RouteHelpers.createRoute(const StatisticsExample(), settings: settings),
          description: '统计组件示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/custom_dialog',
          handler: (settings) => RouteHelpers.createRoute(const CustomDialogExample(), settings: settings),
          description: '自定义对话框示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/smooth_bottom_sheet',
          handler: (settings) => RouteHelpers.createRoute(const SmoothBottomSheetExample(), settings: settings),
          description: '底部面板示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/file_preview',
          handler: (settings) => RouteHelpers.createRoute(const FilePreviewExample(), settings: settings),
          description: '文件预览示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/app_drawer',
          handler: (settings) => RouteHelpers.createRoute(const AppDrawerExample(), settings: settings),
          description: '抽屉示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/home_widgets',
          handler: (settings) => RouteHelpers.createRoute(const HomeWidgetsGalleryScreen(), settings: settings),
          description: '桌面小组件示例列表',
        ),
        RouteDefinition(
          path: '/widgets_gallery/all_widgets_preview',
          handler: (settings) {
            final items = settings.arguments as List<WidgetPreviewItem>?;
            return RouteHelpers.createRoute(
              AllWidgetsPreviewPage(widgetItems: items ?? _defaultWidgetItems),
              settings: settings,
            );
          },
          description: '所有小组件预览',
        ),
        RouteDefinition(
          path: '/widgets_gallery/half_circle_gauge_widget',
          handler: (settings) => RouteHelpers.createRoute(const HalfCircleGaugeWidgetExample(), settings: settings),
          description: '半圆仪表盘示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/widget_config_editor',
          handler: (settings) => RouteHelpers.createRoute(const WidgetConfigEditorExample(), settings: settings),
          description: '组件配置编辑器示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/preset_edit_form',
          handler: (settings) => RouteHelpers.createRoute(const PresetEditFormExample(), settings: settings),
          description: '预设编辑表单示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/super_cupertino_navigation',
          handler: (settings) => RouteHelpers.createRoute(const SuperCupertinoNavigationExample(), settings: settings),
          description: '导航示例',
        ),
        RouteDefinition(
          path: '/widgets_gallery/segmented_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const SegmentedProgressCardExample(), settings: settings),
          description: '分段进度条统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/milestone_card',
          handler: (settings) => RouteHelpers.createRoute(const MilestoneCardExample(), settings: settings),
          description: '里程碑追踪卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/circular_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const CircularProgressCardExample(), settings: settings),
          description: '圆形进度卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/monthly_progress_with_dots_card',
          handler: (settings) => RouteHelpers.createRoute(const MonthlyProgressWithDotsCardExample(), settings: settings),
          description: '月度进度圆点卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/multi_metric_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const MultiMetricProgressCardExample(), settings: settings),
          description: '多指标进度卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/line_chart_trend_card',
          handler: (settings) => RouteHelpers.createRoute(const LineChartTrendCardExample(), settings: settings),
          description: '折线图趋势卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/article_list_card',
          handler: (settings) => RouteHelpers.createRoute(const ArticleListCardExample(), settings: settings),
          description: '文章列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/vertical_bar_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const VerticalBarChartCardExample(), settings: settings),
          description: '垂直柱状图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/trend_line_chart_widget',
          handler: (settings) => RouteHelpers.createRoute(const TrendLineChartWidgetExample(), settings: settings),
          description: '趋势折线图',
        ),
        RouteDefinition(
          path: '/widgets_gallery/stacked_bar_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const StackedBarChartCardExample(), settings: settings),
          description: '堆叠柱状图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/stacked_bar_chart_widget',
          handler: (settings) => RouteHelpers.createRoute(const StackedBarChartWidgetExample(), settings: settings),
          description: '堆叠条形图组件',
        ),
        RouteDefinition(
          path: '/widgets_gallery/stacked_ring_chart',
          handler: (settings) => RouteHelpers.createRoute(const StackedRingChartExample(), settings: settings),
          description: '堆叠环形图统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/monthly_bar_chart',
          handler: (settings) => RouteHelpers.createRoute(const MonthlyBarChartExample(), settings: settings),
          description: '月度柱状图统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/earnings_trend_card',
          handler: (settings) => RouteHelpers.createRoute(const EarningsTrendCardExample(), settings: settings),
          description: '收益趋势卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/ranked_bar_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const RankedBarChartCardExample(), settings: settings),
          description: '排名条形图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/smooth_line_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const SmoothLineChartCardExample(), settings: settings),
          description: '平滑折线图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/contribution_heatmap_card',
          handler: (settings) => RouteHelpers.createRoute(const ContributionHeatmapCardExample(), settings: settings),
          description: '贡献热力图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/audio_waveform_widget',
          handler: (settings) => RouteHelpers.createRoute(const AudioWaveformWidgetExample(), settings: settings),
          description: '音频波形小组件',
        ),
        RouteDefinition(
          path: '/widgets_gallery/dual_slider_widget',
          handler: (settings) => RouteHelpers.createRoute(const DualSliderWidgetExample(), settings: settings),
          description: '双滑块小组件',
        ),
        RouteDefinition(
          path: '/widgets_gallery/storage_breakdown_widget',
          handler: (settings) => RouteHelpers.createRoute(const StorageBreakdownWidgetExample(), settings: settings),
          description: '存储分段小组件',
        ),
        RouteDefinition(
          path: '/widgets_gallery/route_tracking_card',
          handler: (settings) => RouteHelpers.createRoute(const RouteTrackingCardExample(), settings: settings),
          description: '运输追踪路线卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/watch_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const WatchProgressCardExample(), settings: settings),
          description: '观看进度卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/bar_chart_stats_card',
          handler: (settings) => RouteHelpers.createRoute(const BarChartStatsCardExample(), settings: settings),
          description: '柱状图统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/activity_progress_card',
      handler:
          (settings) => RouteHelpers.createRoute(
            CardDotProgressDisplayExample(),
            settings: settings,
          ),
          description: '活动进度卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/daily_bar_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const DailyBarChartCardExample(), settings: settings),
          description: '每日条形图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/weekly_bar_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const WeeklyBarChartCardExample(), settings: settings),
          description: '周条形图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/wallet_balance_card',
          handler: (settings) => RouteHelpers.createRoute(const WalletBalanceCardExample(), settings: settings),
          description: '钱包余额概览卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/habit_streak_tracker',
          handler: (settings) => RouteHelpers.createRoute(const HabitStreakTrackerExample(), settings: settings),
          description: '连续打卡追踪器',
        ),
        RouteDefinition(
          path: '/widgets_gallery/music_player_card',
          handler: (settings) => RouteHelpers.createRoute(const MusicPlayerCardExample(), settings: settings),
          description: '音乐播放器卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/event_calendar_widget',
          handler: (settings) => RouteHelpers.createRoute(const EventCalendarWidgetExample(), settings: settings),
          description: '日历事件卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/performance_bar_chart',
          handler: (settings) => RouteHelpers.createRoute(const PerformanceBarChartExample(), settings: settings),
          description: '性能指标柱状图',
        ),
        RouteDefinition(
          path: '/widgets_gallery/expense_donut_chart',
          handler: (settings) => RouteHelpers.createRoute(const ExpenseDonutChartExample(), settings: settings),
          description: '支出分类环形图',
        ),
        RouteDefinition(
          path: '/widgets_gallery/profile_card_widget',
          handler: (settings) => RouteHelpers.createRoute(const ProfileCardWidgetExample(), settings: settings),
          description: '个人资料卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/portfolio_stacked_chart',
          handler: (settings) => RouteHelpers.createRoute(const PortfolioStackedChartExample(), settings: settings),
          description: '投资组合堆叠图',
        ),
        RouteDefinition(
          path: '/widgets_gallery/spending_trend_chart',
          handler: (settings) => RouteHelpers.createRoute(const SpendingTrendChartExample(), settings: settings),
          description: '支出趋势折线图',
        ),
        RouteDefinition(
          path: '/widgets_gallery/blood_pressure_tracker',
          handler: (settings) => RouteHelpers.createRoute(const BloodPressureTrackerExample(), settings: settings),
          description: '血压追踪器',
        ),
        RouteDefinition(
          path: '/widgets_gallery/mood_tracker_widget',
          handler: (settings) => RouteHelpers.createRoute(const MoodTrackerWidgetExample(), settings: settings),
          description: '心情追踪卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/stress_level_monitor',
          handler: (settings) => RouteHelpers.createRoute(const StressLevelMonitorExample(), settings: settings),
          description: '压力水平监测卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/weight_tracking_widget',
          handler: (settings) => RouteHelpers.createRoute(const WeightTrackingWidgetExample(), settings: settings),
          description: '体重追踪柱状图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/daily_todo_list_widget',
          handler: (settings) => RouteHelpers.createRoute(const DailyTodoListWidgetExample(), settings: settings),
          description: '每日待办事项卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/weekly_steps_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const WeeklyStepsProgressCardExample(), settings: settings),
          description: '每周步数进度卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/dual_range_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const DualRangeChartCardExample(), settings: settings),
          description: '双范围图表统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/weekly_dot_tracker_card',
          handler: (settings) => RouteHelpers.createRoute(const WeeklyDotTrackerCardExample(), settings: settings),
          description: '周点阵追踪卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/mini_trend_card',
          handler: (settings) => RouteHelpers.createRoute(const MiniTrendCardExample(), settings: settings),
          description: '迷你趋势卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/daily_events_card',
          handler: (settings) => RouteHelpers.createRoute(const DailyEventsCardExample(), settings: settings),
          description: '日期事件卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/score_card_widget',
          handler: (settings) => RouteHelpers.createRoute(const ScoreCardWidgetExample(), settings: settings),
          description: '分数卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/category_stack_widget',
          handler: (settings) => RouteHelpers.createRoute(const CategoryStackWidgetExample(), settings: settings),
          description: '分类堆叠消费卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/timeline_schedule_card',
          handler: (settings) => RouteHelpers.createRoute(const TimelineScheduleCardExample(), settings: settings),
          description: '时间线日程卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/message_list_card',
          handler: (settings) => RouteHelpers.createRoute(const MessageListCardExample(), settings: settings),
          description: '邮件列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/daily_schedule_card',
          handler: (settings) => RouteHelpers.createRoute(const DailyScheduleCardExample(), settings: settings),
          description: '每日日程卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/expense_comparison_chart',
          handler: (settings) => RouteHelpers.createRoute(const ExpenseComparisonChartExample(), settings: settings),
          description: '支出对比图表',
        ),
        RouteDefinition(
          path: '/widgets_gallery/activity_rings_card',
          handler: (settings) => RouteHelpers.createRoute(const ActivityRingsCardExample(), settings: settings),
          description: '活动圆环卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/weekly_bars_card',
          handler: (settings) => RouteHelpers.createRoute(const WeeklyBarsCardExample(), settings: settings),
          description: '周柱状图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/medication_tracker_widget',
      handler:
          (settings) => RouteHelpers.createRoute(
            const SquarePillProgressCardExample(),
            settings: settings,
          ),
          description: '药物追踪器卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/modern_egfr_health_widget',
      handler:
          (settings) => RouteHelpers.createRoute(
            const ModernFlipCounterCardExample(),
            settings: settings,
          ),
          description: 'eGFR 健康指标卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/modern_rounded_balance_widget',
          handler: (settings) => RouteHelpers.createRoute(const ModernRoundedBalanceWidgetExample(), settings: settings),
          description: '余额卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/dual_bar_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const DualBarChartCardExample(), settings: settings),
          description: '双柱状图统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/timeline_status_card',
          handler: (settings) => RouteHelpers.createRoute(const TimelineStatusCardExample(), settings: settings),
          description: '时间线状态卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/sleep_stage_chart',
          handler: (settings) => RouteHelpers.createRoute(const SleepStageChartExample(), settings: settings),
          description: '睡眠阶段图表',
        ),
        RouteDefinition(
          path: '/widgets_gallery/monthly_bill_card',
          handler: (settings) => RouteHelpers.createRoute(const MonthlyBillCardExample(), settings: settings),
          description: '月度账单卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/task_list_card',
          handler: (settings) => RouteHelpers.createRoute(const TaskListCardExample(), settings: settings),
          description: '任务列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/rounded_task_list_card',
          handler: (settings) => RouteHelpers.createRoute(const RoundedTaskListCardExample(), settings: settings),
          description: '圆角任务列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/upcoming_tasks_widget',
          handler: (settings) => RouteHelpers.createRoute(const UpcomingTasksWidgetExample(), settings: settings),
          description: '即将到来的任务小组件',
        ),
        RouteDefinition(
          path: '/widgets_gallery/journal_prompt_card',
          handler: (settings) => RouteHelpers.createRoute(const JournalPromptCardExample(), settings: settings),
          description: '日记提示卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/sleep_tracking_card',
      handler:
          (settings) => RouteHelpers.createRoute(
            VerticalCircularProgressCardExample(),
            settings: settings,
          ),
          description: '睡眠追踪卡片',
        ),
    RouteDefinition(
          path: '/widgets_gallery/mood_chart_card',
          handler: (settings) => RouteHelpers.createRoute(const MoodChartCardExample(), settings: settings),
          description: '心情图表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/daily_reflection_card',
          handler: (settings) => RouteHelpers.createRoute(const DailyReflectionCardExample(), settings: settings),
          description: '每日反思卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/modern_rounded_mood_widget',
      handler:
          (settings) => RouteHelpers.createRoute(
            const ModernRoundedBarIconCardExample(),
            settings: settings,
          ),
          description: '现代化圆角心情追踪小组件',
        ),
        RouteDefinition(
          path: '/widgets_gallery/modern_rounded_spending_widget',
          handler: (settings) => RouteHelpers.createRoute(const ModernRoundedSpendingWidgetExample(), settings: settings),
          description: '消费卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/hydration_tracker_widget',
          handler: (settings) => RouteHelpers.createRoute(const HydrationTrackerWidgetExample(), settings: settings),
          description: '饮水追踪器',
        ),
        RouteDefinition(
          path: '/widgets_gallery/trend_value_card',
          handler: (settings) => RouteHelpers.createRoute(const TrendValueCardExample(), settings: settings),
          description: '趨勢數值卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/sleep_duration_card',
          handler: (settings) => RouteHelpers.createRoute(const SleepDurationCardExample(), settings: settings),
          description: '睡眠时长统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/weight_trend_chart',
      handler:
          (settings) => RouteHelpers.createRoute(
            CardTrendLineChartExample(),
            settings: settings,
          ),
          description: '体重趋势图表',
        ),
        RouteDefinition(
          path: '/widgets_gallery/account_balance_card',
          handler: (settings) => RouteHelpers.createRoute(const AccountBalanceCardExample(), settings: settings),
          description: '账户余额卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/budget_trend_card',
          handler: (settings) => RouteHelpers.createRoute(const BudgetTrendCardExample(), settings: settings),
          description: '预算趋势卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/multi_metric_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const MultiMetricProgressCardExample(), settings: settings),
          description: '多指标进度跟踪卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/icon_circular_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const IconCircularProgressCardExample(), settings: settings),
          description: '图标圆形进度卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/color_tag_task_card',
          handler: (settings) => RouteHelpers.createRoute(const ColorTagTaskCardExample(), settings: settings),
          description: '彩色标签任务列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/holiday_rental_card',
          handler: (settings) => RouteHelpers.createRoute(const HolidayRentalCardExample(), settings: settings),
          description: '假期租赁卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/donut_chart_stats_card',
          handler: (settings) => RouteHelpers.createRoute(const DonutChartStatsCardExample(), settings: settings),
          description: '甜甜圈图统计卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/inbox_message_card',
          handler: (settings) => RouteHelpers.createRoute(const InboxMessageCardExample(), settings: settings),
          description: '收件箱消息卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/notes_list_card',
          handler: (settings) => RouteHelpers.createRoute(const NotesListCardExample(), settings: settings),
          description: '笔记列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/news_card',
          handler: (settings) => RouteHelpers.createRoute(const NewsCardExample(), settings: settings),
          description: '新闻卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/news_update_card',
          handler: (settings) => RouteHelpers.createRoute(const NewsUpdateCardExample(), settings: settings),
          description: '新闻更新卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/circular_metrics_card',
          handler: (settings) => RouteHelpers.createRoute(const CircularMetricsCardExample(), settings: settings),
          description: '环形指标卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/colorful_shortcuts_grid',
          handler: (settings) => RouteHelpers.createRoute(const ColorfulShortcutsGridExample(), settings: settings),
          description: '彩色快捷方式网格',
        ),
        RouteDefinition(
          path: '/widgets_gallery/rental_preview_card',
          handler: (settings) => RouteHelpers.createRoute(const RentalPreviewCardExample(), settings: settings),
          description: '租赁预览卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/rounded_reminders_list',
          handler: (settings) => RouteHelpers.createRoute(const RoundedRemindersListExample(), settings: settings),
          description: '圆角提醒事项列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/split_image_card',
          handler: (settings) => RouteHelpers.createRoute(const SplitImageCardExample(), settings: settings),
          description: '图片分割卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/social_profile_card',
          handler: (settings) => RouteHelpers.createRoute(const SocialProfileCardExample(), settings: settings),
          description: '社交资料卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/curve_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const CurveProgressCardExample(), settings: settings),
          description: '曲线进度卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/nutrition_progress_card',
      handler:
          (settings) => RouteHelpers.createRoute(
            SplitColumnProgressBarCardExample(),
            settings: settings,
          ),
          description: '营养进度追踪卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/trend_list_card',
          handler: (settings) => RouteHelpers.createRoute(const TrendListCardExample(), settings: settings),
          description: '趋势列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/social_activity_card',
          handler: (settings) => RouteHelpers.createRoute(const SocialActivityCardExample(), settings: settings),
          description: '社交活动动态卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/screen_time_chart',
          handler: (settings) => RouteHelpers.createRoute(const ScreenTimeChartExample(), settings: settings),
          description: '屏幕时间统计图表',
        ),
        RouteDefinition(
          path: '/widgets_gallery/vertical_property_card',
          handler: (settings) => RouteHelpers.createRoute(const VerticalPropertyCardExample(), settings: settings),
          description: '垂直属性卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/task_progress_list_card',
          handler: (settings) => RouteHelpers.createRoute(const TaskProgressListCardExample(), settings: settings),
          description: '任务进度列表卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/vertical_bar_chart_widget',
          handler: (settings) => RouteHelpers.createRoute(const VerticalBarChartExample(), settings: settings),
          description: '垂直条形图卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/rounded_task_progress_widget',
          handler: (settings) => RouteHelpers.createRoute(const RoundedTaskProgressWidgetExample(), settings: settings),
          description: '圆角任务进度小组件',
        ),
        RouteDefinition(
          path: '/widgets_gallery/weather_forecast_card',
          handler: (settings) => RouteHelpers.createRoute(const WeatherForecastCardExample(), settings: settings),
          description: '天气预报卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/task_progress_card',
          handler: (settings) => RouteHelpers.createRoute(const TaskProgressCardExample(), settings: settings),
          description: '任务进度卡片',
        ),
        RouteDefinition(
          path: '/widgets_gallery/task_list_stat_card',
          handler: (settings) => RouteHelpers.createRoute(const TaskListStatCardExample(), settings: settings),
          description: '任务统计列表卡片',
        ),
      ];
}

/// 默认的小组件预览项列表
final List<WidgetPreviewItem> _defaultWidgetItems = [
  // 进度类
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.speed,
    title: '半圆仪表盘',
    subtitle: 'HalfCircleGaugeWidget',
    route: '/widgets_gallery/half_circle_gauge_widget',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.bar_chart,
    title: '分段进度条卡片',
    subtitle: 'SegmentedProgressCard',
    route: '/widgets_gallery/segmented_progress_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.donut_large,
    title: '圆形进度卡片',
    subtitle: 'CircularProgressCard',
    route: '/widgets_gallery/circular_progress_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.dashboard,
    title: '多指标进度卡片',
    subtitle: 'MultiMetricProgressCard',
    route: '/widgets_gallery/multi_metric_progress_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.pie_chart,
    title: '任务进度卡片',
    subtitle: 'TaskProgressCard',
    route: '/widgets_gallery/task_progress_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.donut_large,
    title: '环形指标卡片',
    subtitle: 'CircularMetricsCard',
    route: '/widgets_gallery/circular_metrics_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.show_chart,
    title: '曲线进度卡片',
    subtitle: 'CurveProgressCard',
    route: '/widgets_gallery/curve_progress_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.all_inclusive,
    title: '活动圆环卡片',
    subtitle: 'ActivityRingsCard',
    route: '/widgets_gallery/activity_rings_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.calendar_month,
    title: '月度进度圆点卡片',
    subtitle: 'MonthlyProgressWithDotsCard',
    route: '/widgets_gallery/monthly_progress_with_dots_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.trip_origin,
    title: '图标圆形进度卡片',
    subtitle: 'IconCircularProgressCard',
    route: '/widgets_gallery/icon_circular_progress_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.restaurant,
    title: '营养进度卡片',
    subtitle: 'NutritionProgressCard',
    route: '/widgets_gallery/nutrition_progress_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.task_alt,
    title: '任务进度列表卡片',
    subtitle: 'TaskProgressListCard',
    route: '/widgets_gallery/task_progress_list_card',
  ),
  WidgetPreviewItem(
    category: '进度类',
    icon: Icons.task_alt,
    title: '圆角任务进度小组件',
    subtitle: 'RoundedTaskProgressWidget',
    route: '/widgets_gallery/rounded_task_progress_widget',
  ),
  // 追踪类
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.flag,
    title: '里程碑追踪卡片',
    subtitle: 'MilestoneCard',
    route: '/widgets_gallery/milestone_card',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.play_circle,
    title: '观看进度卡片',
    subtitle: 'WatchProgressCard',
    route: '/widgets_gallery/watch_progress_card',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.sentiment_satisfied,
    title: '心情追踪卡片',
    subtitle: 'MoodTrackerWidget',
    route: '/widgets_gallery/mood_tracker_widget',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.sentiment_satisfied_alt,
    title: '心情图表卡片',
    subtitle: 'MoodChartCard',
    route: '/widgets_gallery/mood_chart_card',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.psychology,
    title: '压力水平监测卡片',
    subtitle: 'StressLevelMonitor',
    route: '/widgets_gallery/stress_level_monitor',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.bedtime_outlined,
    title: '睡眠追踪卡片',
    subtitle: 'SleepTrackingCard',
    route: '/widgets_gallery/sleep_tracking_card',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.bed,
    title: '睡眠时长统计卡片',
    subtitle: 'SleepDurationCard',
    route: '/widgets_gallery/sleep_duration_card',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.bedtime_rounded,
    title: '周睡眠追踪小组件',
    subtitle: 'WeeklySleepTrackerWidget',
    route: '/widgets_gallery/weekly_sleep_tracker',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.science,
    title: 'eGFR 健康指标卡片',
    subtitle: 'ModernEgfrHealthWidget',
    route: '/widgets_gallery/modern_egfr_health_widget',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.medication,
    title: '药物追踪器卡片',
    subtitle: 'MedicationTrackerWidget',
    route: '/widgets_gallery/medication_tracker_widget',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.water_drop,
    title: '饮水追踪器',
    subtitle: 'HydrationTrackerWidget',
    route: '/widgets_gallery/hydration_tracker_widget',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.monitor_weight,
    title: '体重追踪柱状图卡片',
    subtitle: 'WeightTrackingCard',
    route: '/widgets_gallery/weight_tracking_widget',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.favorite,
    title: '血压追踪器',
    subtitle: 'BloodPressureTracker',
    route: '/widgets_gallery/blood_pressure_tracker',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.directions_run,
    title: '活动进度卡片',
    subtitle: 'ActivityProgressCard',
    route: '/widgets_gallery/activity_progress_card',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.local_fire_department,
    title: '连续打卡追踪器',
    subtitle: 'HabitStreakTracker',
    route: '/widgets_gallery/habit_streak_tracker',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.directions_walk,
    title: '每周步数进度卡片',
    subtitle: 'WeeklyStepsProgressCard',
    route: '/widgets_gallery/weekly_steps_progress_card',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.route,
    title: '运输追踪路线卡片',
    subtitle: 'RouteTrackingCard',
    route: '/widgets_gallery/route_tracking_card',
  ),
  WidgetPreviewItem(
    category: '追踪类',
    icon: Icons.donut_large,
    title: '周点阵追踪卡片',
    subtitle: 'WeeklyDotTrackerCard',
    route: '/widgets_gallery/weekly_dot_tracker_card',
  ),
  // 日历类
  WidgetPreviewItem(
    category: '日历类',
    icon: Icons.event,
    title: '日历事件卡片',
    subtitle: 'EventCalendarWidget',
    route: '/widgets_gallery/event_calendar_widget',
  ),
  WidgetPreviewItem(
    category: '日历类',
    icon: Icons.event,
    title: '日期事件卡片',
    subtitle: 'DailyEventsCard',
    route: '/widgets_gallery/daily_events_card',
  ),
  WidgetPreviewItem(
    category: '日历类',
    icon: Icons.today,
    title: '每日日程卡片',
    subtitle: 'DailyScheduleCard',
    route: '/widgets_gallery/daily_schedule_card',
  ),
  WidgetPreviewItem(
    category: '日历类',
    icon: Icons.schedule,
    title: '时间线日程卡片',
    subtitle: 'TimelineScheduleCard',
    route: '/widgets_gallery/timeline_schedule_card',
  ),
  WidgetPreviewItem(
    category: '日历类',
    icon: Icons.menu_book,
    title: '日记提示卡片',
    subtitle: 'JournalPromptCard',
    route: '/widgets_gallery/journal_prompt_card',
  ),
  WidgetPreviewItem(
    category: '日历类',
    icon: Icons.psychology_rounded,
    title: '每日反思卡片',
    subtitle: 'DailyReflectionCard',
    route: '/widgets_gallery/daily_reflection_card',
  ),
  // 图表类
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.show_chart,
    title: '折线图趋势卡片',
    subtitle: 'LineChartTrendCard',
    route: '/widgets_gallery/line_chart_trend_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.thermostat,
    title: '趋势折线图',
    subtitle: 'TrendLineChartWidget',
    route: '/widgets_gallery/trend_line_chart_widget',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.show_chart,
    title: '平滑折线图卡片',
    subtitle: 'SmoothLineChartCard',
    route: '/widgets_gallery/smooth_line_chart_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '垂直柱状图卡片',
    subtitle: 'VerticalBarChartCard',
    route: '/widgets_gallery/vertical_bar_chart_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.layers,
    title: '堆叠柱状图卡片',
    subtitle: 'StackedBarChartCard',
    route: '/widgets_gallery/stacked_bar_chart_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '堆叠条形图组件',
    subtitle: 'StackedBarChartWidget',
    route: '/widgets_gallery/stacked_bar_chart_widget',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.donut_large,
    title: '堆叠环形图统计卡片',
    subtitle: 'StackedRingChartWidget',
    route: '/widgets_gallery/stacked_ring_chart',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.calendar_view_month,
    title: '月度柱状图统计卡片',
    subtitle: 'MonthlyBarChartWidget',
    route: '/widgets_gallery/monthly_bar_chart',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '排名条形图卡片',
    subtitle: 'RankedBarChartCard',
    route: '/widgets_gallery/ranked_bar_chart_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.grid_on,
    title: '贡献热力图卡片',
    subtitle: 'ContributionHeatmapCard',
    route: '/widgets_gallery/contribution_heatmap_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '柱状图统计卡片',
    subtitle: 'BarChartStatsCard',
    route: '/widgets_gallery/bar_chart_stats_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '每日条形图卡片',
    subtitle: 'DailyBarChartCard',
    route: '/widgets_gallery/daily_bar_chart_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.calendar_view_week,
    title: '周条形图卡片',
    subtitle: 'WeeklyBarChartCard',
    route: '/widgets_gallery/weekly_bar_chart_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '双范围图表统计卡片',
    subtitle: 'DualRangeChartCard',
    route: '/widgets_gallery/dual_range_chart_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.donut_large,
    title: '甜甜圈图统计卡片',
    subtitle: 'DonutChartStatsCard',
    route: '/widgets_gallery/donut_chart_stats_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.trending_up,
    title: '迷你趋势卡片',
    subtitle: 'MiniTrendCard',
    route: '/widgets_gallery/mini_trend_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.trending_up,
    title: '趨勢數值卡片',
    subtitle: 'TrendValueCard',
    route: '/widgets_gallery/trend_value_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.trending_up,
    title: '趋势列表卡片',
    subtitle: 'TrendListCard',
    route: '/widgets_gallery/trend_list_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.monitor_weight,
    title: '体重趋势图表',
    subtitle: 'WeightTrendChartWidget',
    route: '/widgets_gallery/weight_trend_chart',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '双柱状图统计卡片',
    subtitle: 'DualBarChartCard',
    route: '/widgets_gallery/dual_bar_chart_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.view_column,
    title: '周柱状图卡片',
    subtitle: 'WeeklyBarsCard',
    route: '/widgets_gallery/weekly_bars_card',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '屏幕时间统计图表',
    subtitle: 'ScreenTimeChartWidget',
    route: '/widgets_gallery/screen_time_chart',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '垂直条形图卡片',
    subtitle: 'VerticalBarChartWidget',
    route: '/widgets_gallery/vertical_bar_chart_widget',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bedtime,
    title: '睡眠阶段图表',
    subtitle: 'SleepStageChart',
    route: '/widgets_gallery/sleep_stage_chart',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.bar_chart,
    title: '性能指标柱状图',
    subtitle: 'PerformanceBarChart',
    route: '/widgets_gallery/performance_bar_chart',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.pie_chart,
    title: '投资组合堆叠图',
    subtitle: 'PortfolioStackedChart',
    route: '/widgets_gallery/portfolio_stacked_chart',
  ),
  WidgetPreviewItem(
    category: '图表类',
    icon: Icons.monetization_on,
    title: '收入趋势卡片',
    subtitle: 'RevenueTrendCard',
    route: '/widgets_gallery/revenue_trend_card',
  ),
  // 内容类
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.article,
    title: '文章列表卡片',
    subtitle: 'ArticleListCard',
    route: '/widgets_gallery/article_list_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.check_circle_outline,
    title: '任务列表卡片',
    subtitle: 'TaskListCard',
    route: '/widgets_gallery/task_list_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.notes,
    title: '笔记列表卡片',
    subtitle: 'NotesListCard',
    route: '/widgets_gallery/notes_list_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.person,
    title: '个人资料卡片',
    subtitle: 'ProfileCardWidget',
    route: '/widgets_gallery/profile_card_widget',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.crop_free,
    title: '图片分割卡片',
    subtitle: 'SplitImageCard',
    route: '/widgets_gallery/split_image_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.update,
    title: '新闻更新卡片',
    subtitle: 'NewsUpdateCard',
    route: '/widgets_gallery/news_update_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.newspaper,
    title: '新闻卡片',
    subtitle: 'NewsCard',
    route: '/widgets_gallery/news_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.label_outline,
    title: '彩色标签任务列表卡片',
    subtitle: 'ColorTagTaskCard',
    route: '/widgets_gallery/color_tag_task_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.hotel,
    title: '假期租赁卡片',
    subtitle: 'HolidayRentalCard',
    route: '/widgets_gallery/holiday_rental_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.home_work,
    title: '租赁预览卡片',
    subtitle: 'RentalPreviewCard',
    route: '/widgets_gallery/rental_preview_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.inbox,
    title: '收件箱消息卡片',
    subtitle: 'InboxMessageCard',
    route: '/widgets_gallery/inbox_message_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.mail,
    title: '邮件列表卡片',
    subtitle: 'MessageListCard',
    route: '/widgets_gallery/message_list_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.event_available,
    title: '即将到来的任务小组件',
    subtitle: 'UpcomingTasksWidget',
    route: '/widgets_gallery/upcoming_tasks_widget',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.person_outline,
    title: '社交资料卡片',
    subtitle: 'SocialProfileCard',
    route: '/widgets_gallery/social_profile_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.forum_outlined,
    title: '社交活动动态卡片',
    subtitle: 'SocialActivityCard',
    route: '/widgets_gallery/social_activity_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.image,
    title: '垂直属性卡片',
    subtitle: 'VerticalPropertyCard',
    route: '/widgets_gallery/vertical_property_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.task_alt,
    title: '圆角任务列表卡片',
    subtitle: 'RoundedTaskListCard',
    route: '/widgets_gallery/rounded_task_list_card',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.check_circle,
    title: '每日待办事项卡片',
    subtitle: 'DailyTodoListWidget',
    route: '/widgets_gallery/daily_todo_list_widget',
  ),
  WidgetPreviewItem(
    category: '内容类',
    icon: Icons.notification_important,
    title: '圆角提醒事项列表卡片',
    subtitle: 'RoundedRemindersList',
    route: '/widgets_gallery/rounded_reminders_list',
  ),
  // 财务类
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.trending_up,
    title: '收益趋势卡片',
    subtitle: 'EarningsTrendCard',
    route: '/widgets_gallery/earnings_trend_card',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.show_chart,
    title: '支出趋势折线图',
    subtitle: 'SpendingTrendChart',
    route: '/widgets_gallery/spending_trend_chart',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.bar_chart,
    title: '支出对比图表',
    subtitle: 'ExpenseComparisonChart',
    route: '/widgets_gallery/expense_comparison_chart',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.payments_rounded,
    title: '消费卡片',
    subtitle: 'ModernRoundedSpendingWidget',
    route: '/widgets_gallery/modern_rounded_spending_widget',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.account_balance_wallet,
    title: '预算趋势卡片',
    subtitle: 'BudgetTrendCardWidget',
    route: '/widgets_gallery/budget_trend_card',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.account_balance,
    title: '账户余额卡片',
    subtitle: 'AccountBalanceCard',
    route: '/widgets_gallery/account_balance_card',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.bar_chart,
    title: '分类堆叠消费卡片',
    subtitle: 'CategoryStackWidget',
    route: '/widgets_gallery/category_stack_widget',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.account_balance_wallet,
    title: '钱包余额概览卡片',
    subtitle: 'WalletBalanceCard',
    route: '/widgets_gallery/wallet_balance_card',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.account_balance_wallet,
    title: '余额卡片',
    subtitle: 'ModernRoundedBalanceWidget',
    route: '/widgets_gallery/modern_rounded_balance_widget',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.receipt_long,
    title: '月度账单卡片',
    subtitle: 'MonthlyBillCard',
    route: '/widgets_gallery/monthly_bill_card',
  ),
  WidgetPreviewItem(
    category: '财务类',
    icon: Icons.donut_large,
    title: '支出分类环形图',
    subtitle: 'ExpenseDonutChart',
    route: '/widgets_gallery/expense_donut_chart',
  ),
  // 媒体类
  WidgetPreviewItem(
    category: '媒体类',
    icon: Icons.graphic_eq,
    title: '音频波形小组件',
    subtitle: 'AudioWaveformWidget',
    route: '/widgets_gallery/audio_waveform_widget',
  ),
  WidgetPreviewItem(
    category: '媒体类',
    icon: Icons.music_note,
    title: '音乐播放器卡片',
    subtitle: 'MusicPlayerCard',
    route: '/widgets_gallery/music_player_card',
  ),
  // 工具类
  WidgetPreviewItem(
    category: '工具类',
    icon: Icons.access_time,
    title: '双滑块小组件',
    subtitle: 'DualSliderWidget',
    route: '/widgets_gallery/dual_slider_widget',
  ),
  WidgetPreviewItem(
    category: '工具类',
    icon: Icons.scoreboard,
    title: '分数卡片',
    subtitle: 'ScoreCardWidget',
    route: '/widgets_gallery/score_card_widget',
  ),
  WidgetPreviewItem(
    category: '工具类',
    icon: Icons.apps,
    title: '彩色快捷方式网格',
    subtitle: 'ColorfulShortcutsGrid',
    route: '/widgets_gallery/colorful_shortcuts_grid',
  ),
  WidgetPreviewItem(
    category: '工具类',
    icon: Icons.wb_sunny,
    title: '天气预报卡片',
    subtitle: 'WeatherForecastCard',
    route: '/widgets_gallery/weather_forecast_card',
  ),
  WidgetPreviewItem(
    category: '工具类',
    icon: Icons.timeline,
    title: '时间线状态卡片',
    subtitle: 'TimelineStatusCard',
    route: '/widgets_gallery/timeline_status_card',
  ),
  WidgetPreviewItem(
    category: '工具类',
    icon: Icons.storage,
    title: '存储分段小组件',
    subtitle: 'StorageBreakdownWidget',
    route: '/widgets_gallery/storage_breakdown_widget',
  ),
];
