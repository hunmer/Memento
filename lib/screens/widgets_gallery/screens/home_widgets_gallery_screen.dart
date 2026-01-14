import 'package:flutter/material.dart';

/// 桌面小组件展示列表页
class HomeWidgetsGalleryScreen extends StatelessWidget {
  const HomeWidgetsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('桌面小组件示例')),
      body: ListView(
        children: [
          // 进度类
          ..._buildProgressSection(context),
          // 追踪类
          ..._buildTrackingSection(context),
          // 日历类
          ..._buildCalendarSection(context),
          // 图表类
          ..._buildChartSection(context),
          // 内容类
          ..._buildContentSection(context),
          // 财务类
          ..._buildFinanceSection(context),
          // 媒体类
          ..._buildMediaSection(context),
          // 工具类
          ..._buildUtilitySection(context),
        ],
      ),
    );
  }

  // 进度类组件
  List<Widget> _buildProgressSection(BuildContext context) {
    return [
      _buildSectionHeader(context, '进度类 - 显示各类进度和完成度'),
      _buildListItem(
        context,
        icon: Icons.speed,
        title: '半圆仪表盘',
        subtitle: 'HalfCircleGaugeWidget - 半圆形进度仪表盘',
        route: '/widgets_gallery/half_circle_gauge_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '分段进度条卡片',
        subtitle: 'SegmentedProgressCard - 多类别分段统计卡片',
        route: '/widgets_gallery/segmented_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.donut_large,
        title: '圆形进度卡片',
        subtitle: 'CircularProgressCard - 圆形进度展示卡片',
        route: '/widgets_gallery/circular_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.dashboard,
        title: '多指标进度卡片',
        subtitle: 'MultiMetricProgressCard - 多指标进度展示卡片',
        route: '/widgets_gallery/multi_metric_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.pie_chart,
        title: '任务进度卡片',
        subtitle: 'TaskProgressCard - 任务完成进度与待办事项卡片',
        route: '/widgets_gallery/task_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.donut_large,
        title: '环形指标卡片',
        subtitle: 'CircularMetricsCard - 多指标环形进度展示卡片',
        route: '/widgets_gallery/circular_metrics_card',
      ),
      _buildListItem(
        context,
        icon: Icons.show_chart,
        title: '曲线进度卡片',
        subtitle: 'CurveProgressCard - 带曲线图的进度统计卡片',
        route: '/widgets_gallery/curve_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.all_inclusive,
        title: '活动圆环卡片',
        subtitle: 'ActivityRingsCard - 活动进度圆环展示卡片',
        route: '/widgets_gallery/activity_rings_card',
      ),
      _buildListItem(
        context,
        icon: Icons.calendar_month,
        title: '月度进度圆点卡片',
        subtitle: 'MonthlyProgressWithDotsCard - 圆点矩阵月度进度卡片',
        route: '/widgets_gallery/monthly_progress_with_dots_card',
      ),
      _buildListItem(
        context,
        icon: Icons.trip_origin,
        title: '图标圆形进度卡片',
        subtitle: 'IconCircularProgressCard - 带图标和通知点的圆形进度卡片',
        route: '/widgets_gallery/icon_circular_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.restaurant,
        title: '营养进度卡片',
        subtitle: 'NutritionProgressCard - 卡路里与营养素追踪卡片',
        route: '/widgets_gallery/nutrition_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.task_alt,
        title: '任务进度列表卡片',
        subtitle: 'TaskProgressListCard - 带进度条的任务列表展示卡片',
        route: '/widgets_gallery/task_progress_list_card',
      ),
      _buildListItem(
        context,
        icon: Icons.task_alt,
        title: '圆角任务进度小组件',
        subtitle: 'RoundedTaskProgressWidget - 圆角风格的任务进度展示小组件',
        route: '/widgets_gallery/rounded_task_progress_widget',
      ),
    ];
  }

  // 追踪类组件
  List<Widget> _buildTrackingSection(BuildContext context) {
    return [
      _buildSectionHeader(context, '追踪类 - 习惯、活动追踪'),
      _buildListItem(
        context,
        icon: Icons.flag,
        title: '里程碑追踪卡片',
        subtitle: 'MilestoneCard - 时间里程碑追踪展示卡片',
        route: '/widgets_gallery/milestone_card',
      ),
      _buildListItem(
        context,
        icon: Icons.play_circle,
        title: '观看进度卡片',
        subtitle: 'WatchProgressCard - 观看进度与历史记录展示卡片',
        route: '/widgets_gallery/watch_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.sentiment_satisfied,
        title: '心情追踪卡片',
        subtitle: 'MoodTrackerWidget - 每周心情记录与统计卡片',
        route: '/widgets_gallery/mood_tracker_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.sentiment_satisfied_alt,
        title: '心情图表卡片',
        subtitle: 'MoodChartCard - 情绪柱状图与表情历史追踪卡片',
        route: '/widgets_gallery/mood_chart_card',
      ),
      _buildListItem(
        context,
        icon: Icons.psychology,
        title: '压力水平监测卡片',
        subtitle: 'StressLevelMonitor - 压力分数与每周趋势追踪',
        route: '/widgets_gallery/stress_level_monitor',
      ),
      _buildListItem(
        context,
        icon: Icons.bedtime_outlined,
        title: '睡眠追踪卡片',
        subtitle: 'SleepTrackingCard - 睡眠时长与周日程追踪卡片',
        route: '/widgets_gallery/sleep_tracking_card',
      ),
      _buildListItem(
        context,
        icon: Icons.bed,
        title: '睡眠时长统计卡片',
        subtitle: 'SleepDurationCard - 睡眠时长与周期可视化展示卡片',
        route: '/widgets_gallery/sleep_duration_card',
      ),
      _buildListItem(
        context,
        icon: Icons.bedtime_rounded,
        title: '周睡眠追踪小组件',
        subtitle: 'WeeklySleepTrackerWidget - 7天睡眠进度环与状态追踪卡片',
        route: '/widgets_gallery/weekly_sleep_tracker',
      ),
      _buildListItem(
        context,
        icon: Icons.science,
        title: 'eGFR 健康指标卡片',
        subtitle: 'ModernEgfrHealthWidget - 肾功能指标健康监测卡片',
        route: '/widgets_gallery/modern_egfr_health_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.medication,
        title: '药物追踪器卡片',
        subtitle: 'MedicationTrackerWidget - 药物进度追踪展示卡片',
        route: '/widgets_gallery/medication_tracker_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.water_drop,
        title: '饮水追踪器',
        subtitle: 'HydrationTrackerWidget - 每日饮水量追踪与连续打卡',
        route: '/widgets_gallery/hydration_tracker_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.monitor_weight,
        title: '体重追踪柱状图卡片',
        subtitle: 'WeightTrackingCard - 体重数据追踪与目标警戒线展示',
        route: '/widgets_gallery/weight_tracking_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.favorite,
        title: '血压追踪器',
        subtitle: 'BloodPressureTracker - 血压数值与周趋势展示卡片',
        route: '/widgets_gallery/blood_pressure_tracker',
      ),
      _buildListItem(
        context,
        icon: Icons.directions_run,
        title: '活动进度卡片',
        subtitle: 'ActivityProgressCard - 活动里程进度与点状进度卡片',
        route: '/widgets_gallery/activity_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.local_fire_department,
        title: '连续打卡追踪器',
        subtitle: 'HabitStreakTracker - 连续打卡天数追踪展示组件',
        route: '/widgets_gallery/habit_streak_tracker',
      ),
      _buildListItem(
        context,
        icon: Icons.directions_walk,
        title: '每周步数进度卡片',
        subtitle: 'WeeklyStepsProgressCard - 每周步数柱状图统计卡片',
        route: '/widgets_gallery/weekly_steps_progress_card',
      ),
      _buildListItem(
        context,
        icon: Icons.route,
        title: '运输追踪路线卡片',
        subtitle: 'RouteTrackingCard - 路线追踪运输状态展示卡片',
        route: '/widgets_gallery/route_tracking_card',
      ),
      _buildListItem(
        context,
        icon: Icons.donut_large,
        title: '周点阵追踪卡片',
        subtitle: 'WeeklyDotTrackerCard - 周进度点阵追踪展示卡片',
        route: '/widgets_gallery/weekly_dot_tracker_card',
      ),
    ];
  }

  // 日历类组件
  List<Widget> _buildCalendarSection(BuildContext context) {
    return [
      _buildSectionHeader(context, '日历类 - 日历、时间相关'),
      _buildListItem(
        context,
        icon: Icons.event,
        title: '日历事件卡片',
        subtitle: 'EventCalendarWidget - 日历事件周视图与提醒卡片',
        route: '/widgets_gallery/event_calendar_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.event,
        title: '日期事件卡片',
        subtitle: 'DailyEventsCard - 显示日期和彩色事件列表卡片',
        route: '/widgets_gallery/daily_events_card',
      ),
      _buildListItem(
        context,
        icon: Icons.today,
        title: '每日日程卡片',
        subtitle: 'DailyScheduleCard - 每日活动日程展示卡片',
        route: '/widgets_gallery/daily_schedule_card',
      ),
      _buildListItem(
        context,
        icon: Icons.schedule,
        title: '时间线日程卡片',
        subtitle: 'TimelineScheduleCard - 双日时间线日程展示卡片',
        route: '/widgets_gallery/timeline_schedule_card',
      ),
      _buildListItem(
        context,
        icon: Icons.menu_book,
        title: '日记提示卡片',
        subtitle: 'JournalPromptCard - 日记提示问题与快捷操作卡片',
        route: '/widgets_gallery/journal_prompt_card',
      ),
      _buildListItem(
        context,
        icon: Icons.psychology_rounded,
        title: '每日反思卡片',
        subtitle: 'DailyReflectionCard - 每日反思引导问题与操作卡片',
        route: '/widgets_gallery/daily_reflection_card',
      ),
    ];
  }

  // 图表类组件
  List<Widget> _buildChartSection(BuildContext context) {
    return [
      _buildSectionHeader(context, '图表类 - 数据可视化图表'),
      _buildListItem(
        context,
        icon: Icons.show_chart,
        title: '折线图趋势卡片',
        subtitle: 'LineChartTrendCard - 折线图趋势统计卡片',
        route: '/widgets_gallery/line_chart_trend_card',
      ),
      _buildListItem(
        context,
        icon: Icons.thermostat,
        title: '趋势折线图',
        subtitle: 'TrendLineChartWidget - 平滑曲线趋势展示组件',
        route: '/widgets_gallery/trend_line_chart_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.show_chart,
        title: '平滑折线图卡片',
        subtitle: 'SmoothLineChartCard - 带渐变填充的平滑折线图卡片',
        route: '/widgets_gallery/smooth_line_chart_card',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '垂直柱状图卡片',
        subtitle: 'VerticalBarChartCard - 垂直柱状图统计卡片',
        route: '/widgets_gallery/vertical_bar_chart_card',
      ),
      _buildListItem(
        context,
        icon: Icons.layers,
        title: '堆叠柱状图卡片',
        subtitle: 'StackedBarChartCard - 多年份数据堆叠对比卡片',
        route: '/widgets_gallery/stacked_bar_chart_card',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '堆叠条形图组件',
        subtitle: 'StackedBarChartWidget - 三层堆叠条形图展示组件',
        route: '/widgets_gallery/stacked_bar_chart_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.donut_large,
        title: '堆叠环形图统计卡片',
        subtitle: 'StackedRingChartWidget - 多类别环形图统计卡片',
        route: '/widgets_gallery/stacked_ring_chart',
      ),
      _buildListItem(
        context,
        icon: Icons.calendar_view_month,
        title: '月度柱状图统计卡片',
        subtitle: 'MonthlyBarChartWidget - 12个月数据柱状图展示',
        route: '/widgets_gallery/monthly_bar_chart',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '排名条形图卡片',
        subtitle: 'RankedBarChartCard - 水平排名条形图展示卡片',
        route: '/widgets_gallery/ranked_bar_chart_card',
      ),
      _buildListItem(
        context,
        icon: Icons.grid_on,
        title: '贡献热力图卡片',
        subtitle: 'ContributionHeatmapCard - 活跃度热力图网格展示卡片',
        route: '/widgets_gallery/contribution_heatmap_card',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '柱状图统计卡片',
        subtitle: 'BarChartStatsCard - 柱状图数据统计展示卡片',
        route: '/widgets_gallery/bar_chart_stats_card',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '每日条形图卡片',
        subtitle: 'DailyBarChartCard - 多日数据条形图展示卡片',
        route: '/widgets_gallery/daily_bar_chart_card',
      ),
      _buildListItem(
        context,
        icon: Icons.calendar_view_week,
        title: '周条形图卡片',
        subtitle: 'WeeklyBarChartCard - 一周数据堆叠条形图展示卡片',
        route: '/widgets_gallery/weekly_bar_chart_card',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '双范围图表统计卡片',
        subtitle: 'DualRangeChartCard - 双数值范围周统计图表卡片',
        route: '/widgets_gallery/dual_range_chart_card',
      ),
      _buildListItem(
        context,
        icon: Icons.donut_large,
        title: '甜甜圈图统计卡片',
        subtitle: 'DonutChartStatsCard - 环形分布图与分类列表展示卡片',
        route: '/widgets_gallery/donut_chart_stats_card',
      ),
      _buildListItem(
        context,
        icon: Icons.trending_up,
        title: '迷你趋势卡片',
        subtitle: 'MiniTrendCard - 迷你折线图趋势展示卡片',
        route: '/widgets_gallery/mini_trend_card',
      ),
      _buildListItem(
        context,
        icon: Icons.trending_up,
        title: '趨勢數值卡片',
        subtitle: 'TrendValueCard - 带曲线图表的趋势数值展示卡片',
        route: '/widgets_gallery/trend_value_card',
      ),
      _buildListItem(
        context,
        icon: Icons.trending_up,
        title: '趋势列表卡片',
        subtitle: 'TrendListCard - 股票/指数价格与涨跌幅列表卡片',
        route: '/widgets_gallery/trend_list_card',
      ),
      _buildListItem(
        context,
        icon: Icons.monitor_weight,
        title: '体重趋势图表',
        subtitle: 'WeightTrendChartWidget - 体重趋势折线图展示卡片',
        route: '/widgets_gallery/weight_trend_chart',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '双柱状图统计卡片',
        subtitle: 'DualBarChartCard - 双数值柱状图对比展示卡片',
        route: '/widgets_gallery/dual_bar_chart_card',
      ),
      _buildListItem(
        context,
        icon: Icons.view_column,
        title: '周柱状图卡片',
        subtitle: 'WeeklyBarsCard - 周数据柱状图统计卡片',
        route: '/widgets_gallery/weekly_bars_card',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '屏幕时间统计图表',
        subtitle: 'ScreenTimeChartWidget - 堆叠柱状图展示屏幕使用时间',
        route: '/widgets_gallery/screen_time_chart',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '垂直条形图卡片',
        subtitle: 'VerticalBarChartWidget - 天气预报垂直条形图展示卡片',
        route: '/widgets_gallery/vertical_bar_chart_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.bedtime,
        title: '睡眠阶段图表',
        subtitle: 'SleepStageChart - 睡眠阶段气泡可视化图表',
        route: '/widgets_gallery/sleep_stage_chart',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '性能指标柱状图',
        subtitle: 'PerformanceBarChart - 增长数据柱状图展示组件',
        route: '/widgets_gallery/performance_bar_chart',
      ),
      _buildListItem(
        context,
        icon: Icons.pie_chart,
        title: '投资组合堆叠图',
        subtitle: 'PortfolioStackedChart - 资产配置堆叠柱状图',
        route: '/widgets_gallery/portfolio_stacked_chart',
      ),
      _buildListItem(
        context,
        icon: Icons.monetization_on,
        title: '收入趋势卡片',
        subtitle: 'RevenueTrendCard - 圆角收入趋势曲线图表卡片',
        route: '/widgets_gallery/revenue_trend_card',
      ),
    ];
  }

  // 内容类组件
  List<Widget> _buildContentSection(BuildContext context) {
    return [
      _buildSectionHeader(context, '内容类 - 文章、笔记等内容展示'),
      _buildListItem(
        context,
        icon: Icons.article,
        title: '文章列表卡片',
        subtitle: 'ArticleListCard - 文章内容展示列表卡片',
        route: '/widgets_gallery/article_list_card',
      ),
      _buildListItem(
        context,
        icon: Icons.check_circle_outline,
        title: '任务列表卡片',
        subtitle: 'TaskListCard - 任务清单与计数展示卡片',
        route: '/widgets_gallery/task_list_card',
      ),
      _buildListItem(
        context,
        icon: Icons.notes,
        title: '笔记列表卡片',
        subtitle: 'NotesListCard - 笔记列表展示卡片',
        route: '/widgets_gallery/notes_list_card',
      ),
      _buildListItem(
        context,
        icon: Icons.person,
        title: '个人资料卡片',
        subtitle: 'ProfileCardWidget - 个人信息展示资料卡片',
        route: '/widgets_gallery/profile_card_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.crop_free,
        title: '图片分割卡片',
        subtitle: 'SplitImageCard - 左右分屏布局的图片展示卡片',
        route: '/widgets_gallery/split_image_card',
      ),
      _buildListItem(
        context,
        icon: Icons.update,
        title: '新闻更新卡片',
        subtitle: 'NewsUpdateCard - 带分页指示器的新闻更新展示卡片',
        route: '/widgets_gallery/news_update_card',
      ),
      _buildListItem(
        context,
        icon: Icons.newspaper,
        title: '新闻卡片',
        subtitle: 'NewsCard - 头条新闻与列表展示卡片',
        route: '/widgets_gallery/news_card',
      ),
      _buildListItem(
        context,
        icon: Icons.label_outline,
        title: '彩色标签任务列表卡片',
        subtitle: 'ColorTagTaskCard - 彩色标签条的任务列表卡片',
        route: '/widgets_gallery/color_tag_task_card',
      ),
      _buildListItem(
        context,
        icon: Icons.hotel,
        title: '假期租赁卡片',
        subtitle: 'HolidayRentalCard - 图片+信息的假期租赁展示卡片',
        route: '/widgets_gallery/holiday_rental_card',
      ),
      _buildListItem(
        context,
        icon: Icons.home_work,
        title: '租赁预览卡片',
        subtitle: 'RentalPreviewCard - 图片+状态的租赁预览卡片',
        route: '/widgets_gallery/rental_preview_card',
      ),
      _buildListItem(
        context,
        icon: Icons.inbox,
        title: '收件箱消息卡片',
        subtitle: 'InboxMessageCard - 收件箱消息列表展示卡片',
        route: '/widgets_gallery/inbox_message_card',
      ),
      _buildListItem(
        context,
        icon: Icons.mail,
        title: '邮件列表卡片',
        subtitle: 'MessageListCard - 邮件/消息列表展示卡片',
        route: '/widgets_gallery/message_list_card',
      ),
      _buildListItem(
        context,
        icon: Icons.event_available,
        title: '即将到来的任务小组件',
        subtitle: 'UpcomingTasksWidget - 任务计数与彩色标签列表展示组件',
        route: '/widgets_gallery/upcoming_tasks_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.person_outline,
        title: '社交资料卡片',
        subtitle: 'SocialProfileCard - 社交媒体用户资料展示卡片',
        route: '/widgets_gallery/social_profile_card',
      ),
      _buildListItem(
        context,
        icon: Icons.forum_outlined,
        title: '社交活动动态卡片',
        subtitle: 'SocialActivityCard - 社交媒体动态信息流展示卡片',
        route: '/widgets_gallery/social_activity_card',
      ),
      _buildListItem(
        context,
        icon: Icons.image,
        title: '垂直属性卡片',
        subtitle: 'VerticalPropertyCard - 图片+信息的垂直展示卡片',
        route: '/widgets_gallery/vertical_property_card',
      ),
      _buildListItem(
        context,
        icon: Icons.task_alt,
        title: '圆角任务列表卡片',
        subtitle: 'RoundedTaskListCard - 高度圆角的任务列表卡片',
        route: '/widgets_gallery/rounded_task_list_card',
      ),
      _buildListItem(
        context,
        icon: Icons.check_circle,
        title: '每日待办事项卡片',
        subtitle: 'DailyTodoListWidget - 任务列表与提醒信息展示卡片',
        route: '/widgets_gallery/daily_todo_list_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.notification_important,
        title: '圆角提醒事项列表卡片',
        subtitle: 'RoundedRemindersList - 圆角卡片风格的提醒事项列表',
        route: '/widgets_gallery/rounded_reminders_list',
      ),
    ];
  }

  // 财务类组件
  List<Widget> _buildFinanceSection(BuildContext context) {
    return [
      _buildSectionHeader(context, '财务类 - 钱包、账单等财务相关'),
      _buildListItem(
        context,
        icon: Icons.trending_up,
        title: '收益趋势卡片',
        subtitle: 'EarningsTrendCard - 收益趋势与折线图展示卡片',
        route: '/widgets_gallery/earnings_trend_card',
      ),
      _buildListItem(
        context,
        icon: Icons.show_chart,
        title: '支出趋势折线图',
        subtitle: 'SpendingTrendChart - 支出趋势对比折线图',
        route: '/widgets_gallery/spending_trend_chart',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '支出对比图表',
        subtitle: 'ExpenseComparisonChart - 月度支出对比柱状图',
        route: '/widgets_gallery/expense_comparison_chart',
      ),
      _buildListItem(
        context,
        icon: Icons.payments_rounded,
        title: '消费卡片',
        subtitle: 'ModernRoundedSpendingWidget - 今日支出分类统计卡片',
        route: '/widgets_gallery/modern_rounded_spending_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.account_balance_wallet,
        title: '预算趋势卡片',
        subtitle: 'BudgetTrendCardWidget - 带迷你曲线图的预算趋势展示卡片',
        route: '/widgets_gallery/budget_trend_card',
      ),
      _buildListItem(
        context,
        icon: Icons.account_balance,
        title: '账户余额卡片',
        subtitle: 'AccountBalanceCard - 银行账户余额与收支统计卡片',
        route: '/widgets_gallery/account_balance_card',
      ),
      _buildListItem(
        context,
        icon: Icons.bar_chart,
        title: '分类堆叠消费卡片',
        subtitle: 'CategoryStackWidget - 堆叠柱状图与消费分类展示',
        route: '/widgets_gallery/category_stack_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.account_balance_wallet,
        title: '钱包余额概览卡片',
        subtitle: 'WalletBalanceCard - 钱包余额与收支统计卡片',
        route: '/widgets_gallery/wallet_balance_card',
      ),
      _buildListItem(
        context,
        icon: Icons.account_balance_wallet,
        title: '余额卡片',
        subtitle: 'ModernRoundedBalanceWidget - 余额与周支出统计卡片',
        route: '/widgets_gallery/modern_rounded_balance_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.receipt_long,
        title: '月度账单卡片',
        subtitle: 'MonthlyBillCard - 收入支出结余统计卡片',
        route: '/widgets_gallery/monthly_bill_card',
      ),
      _buildListItem(
        context,
        icon: Icons.donut_large,
        title: '支出分类环形图',
        subtitle: 'ExpenseDonutChart - 支出类别环形统计图',
        route: '/widgets_gallery/expense_donut_chart',
      ),
    ];
  }

  // 媒体类组件
  List<Widget> _buildMediaSection(BuildContext context) {
    return [
      _buildSectionHeader(context, '媒体类 - 音频、视频等媒体相关'),
      _buildListItem(
        context,
        icon: Icons.graphic_eq,
        title: '音频波形小组件',
        subtitle: 'AudioWaveformWidget - 音频播放波形动画展示组件',
        route: '/widgets_gallery/audio_waveform_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.music_note,
        title: '音乐播放器卡片',
        subtitle: 'MusicPlayerCard - 音乐播放控制与歌词展示卡片',
        route: '/widgets_gallery/music_player_card',
      ),
    ];
  }

  // 工具类组件
  List<Widget> _buildUtilitySection(BuildContext context) {
    return [
      _buildSectionHeader(context, '工具类 - 通用工具组件'),
      _buildListItem(
        context,
        icon: Icons.access_time,
        title: '双滑块小组件',
        subtitle: 'DualSliderWidget - 通用双滑块数值显示组件',
        route: '/widgets_gallery/dual_slider_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.scoreboard,
        title: '分数卡片',
        subtitle: 'ScoreCardWidget - 分数与行为记录展示卡片',
        route: '/widgets_gallery/score_card_widget',
      ),
      _buildListItem(
        context,
        icon: Icons.apps,
        title: '彩色快捷方式网格',
        subtitle: 'ColorfulShortcutsGrid - 多色彩快捷方式网格展示组件',
        route: '/widgets_gallery/colorful_shortcuts_grid',
      ),
      _buildListItem(
        context,
        icon: Icons.wb_sunny,
        title: '天气预报卡片',
        subtitle: 'WeatherForecastCard - 天气预报与温度趋势展示卡片',
        route: '/widgets_gallery/weather_forecast_card',
      ),
      _buildListItem(
        context,
        icon: Icons.timeline,
        title: '时间线状态卡片',
        subtitle: 'TimelineStatusCard - 时间进度状态展示卡片',
        route: '/widgets_gallery/timeline_status_card',
      ),
      _buildListItem(
        context,
        icon: Icons.storage,
        title: '存储分段小组件',
        subtitle: 'StorageBreakdownWidget - 设备存储分段统计展示组件',
        route: '/widgets_gallery/storage_breakdown_widget',
      ),
    ];
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}
