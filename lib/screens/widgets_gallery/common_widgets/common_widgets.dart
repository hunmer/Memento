import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'widgets/circular_progress_card.dart';
import 'widgets/card_dot_progress_display.dart';
import 'widgets/half_gauge_card.dart';
import 'widgets/task_progress_card.dart';
import 'widgets/task_list_card.dart';
import 'widgets/audio_waveform_card.dart';
import 'widgets/line_chart_trend_card.dart';
import 'widgets/earnings_trend_card.dart';
import 'widgets/watch_progress_card.dart';
import 'widgets/vertical_circular_progress_card.dart';
import 'widgets/card_bar_chart_monitor.dart';
import 'widgets/card_bubble_chart_display.dart';
import 'widgets/card_trend_line_chart.dart';
import 'widgets/image_display_card.dart';
import 'widgets/split_image_card.dart';
import 'widgets/segmented_progress_card.dart';
import 'widgets/profile_card_card.dart';
import 'widgets/milestone_card.dart';
import 'package:Memento/widgets/common/inbox_message_card.dart';
import 'package:Memento/widgets/common/rounded_task_list_card.dart';
import 'package:Memento/widgets/common/rounded_reminders_list_card.dart';
import 'widgets/monthly_progress_with_dots_card.dart';
import 'widgets/multi_metric_progress_card.dart';
import 'widgets/circular_metrics_card.dart';
import 'widgets/contribution_heatmap_card.dart';
import 'widgets/smooth_line_chart_card.dart';
import 'widgets/vertical_bar_chart_card.dart';
import 'widgets/message_list_card.dart';
import 'widgets/revenue_trend_card.dart';
import 'widgets/dual_slider_widget.dart';
import 'widgets/daily_todo_list_widget.dart';
import 'widgets/upcoming_tasks_widget.dart';
import 'widgets/social_profile_card.dart';
import 'widgets/mini_trend_card.dart';
import 'widgets/budget_trend_card.dart';
import 'widgets/account_balance_card.dart';
import 'widgets/modern_rounded_spending_widget.dart';
import 'widgets/wallet_balance_card.dart';
import 'widgets/music_player_card.dart';
import 'widgets/score_card_widget.dart';
import 'widgets/trend_value_card.dart';
import 'widgets/trend_list_card.dart';
import 'widgets/modern_flip_counter_card.dart';
import 'widgets/chart_icon_display_card.dart';
import 'widgets/news_update_card.dart';
import 'widgets/news_card.dart';
import 'widgets/daily_events_card.dart';
import 'widgets/daily_reflection_card.dart';
import 'widgets/colorful_shortcuts_grid.dart';
import 'widgets/journal_prompt_card.dart';
import 'widgets/social_activity_card.dart';
import 'widgets/icon_circular_progress_card.dart';
import 'widgets/monthly_bill_card.dart';
import 'widgets/color_tag_task_card.dart';
import 'widgets/weather_forecast_card.dart';
import 'widgets/timeline_status_card.dart';
import 'widgets/spending_trend_chart.dart';
import 'widgets/modern_rounded_bar_icon_card.dart';
import 'widgets/daily_schedule_card.dart';
import 'widgets/article_list_card.dart';
import 'widgets/event_calendar_widget.dart';
import 'widgets/rounded_task_progress_widget.dart';
import 'widgets/dual_range_chart_card.dart';
import 'widgets/daily_bar_chart_card.dart';
import 'widgets/split_column_progress_bar_card.dart';
import 'widgets/portfolio_stacked_chart.dart';
import 'widgets/activity_rings_card.dart';
import 'widgets/category_stack_widget.dart';
import 'widgets/performance_bar_chart.dart';
import 'widgets/expense_donut_chart.dart';
import 'widgets/ranked_bar_chart_card.dart';
import 'widgets/rental_preview_card.dart';
import 'widgets/rounded_property_card.dart';
import 'widgets/task_list_stat_card.dart';
import 'widgets/vertical_property_card.dart';
import 'widgets/task_progress_list.dart';
import 'widgets/square_pill_progress_card.dart';
import 'widgets/dark_bar_chart_card.dart';
import 'widgets/card_emoji_icon_display.dart';
import 'widgets/habit_streak_tracker_card.dart';
import 'widgets/monthly_dot_tracker_card.dart';
import 'widgets/checkin_item_card.dart';
import 'widgets/activity_heatmap_card.dart';
import 'widgets/activity_today_pie_chart_card.dart';

/// 公共小组件 ID 枚举
enum CommonWidgetId {
  circularProgressCard,
  socialActivityCard,
  iconCircularProgressCard,
  colorTagTaskCard,
  activityProgressCard,
  halfGaugeCard,
  taskProgressCard,
  taskListCard,
  audioWaveformCard,
  segmentedProgressCard,
  milestoneCard,
  monthlyProgressDotsCard,
  multiMetricProgressCard,
  circularMetricsCard,
  contributionHeatmapCard,
  smoothLineChartCard,
  lineChartTrendCard,
  verticalBarChartCard,
  messageListCard,
  inboxMessageCard,
  roundedTaskListCard,
  roundedRemindersList,
  dualSliderCard,
  earningsTrendCard,
  revenueTrendCard,
  watchProgressCard,
  stressLevelMonitor,
  sleepTrackingCard,
  dailyTodoListCard,
  upcomingTasksWidget,
  profileCardCard,
  sleepStageChartCard,
  splitImageCard,
  imageDisplayCard,
  weightTrendChart,
  socialProfileCard,
  miniTrendCard,
  budgetTrendCard,
  accountBalanceCard,
  modernRoundedSpendingWidget,
  walletBalanceCard,
  musicPlayerCard,
  scoreCardWidget,
  trendValueCard,
  trendListCard,
  moodChartCard,
  newsUpdateCard,
  newsCard,
  dailyEventsCard,
  modernEgfrHealthWidget,
  dailyReflectionCard,
  colorfulShortcutsGrid,
  journalPromptCard,
  monthlyBillCard,
  weatherForecastCard,
  timelineStatusCard,
  spendingTrendChart,
  modernRoundedMoodWidget,
  dailyScheduleCard,
  articleListCard,
  eventCalendarWidget,
  roundedTaskProgressWidget,
  dualRangeChartCard,
  dailyBarChartCard,
  nutritionProgressCard,
  portfolioStackedChart,
  activityRingsCard,
  categoryStackWidget,
  performanceBarChart,
  expenseDonutChart,
  rankedBarChartCard,
  rentalPreviewCard,
  roundedPropertyCard,
  taskListStatCard,
  verticalPropertyCard,
  taskProgressList,
  medicationTrackerWidget,
  sleepDurationCard,
  moodTrackerCard,
  habitStreakTrackerCard,
  monthlyDotTrackerCard,
  checkinItemCard,
  activityHeatmapCard,
  activityTodayPieChartCard,
}

/// 公共小组件元数据
class CommonWidgetMetadata {
  final CommonWidgetId id;
  final String name;
  final String description;
  final IconData icon;
  final HomeWidgetSize defaultSize;
  final List<HomeWidgetSize> supportedSizes;

  const CommonWidgetMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.defaultSize,
    required this.supportedSizes,
  });
}

/// 公共小组件注册表
class CommonWidgetsRegistry {
  static const Map<CommonWidgetId, CommonWidgetMetadata> metadata = {
    CommonWidgetId.circularProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.circularProgressCard,
      name: '圆形进度卡片',
      description: '显示百分比进度，带圆形进度环',
      icon: Icons.circle_outlined,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.iconCircularProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.iconCircularProgressCard,
      name: '图标圆形进度卡片',
      description: '显示带圆形进度条的卡片，支持图标、通知点、标题和副标题',
      icon: Icons.control_point_duplicate,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.colorTagTaskCard: CommonWidgetMetadata(
      id: CommonWidgetId.colorTagTaskCard,
      name: '彩色标签任务列表卡片',
      description: '显示带彩色标签的任务列表，支持翻转计数动画和入场效果',
      icon: Icons.label,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.activityProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.activityProgressCard,
      name: '活动进度卡片',
      description: '显示活动数值、单位、活动数和进度点',
      icon: Icons.directions_run,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.halfGaugeCard: CommonWidgetMetadata(
      id: CommonWidgetId.halfGaugeCard,
      name: '半圆形仪表盘',
      description: '显示预算/余额的半圆形仪表盘',
      icon: Icons.speed,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.taskProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.taskProgressCard,
      name: '任务进度卡片',
      description: '显示任务进度、待办列表',
      icon: Icons.task_alt,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.taskListCard: CommonWidgetMetadata(
      id: CommonWidgetId.taskListCard,
      name: '任务列表卡片',
      description: '显示任务列表和计数信息',
      icon: Icons.format_list_bulleted,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.audioWaveformCard: CommonWidgetMetadata(
      id: CommonWidgetId.audioWaveformCard,
      name: '音频波形卡片',
      description: '显示音频录制信息、时长和波形可视化',
      icon: Icons.graphic_eq,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.segmentedProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.segmentedProgressCard,
      name: '分段进度条卡片',
      description: '多类别分段统计卡片',
      icon: Icons.bar_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.milestoneCard: CommonWidgetMetadata(
      id: CommonWidgetId.milestoneCard,
      name: '里程碑追踪卡片',
      description: '时间里程碑追踪展示卡片',
      icon: Icons.flag,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.monthlyProgressDotsCard: CommonWidgetMetadata(
      id: CommonWidgetId.monthlyProgressDotsCard,
      name: '月度进度圆点卡片',
      description: '圆点矩阵月度进度卡片',
      icon: Icons.calendar_month,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.multiMetricProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.multiMetricProgressCard,
      name: '多指标进度卡片',
      description: '多指标进度展示卡片，带圆形进度环',
      icon: Icons.dashboard,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.circularMetricsCard: CommonWidgetMetadata(
      id: CommonWidgetId.circularMetricsCard,
      name: '环形指标卡片',
      description: '显示多个环形指标，带进度环和图标',
      icon: Icons.donut_large,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.contributionHeatmapCard: CommonWidgetMetadata(
      id: CommonWidgetId.contributionHeatmapCard,
      name: '贡献热力图卡片',
      description: '活跃度热力图网格展示卡片',
      icon: Icons.grid_on,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.smoothLineChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.smoothLineChartCard,
      name: '平滑折线图卡片',
      description: '带渐变填充的平滑折线图卡片',
      icon: Icons.show_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.verticalBarChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.verticalBarChartCard,
      name: '垂直柱状图卡片',
      description: '双数据系列垂直柱状图展示卡片',
      icon: Icons.bar_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.lineChartTrendCard: CommonWidgetMetadata(
      id: CommonWidgetId.lineChartTrendCard,
      name: '折线图趋势卡片',
      description: '折线图趋势统计卡片',
      icon: Icons.show_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.messageListCard: CommonWidgetMetadata(
      id: CommonWidgetId.messageListCard,
      name: '消息列表卡片',
      description: '消息列表展示卡片，支持置顶消息和消息列表',
      icon: Icons.message,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.inboxMessageCard: CommonWidgetMetadata(
      id: CommonWidgetId.inboxMessageCard,
      name: '收件箱消息卡片',
      description: '显示消息列表和计数信息',
      icon: Icons.inbox,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.roundedTaskListCard: CommonWidgetMetadata(
      id: CommonWidgetId.roundedTaskListCard,
      name: '圆角任务列表卡片',
      description: '显示任务列表和日期信息',
      icon: Icons.list_alt,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.roundedRemindersList: CommonWidgetMetadata(
      id: CommonWidgetId.roundedRemindersList,
      name: '圆角提醒事项列表',
      description: '显示提醒事项列表和计数',
      icon: Icons.notification_important,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.dualSliderCard: CommonWidgetMetadata(
      id: CommonWidgetId.dualSliderCard,
      name: '双滑块小组件',
      description: '通用双滑块数值显示组件，支持自定义标签和进度',
      icon: Icons.access_time,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.earningsTrendCard: CommonWidgetMetadata(
      id: CommonWidgetId.earningsTrendCard,
      name: '收益趋势卡片',
      description: '显示收益趋势、货币数值、百分比变化和平滑折线图',
      icon: Icons.trending_up,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.revenueTrendCard: CommonWidgetMetadata(
      id: CommonWidgetId.revenueTrendCard,
      name: '收入趋势卡片',
      description: '显示收入趋势、货币数值、百分比变化和曲线图，支持日期标签和高亮点',
      icon: Icons.trending_up,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.watchProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.watchProgressCard,
      name: '观看进度卡片',
      description: '显示用户观看进度、当前/总数和观看项目列表',
      icon: Icons.play_circle_outline,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.stressLevelMonitor: CommonWidgetMetadata(
      id: CommonWidgetId.stressLevelMonitor,
      name: '压力水平监测',
      description: '显示当前压力分数、状态描述和每周7天的柱状图数据，支持动画效果',
      icon: Icons.psychology_outlined,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.sleepTrackingCard: CommonWidgetMetadata(
      id: CommonWidgetId.sleepTrackingCard,
      name: '睡眠追踪卡片',
      description: '显示睡眠时长、标签和每周7天的进度环，支持动画效果',
      icon: Icons.bedtime_outlined,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.dailyTodoListCard: CommonWidgetMetadata(
      id: CommonWidgetId.dailyTodoListCard,
      name: '每日待办事项卡片',
      description: '显示日期、时间和待办任务列表，支持任务切换和提醒信息',
      icon: Icons.check_circle_outline,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.upcomingTasksWidget: CommonWidgetMetadata(
      id: CommonWidgetId.upcomingTasksWidget,
      name: '即将到来的任务小组件',
      description: '显示任务计数、任务列表和更多任务数量，支持动画效果',
      icon: Icons.task_alt,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.profileCardCard: CommonWidgetMetadata(
      id: CommonWidgetId.profileCardCard,
      name: '个人资料卡片',
      description: '展示用户个人信息，包括背景图、姓名、认证标志、简介和关注统计',
      icon: Icons.account_circle,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.sleepStageChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.sleepStageChartCard,
      name: '睡眠阶段图表',
      description: '展示睡眠阶段的可视化图表，支持动画效果和时间范围选择',
      icon: Icons.bedtime_outlined,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.splitImageCard: CommonWidgetMetadata(
      id: CommonWidgetId.splitImageCard,
      name: '图片分割卡片',
      description: '左右分屏布局的卡片组件，左侧展示图片，右侧展示信息',
      icon: Icons.image,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.socialProfileCard: CommonWidgetMetadata(
      id: CommonWidgetId.socialProfileCard,
      name: '社交资料卡片',
      description: '显示用户头像、名称、账号、标签、内容和社交统计数据',
      icon: Icons.person,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.miniTrendCard: CommonWidgetMetadata(
      id: CommonWidgetId.miniTrendCard,
      name: '迷你趋势卡片',
      description: '显示标题、图标、当前数值、单位、副标题、星期标签和趋势折线图',
      icon: Icons.show_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.budgetTrendCard: CommonWidgetMetadata(
      id: CommonWidgetId.budgetTrendCard,
      name: '预算趋势卡片',
      description: '通用的带迷你曲线图的数值展示卡片，支持标签、数值显示（带翻转动画）、迷你曲线图、变化百分比和更新时间',
      icon: Icons.trending_up,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.accountBalanceCard: CommonWidgetMetadata(
      id: CommonWidgetId.accountBalanceCard,
      name: '账户余额卡片',
      description: '显示多个账户的余额信息，包括账户名称、图标、账单数量和余额，支持正负余额显示和入场动画效果',
      icon: Icons.account_balance,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.modernRoundedSpendingWidget: CommonWidgetMetadata(
      id: CommonWidgetId.modernRoundedSpendingWidget,
      name: '现代圆角消费卡片',
      description: '显示当前消费、预算、分类进度条和分类列表，支持动画效果',
      icon: Icons.payments_outlined,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.walletBalanceCard: CommonWidgetMetadata(
      id: CommonWidgetId.walletBalanceCard,
      name: '钱包余额概览卡片',
      description: '显示钱包余额、可用余额、收入支出统计和操作按钮，支持动画效果',
      icon: Icons.account_balance_wallet,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.musicPlayerCard: CommonWidgetMetadata(
      id: CommonWidgetId.musicPlayerCard,
      name: '音乐播放器卡片',
      description: '显示专辑封面、歌词、播放进度和控制按钮，支持动画效果',
      icon: Icons.music_note,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.scoreCardWidget: CommonWidgetMetadata(
      id: CommonWidgetId.scoreCardWidget,
      name: '分数卡片',
      description: '显示分数、等级和行为列表，支持翻转计数动画和渐变背景',
      icon: Icons.scoreboard,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.trendValueCard: CommonWidgetMetadata(
      id: CommonWidgetId.trendValueCard,
      name: '趋势数值卡片',
      description: '通用的数值展示卡片，支持数值和单位显示（带翻转动画）、趋势指示（上升/下降）、曲线图表（带渐变填充）和附加信息（日期、BMI等）',
      icon: Icons.trending_up,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.trendListCard: CommonWidgetMetadata(
      id: CommonWidgetId.trendListCard,
      name: '趋势列表卡片',
      description: '股票/指数价格与涨跌幅列表卡片，支持多个趋势项展示，带翻转计数动画和入场效果',
      icon: Icons.trending_up,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.modernEgfrHealthWidget: CommonWidgetMetadata(
      id: CommonWidgetId.modernEgfrHealthWidget,
      name: '健康指标卡片',
      description: '通用的健康指标展示卡片，支持标题、图标、数值（带翻转动画）、单位和状态指示器',
      icon: Icons.favorite,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.newsUpdateCard: CommonWidgetMetadata(
      id: CommonWidgetId.newsUpdateCard,
      name: '新闻更新卡片',
      description: '显示新闻标题、时间戳和分页指示器，支持动画效果',
      icon: Icons.newspaper,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.newsCard: CommonWidgetMetadata(
      id: CommonWidgetId.newsCard,
      name: '新闻卡片',
      description: '显示头条新闻、分类标签和新闻列表，支持动画效果',
      icon: Icons.article,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),

    CommonWidgetId.moodChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.moodChartCard,
      name: '心情图表卡片',
      description: '显示每日情绪柱状图和每周心情历史记录，支持动画效果和多种心情表情',
      icon: Icons.sentiment_satisfied_alt,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.dailyEventsCard: CommonWidgetMetadata(
      id: CommonWidgetId.dailyEventsCard,
      name: '每日事件卡片',
      description: '显示星期、日期和当日事件列表，支持翻转计数动画',
      icon: Icons.event,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.dailyReflectionCard: CommonWidgetMetadata(
      id: CommonWidgetId.dailyReflectionCard,
      name: '每日反思卡片',
      description: '引导用户每日思考和记录的卡片，包含星期几、引导性问题和操作按钮',
      icon: Icons.lightbulb_outline,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.colorfulShortcutsGrid: CommonWidgetMetadata(
      id: CommonWidgetId.colorfulShortcutsGrid,
      name: '彩色快捷方式网格',
      description: '显示带颜色背景的快捷方式网格，支持动画效果和自定义图标',
      icon: Icons.grid_view,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.journalPromptCard: CommonWidgetMetadata(
      id: CommonWidgetId.journalPromptCard,
      name: '日记提示卡片',
      description: '显示星期几、提示性问题和操作按钮（新建、同步），支持动画效果和自定义蝴蝶图标',
      icon: Icons.book,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.socialActivityCard: CommonWidgetMetadata(
      id: CommonWidgetId.socialActivityCard,
      name: '社交活动动态卡片',
      description: '显示用户头像、名称、关注数和社交动态列表，支持翻转计数动画和互动数据',
      icon: Icons.people,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.monthlyBillCard: CommonWidgetMetadata(
      id: CommonWidgetId.monthlyBillCard,
      name: '月度账单卡片',
      description: '显示月度账单信息，包括收入、支出和结余，支持翻转计数动画和入场效果',
      icon: Icons.receipt_long,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.weatherForecastCard: CommonWidgetMetadata(
      id: CommonWidgetId.weatherForecastCard,
      name: '天气预报卡片',
      description: '显示城市天气、温度信息和温度趋势图，支持翻转计数动画和入场效果',
      icon: Icons.cloud,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.timelineStatusCard: CommonWidgetMetadata(
      id: CommonWidgetId.timelineStatusCard,
      name: '时间线状态卡片',
      description: '显示位置、标题、描述和时间线进度，支持动画效果和网格背景',
      icon: Icons.timeline,
      defaultSize: HomeWidgetSize.medium,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.spendingTrendChart: CommonWidgetMetadata(
      id: CommonWidgetId.spendingTrendChart,
      name: '支出趋势折线图',
      description: '显示支出趋势对比的折线图卡片，支持当前月与上月对比、预算线显示和平滑曲线动画',
      icon: Icons.show_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.modernRoundedMoodWidget: CommonWidgetMetadata(
      id: CommonWidgetId.modernRoundedMoodWidget,
      name: '现代化心情追踪',
      description: '周视图柱状图显示每日心情值，支持积极/消极情绪区分、7天心情历史和当前日期高亮',
      icon: Icons.sentiment_satisfied_alt,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.dailyScheduleCard: CommonWidgetMetadata(
      id: CommonWidgetId.dailyScheduleCard,
      name: '每日日程卡片',
      description: '显示日期、今日活动和明日活动列表，支持时间活动和全天活动',
      icon: Icons.event,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.articleListCard: CommonWidgetMetadata(
      id: CommonWidgetId.articleListCard,
      name: '文章列表卡片',
      description: '显示特色文章和普通文章列表，支持图片展示和动画效果',
      icon: Icons.article,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.eventCalendarWidget: CommonWidgetMetadata(
      id: CommonWidgetId.eventCalendarWidget,
      name: '日历事件小组件',
      description: '显示日期、周日历和事件列表，支持活动计数和提醒信息',
      icon: Icons.calendar_today,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.roundedTaskProgressWidget: CommonWidgetMetadata(
      id: CommonWidgetId.roundedTaskProgressWidget,
      name: '圆角任务进度小组件',
      description: '显示项目标题、进度条、待办任务列表、评论数、附件数和团队成员头像',
      icon: Icons.task_alt,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.dualRangeChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.dualRangeChartCard,
      name: '双范围图表统计卡片',
      description: '显示双范围柱状图，支持日期选择、周视图和范围汇总数据',
      icon: Icons.bar_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.dailyBarChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.dailyBarChartCard,
      name: '每日条形图卡片',
      description: '显示每日数据条形图，支持标题、副标题、数值显示和多种颜色',
      icon: Icons.bar_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.nutritionProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.nutritionProgressCard,
      name: '营养进度卡片',
      description: '显示卡路里和营养素（蛋白质、碳水化合物、脂肪）进度，支持动画计数',
      icon: Icons.restaurant,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.portfolioStackedChart: CommonWidgetMetadata(
      id: CommonWidgetId.portfolioStackedChart,
      name: '投资组合堆叠图',
      description: '显示投资组合的堆叠柱状图，支持多种资产类型和月度数据展示',
      icon: Icons.show_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.activityRingsCard: CommonWidgetMetadata(
      id: CommonWidgetId.activityRingsCard,
      name: '活动圆环卡片',
      description: '显示活动圆环（步数、卡路里等），支持日期和状态显示',
      icon: Icons.fitness_center,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.categoryStackWidget: CommonWidgetMetadata(
      id: CommonWidgetId.categoryStackWidget,
      name: '分类堆叠消费卡片',
      description: '显示分类消费堆叠图，支持当前金额、目标金额和分类列表',
      icon: Icons.pie_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.performanceBarChart: CommonWidgetMetadata(
      id: CommonWidgetId.performanceBarChart,
      name: '性能指标柱状图',
      description: '显示性能指标柱状图，支持增长百分比和时间周期',
      icon: Icons.bar_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.expenseDonutChart: CommonWidgetMetadata(
      id: CommonWidgetId.expenseDonutChart,
      name: '支出分类环形图',
      description: '显示支出分类的环形图和分类列表，支持总额显示和翻转计数动画',
      icon: Icons.pie_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.rankedBarChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.rankedBarChartCard,
      name: '排名条形图卡片',
      description: '显示排名条形图列表，支持标题、副标题、条目计数和页脚文本',
      icon: Icons.bar_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.rentalPreviewCard: CommonWidgetMetadata(
      id: CommonWidgetId.rentalPreviewCard,
      name: '租赁预览卡片',
      description: '显示租赁信息的卡片，包含图片、标题、评分、描述和时间',
      icon: Icons.home_work,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.roundedPropertyCard: CommonWidgetMetadata(
      id: CommonWidgetId.roundedPropertyCard,
      name: '圆角属性卡片',
      description: '显示房地产属性的卡片，包含图片、标题、元数据和描述',
      icon: Icons.home,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.taskListStatCard: CommonWidgetMetadata(
      id: CommonWidgetId.taskListStatCard,
      name: '任务统计列表卡片',
      description: '显示任务统计和列表的卡片，包含图标、计数和任务列表',
      icon: Icons.format_list_bulleted,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.verticalPropertyCard: CommonWidgetMetadata(
      id: CommonWidgetId.verticalPropertyCard,
      name: '垂直属性卡片',
      description: '显示属性信息的垂直卡片，包含图片、标题、元数据和操作按钮',
      icon: Icons.home_outlined,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.taskProgressList: CommonWidgetMetadata(
      id: CommonWidgetId.taskProgressList,
      name: '任务进度列表',
      description: '显示任务进度列表，包含任务标题、时间和进度条',
      icon: Icons.task_alt,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.medicationTrackerWidget: CommonWidgetMetadata(
      id: CommonWidgetId.medicationTrackerWidget,
      name: '药物追踪器',
      description: '显示药物数量和进度，带胶囊形状进度条',
      icon: Icons.medication_outlined,
      defaultSize: HomeWidgetSize.medium,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.sleepDurationCard: CommonWidgetMetadata(
      id: CommonWidgetId.sleepDurationCard,
      name: '睡眠时长统计卡片',
      description: '显示睡眠时长、趋势和睡眠周期可视化',
      icon: Icons.bedtime_outlined,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.moodTrackerCard: CommonWidgetMetadata(
      id: CommonWidgetId.moodTrackerCard,
      name: '心情追踪卡片',
      description: '显示情绪记录和每周情绪数据',
      icon: Icons.sentiment_satisfied_alt,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.habitStreakTrackerCard: CommonWidgetMetadata(
      id: CommonWidgetId.habitStreakTrackerCard,
      name: '习惯连续追踪卡片',
      description: '显示习惯打卡连续天数、最佳记录、里程碑和日期网格',
      icon: Icons.local_fire_department,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.monthlyDotTrackerCard: CommonWidgetMetadata(
      id: CommonWidgetId.monthlyDotTrackerCard,
      name: '月度点追踪卡片',
      description: '显示当月的签到状态点阵、进度统计和状态标签',
      icon: Icons.calendar_month,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.checkinItemCard: CommonWidgetMetadata(
      id: CommonWidgetId.checkinItemCard,
      name: '签到项目卡片',
      description: '显示签到项目的图标、名称、今日打卡状态和热力图',
      icon: Icons.checklist,
      defaultSize: HomeWidgetSize.medium,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.activityHeatmapCard: CommonWidgetMetadata(
      id: CommonWidgetId.activityHeatmapCard,
      name: '活动热力图卡片',
      description: '展示今日24小时的活动热力图，支持不同时间粒度（5/10/15/30/60分钟）',
      icon: Icons.grid_on,
      defaultSize: HomeWidgetSize.large3,
      supportedSizes: [HomeWidgetSize.large3],
    ),
    CommonWidgetId.activityTodayPieChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.activityTodayPieChartCard,
      name: '今日活动统计卡片',
      description: '使用饼状图展示今日活动统计，按标签统计时长',
      icon: Icons.pie_chart,
      defaultSize: HomeWidgetSize.large3,
      supportedSizes: [HomeWidgetSize.large3],
    ),
  };

  /// 获取元数据
  static CommonWidgetMetadata getMetadata(CommonWidgetId id) {
    return metadata[id]!;
  }

  /// 获取所有元数据
  static List<CommonWidgetMetadata> getAllMetadata() {
    return metadata.values.toList();
  }

  /// 根据 ID 字符串获取枚举值
  static CommonWidgetId? fromString(String id) {
    return CommonWidgetId.values.asNameMap()[id];
  }
}


/// 公共小组件构建器
class CommonWidgetBuilder {
  /// 构建公共小组件
  static Widget build(
    BuildContext context,
    CommonWidgetId widgetId,
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    switch (widgetId) {
      case CommonWidgetId.circularProgressCard:
        return CircularProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.iconCircularProgressCard:
        return IconCircularProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.colorTagTaskCard:
        return ColorTagTaskCardWidget.fromProps(props, size);
      case CommonWidgetId.activityProgressCard:
        return CardDotProgressDisplay.fromProps(props, size);
      case CommonWidgetId.halfGaugeCard:
        return HalfGaugeCardWidget.fromProps(props, size);
      case CommonWidgetId.taskProgressCard:
        return TaskProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.taskListCard:
        return TaskListCardWidget.fromProps(props, size);
      case CommonWidgetId.audioWaveformCard:
        return AudioWaveformCardWidget.fromProps(props, size);
      case CommonWidgetId.segmentedProgressCard:
        return SegmentedProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.milestoneCard:
        return MilestoneCardWidget.fromProps(props, size);
      case CommonWidgetId.monthlyProgressDotsCard:
        return MonthlyProgressWithDotsCardWidget.fromProps(props, size);
      case CommonWidgetId.multiMetricProgressCard:
        return MultiMetricProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.circularMetricsCard:
        return CircularMetricsCardWidget.fromProps(props, size);
      case CommonWidgetId.contributionHeatmapCard:
        return ContributionHeatmapCardWidget.fromProps(props, size);
      case CommonWidgetId.smoothLineChartCard:
        return SmoothLineChartCardWidget.fromProps(props, size);
      case CommonWidgetId.lineChartTrendCard:
        return LineChartTrendCardWidget.fromProps(props, size);
      case CommonWidgetId.verticalBarChartCard:
        return VerticalBarChartCardWidget.fromProps(props, size);
      case CommonWidgetId.messageListCard:
        return MessageListCardWidget.fromProps(props, size);
      case CommonWidgetId.inboxMessageCard:
        return InboxMessageCardWidget.fromProps(props, size);
      case CommonWidgetId.roundedTaskListCard:
        return RoundedTaskListCard.fromProps(props, size);
      case CommonWidgetId.roundedRemindersList:
        return ReminderListCard.fromProps(props, size);
      case CommonWidgetId.dualSliderCard:
        return DualSliderWidget.fromProps(props, size);
      case CommonWidgetId.earningsTrendCard:
        return EarningsTrendCardWidget.fromProps(props, size);
      case CommonWidgetId.revenueTrendCard:
        return RevenueTrendCardWidget.fromProps(props, size);
      case CommonWidgetId.watchProgressCard:
        return WatchProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.sleepTrackingCard:
        return VerticalCircularProgressCard.fromProps(props, size);
      case CommonWidgetId.stressLevelMonitor:
        return CardBarChartMonitor.fromProps(props, size);
      case CommonWidgetId.dailyTodoListCard:
        return DailyTodoListWidget.fromProps(props, size);
      case CommonWidgetId.upcomingTasksWidget:
        return UpcomingTasksWidget.fromProps(props, size);
      case CommonWidgetId.splitImageCard:
        return SplitImageCardWidget.fromProps(props, size);
      case CommonWidgetId.profileCardCard:
        return ProfileCardWidget.fromProps(props, size);
      case CommonWidgetId.sleepStageChartCard:
        return CardBubbleChartDisplay.fromProps(props, size);
      case CommonWidgetId.imageDisplayCard:
        return ImageDisplayCardWidget.fromProps(props, size);
      case CommonWidgetId.weightTrendChart:
        return CardTrendLineChart.fromProps(props, size);
      case CommonWidgetId.socialProfileCard:
        return SocialProfileCardWidget.fromProps(props, size);
      case CommonWidgetId.miniTrendCard:
        return MiniTrendCardWidget.fromProps(props, size);
      case CommonWidgetId.budgetTrendCard:
        return BudgetTrendCardWidget.fromProps(props, size);
      case CommonWidgetId.accountBalanceCard:
        return AccountBalanceCardWidget.fromProps(props, size);
      case CommonWidgetId.modernRoundedSpendingWidget:
        return ModernRoundedSpendingWidget.fromProps(props, size);
      case CommonWidgetId.walletBalanceCard:
        return WalletBalanceCardWidget.fromProps(props, size);
      case CommonWidgetId.musicPlayerCard:
        return MusicPlayerCardWidget.fromProps(props, size);
      case CommonWidgetId.scoreCardWidget:
        return ScoreCardWidget.fromProps(props, size);
      case CommonWidgetId.trendValueCard:
        return TrendValueCardWidget.fromProps(props, size);
      case CommonWidgetId.trendListCard:
        return TrendListCardWidget.fromProps(props, size);
      case CommonWidgetId.newsUpdateCard:
        return NewsUpdateCardWidget.fromProps(props, size);
      case CommonWidgetId.newsCard:
        return NewsCardWidget.fromProps(props, size);
      case CommonWidgetId.modernEgfrHealthWidget:
        return ModernFlipCounterCard.fromProps(props, size);
      case CommonWidgetId.moodChartCard:
        return ChartIconDisplayCard.fromProps(props, size);
      case CommonWidgetId.dailyEventsCard:
        return DailyEventsCardWidget.fromProps(props, size);
      case CommonWidgetId.dailyReflectionCard:
        return DailyReflectionCardWidget.fromProps(props, size);
      case CommonWidgetId.colorfulShortcutsGrid:
        return ColorfulShortcutsGridWidget.fromProps(props, size);
      case CommonWidgetId.journalPromptCard:
        return JournalPromptCardWidget.fromProps(props, size);
      case CommonWidgetId.socialActivityCard:
        return SocialActivityCardWidget.fromProps(props, size);
      case CommonWidgetId.monthlyBillCard:
        return MonthlyBillCardWidget.fromProps(props, size);
      case CommonWidgetId.weatherForecastCard:
        return WeatherForecastCard.fromProps(props, size);
      case CommonWidgetId.timelineStatusCard:
        return TimelineStatusCardWidget.fromProps(props, size);
      case CommonWidgetId.spendingTrendChart:
        return SpendingTrendChartWidget.fromProps(props, size);
      case CommonWidgetId.modernRoundedMoodWidget:
        return ModernRoundedBarIconCard.fromProps(props, size);
      case CommonWidgetId.dailyScheduleCard:
        return DailyScheduleCardWidget.fromProps(props, size);
      case CommonWidgetId.articleListCard:
        return ArticleListCardWidget.fromProps(props, size);
      case CommonWidgetId.eventCalendarWidget:
        return EventCalendarWidget.fromProps(props, size);
      case CommonWidgetId.roundedTaskProgressWidget:
        return RoundedTaskProgressWidget.fromProps(props, size);
      case CommonWidgetId.dualRangeChartCard:
        return DualRangeChartCardWidget.fromProps(props, size);
      case CommonWidgetId.dailyBarChartCard:
        return DailyBarChartCardWidget.fromProps(props, size);
      case CommonWidgetId.nutritionProgressCard:
        return SplitColumnProgressBarCard.fromProps(props, size);
      case CommonWidgetId.portfolioStackedChart:
        return PortfolioStackedChartWidget.fromProps(props, size);
      case CommonWidgetId.activityRingsCard:
        return ActivityRingsCardWidget.fromProps(props, size);
      case CommonWidgetId.categoryStackWidget:
        return CategoryStackWidget.fromProps(props, size);
      case CommonWidgetId.performanceBarChart:
        return PerformanceBarChartWidget.fromProps(props, size);
      case CommonWidgetId.expenseDonutChart:
        return ExpenseDonutChartWidget.fromProps(props, size);
      case CommonWidgetId.rankedBarChartCard:
        return RankedBarChartCardWidget.fromProps(props, size);
      case CommonWidgetId.rentalPreviewCard:
        return RentalPreviewCardWidget.fromProps(props, size);
      case CommonWidgetId.roundedPropertyCard:
        return RoundedPropertyCardWidget.fromProps(props, size);
      case CommonWidgetId.taskListStatCard:
        return TaskListStatCardWidget.fromProps(props, size);
      case CommonWidgetId.verticalPropertyCard:
        return VerticalPropertyCardWidget.fromProps(props, size);
      case CommonWidgetId.taskProgressList:
        return TaskProgressListWidget.fromProps(props, size);
      case CommonWidgetId.medicationTrackerWidget:
        return SquarePillProgressCard.fromProps(props, size);
      case CommonWidgetId.sleepDurationCard:
        return DarkBarChartCard.fromProps(props, size);
      case CommonWidgetId.moodTrackerCard:
        return CardEmojiIconDisplay.fromProps(props, size);
      case CommonWidgetId.habitStreakTrackerCard:
        return HabitStreakTrackerCardWidget.fromProps(props, size);
      case CommonWidgetId.monthlyDotTrackerCard:
        return MonthlyDotTrackerCardWidget.fromProps(props, size);
      case CommonWidgetId.checkinItemCard:
        return CheckinItemCardWidget.fromProps(props, size);
      case CommonWidgetId.activityHeatmapCard:
        return ActivityHeatmapCardWidget.fromProps(props, size);
      case CommonWidgetId.activityTodayPieChartCard:
        return ActivityTodayPieChartCardWidget.fromProps(props, size);
    }
  }
}
