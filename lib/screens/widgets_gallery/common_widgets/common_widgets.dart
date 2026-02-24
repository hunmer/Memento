// ignore_for_file: deprecated_member_use_from_same_package

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
import 'package:Memento/widgets/common/timer_card_widget.dart';
import 'widgets/monthly_progress_with_dots_card.dart';
import 'widgets/multi_metric_progress_card.dart';
import 'widgets/circular_metrics_card.dart';
import 'widgets/smooth_line_chart_card.dart';
import 'widgets/goods_item_selector.dart';
import 'widgets/vertical_bar_chart_card.dart';
import 'widgets/revenue_trend_card.dart';
import 'widgets/dual_slider_widget.dart';
import 'widgets/daily_todo_list_widget.dart';
import 'widgets/upcoming_tasks_widget.dart';
import 'widgets/social_profile_card.dart';
import 'widgets/mini_trend_card.dart';
import 'widgets/account_balance_card.dart';
import 'widgets/modern_rounded_spending_widget.dart';
import 'widgets/wallet_balance_card.dart';
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
import 'widgets/ranked_bar_chart_card.dart';
import 'widgets/rental_preview_card.dart';
import 'widgets/rounded_property_card.dart';
import 'widgets/task_list_stat_card.dart';
import 'widgets/vertical_property_card.dart';
import 'widgets/task_progress_list.dart';
import 'widgets/dark_bar_chart_card.dart';
import 'widgets/card_emoji_icon_display.dart';
import 'widgets/habit_streak_tracker_card.dart';
import 'widgets/monthly_dot_tracker_card.dart';
import 'widgets/checkin_item_card.dart';
import 'widgets/activity_heatmap_card.dart';
import 'widgets/activity_today_pie_chart_card.dart';
import 'widgets/timeline_schedule_card.dart';
import 'widgets/trend_line_chart_card_wrapper.dart';
import 'widgets/bar_chart_stats_card.dart';
import 'widgets/expense_comparison_chart_card.dart';
import 'widgets/weekly_diary_widget.dart';
import 'package:Memento/widgets/common/dual_value_tracker_card.dart';
import 'package:Memento/widgets/common/modern_rounded_balance_card.dart';
import 'package:Memento/plugins/activity/home_widgets/widgets/activity_last_activity.dart';
import 'widgets/folder_notes_card.dart';
import 'widgets/habit_heatmap_card.dart';
import 'widgets/points_goal_card.dart';
import 'widgets/store_product_selector_card.dart';
import 'widgets/store_user_item_selector_card.dart';
import 'widgets/notebook_list_card.dart';
import 'widgets/node_stats_card.dart';
import 'widgets/todo_nodes_list.dart';
import 'widgets/contact_card.dart';
import 'widgets/recent_contact_card.dart';
import 'package:Memento/plugins/habits/home_widgets/widgets/habit_card_widget.dart';

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
  smoothLineChartCard,
  lineChartTrendCard,
  verticalBarChartCard,
  inboxMessageCard,
  roundedTaskListCard,
  roundedRemindersList,
  dualSliderCard,
  earningsTrendCard,
  timerCard,
  revenueTrendCard,
  watchProgressCard,
  stressLevelMonitor,
  dailyTodoListCard,
  upcomingTasksWidget,
  profileCardCard,
  sleepStageChartCard,
  splitImageCard,
  imageDisplayCard,
  weightTrendChart,
  socialProfileCard,
  miniTrendCard,
  accountBalanceCard,
  modernRoundedSpendingWidget,
  walletBalanceCard,
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
  rankedBarChartCard,
  rentalPreviewCard,
  roundedPropertyCard,
  taskListStatCard,
  verticalPropertyCard,
  taskProgressList,
  sleepDurationCard,
  moodTrackerCard,
  habitStreakTrackerCard,
  monthlyDotTrackerCard,
  checkinItemCard,
  activityHeatmapCard,
  activityTodayPieChartCard,
  timelineScheduleCard,
  bloodPressureTracker,
  trendLineChartCard,
  modernRoundedBalanceCard,
  barChartStatsCard,
  expenseComparisonChart,
  weeklyDiaryWidget,
  activityLastActivity,
  folderNotesCard,
  goodsItemSelector,
  habitHeatmapCard,
  pointsGoalCard,
  storeProductSelector,
  storeUserItemSelector,
  notebookListCard,
  nodeStatsCard,
  todoNodesList,
  recentContactCard,
  contactCard,
  habitCard,
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
  static final Map<CommonWidgetId, CommonWidgetMetadata> metadata = {
    CommonWidgetId.circularProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.circularProgressCard,
      name: '圆形进度卡片',
      description: '显示百分比进度，带圆形进度环',
      icon: Icons.circle_outlined,
      defaultSize: Large3Size(),
      supportedSizes: [const MediumSize(), const LargeSize()],
    ),
    CommonWidgetId.iconCircularProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.iconCircularProgressCard,
      name: '图标圆形进度卡片',
      description: '显示带圆形进度条的卡片，支持图标、通知点、标题和副标题',
      icon: Icons.control_point_duplicate,
      defaultSize: Large3Size(),
      supportedSizes: [const MediumSize(), const LargeSize()],
    ),
    CommonWidgetId.colorTagTaskCard: CommonWidgetMetadata(
      id: CommonWidgetId.colorTagTaskCard,
      name: '彩色标签任务列表卡片',
      description: '显示带彩色标签的任务列表，支持翻转计数动画和入场效果',
      icon: Icons.label,
      defaultSize: Large3Size(),
      supportedSizes: const [LargeSize()],
    ),
    CommonWidgetId.activityProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.activityProgressCard,
      name: '活动进度卡片',
      description: '显示活动数值、单位、活动数和进度点',
      icon: Icons.directions_run,
      defaultSize: Large3Size(),
      supportedSizes: [const MediumSize(), const LargeSize()],
    ),
    CommonWidgetId.halfGaugeCard: const CommonWidgetMetadata(
      id: CommonWidgetId.halfGaugeCard,
      name: '半圆形仪表盘',
      description: '显示预算/余额的半圆形仪表盘',
      icon: Icons.speed,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.taskProgressCard: const CommonWidgetMetadata(
      id: CommonWidgetId.taskProgressCard,
      name: '任务进度卡片',
      description: '显示任务进度、待办列表',
      icon: Icons.task_alt,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.taskListCard: CommonWidgetMetadata(
      id: CommonWidgetId.taskListCard,
      name: '任务列表卡片',
      description: '显示任务列表和计数信息',
      icon: Icons.format_list_bulleted,
      defaultSize: Large3Size(),
      supportedSizes: const [LargeSize()],
    ),
    CommonWidgetId.audioWaveformCard: const CommonWidgetMetadata(
      id: CommonWidgetId.audioWaveformCard,
      name: '音频波形卡片',
      description: '显示音频录制信息、时长和波形可视化',
      icon: Icons.graphic_eq,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.segmentedProgressCard: const CommonWidgetMetadata(
      id: CommonWidgetId.segmentedProgressCard,
      name: '分段进度条卡片',
      description: '多类别分段统计卡片',
      icon: Icons.bar_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.milestoneCard: CommonWidgetMetadata(
      id: CommonWidgetId.milestoneCard,
      name: '里程碑追踪卡片',
      description: '时间里程碑追踪展示卡片',
      icon: Icons.flag,
      defaultSize: Large3Size(),
      supportedSizes: const [LargeSize()],
    ),
    CommonWidgetId.monthlyProgressDotsCard: const CommonWidgetMetadata(
      id: CommonWidgetId.monthlyProgressDotsCard,
      name: '月度进度圆点卡片',
      description: '圆点矩阵月度进度卡片',
      icon: Icons.calendar_month,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.multiMetricProgressCard: const CommonWidgetMetadata(
      id: CommonWidgetId.multiMetricProgressCard,
      name: '多指标进度卡片',
      description: '多指标进度展示卡片，带圆形进度环',
      icon: Icons.dashboard,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.circularMetricsCard: const CommonWidgetMetadata(
      id: CommonWidgetId.circularMetricsCard,
      name: '环形指标卡片',
      description: '显示多个环形指标，带进度环和图标',
      icon: Icons.donut_large,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.smoothLineChartCard: const CommonWidgetMetadata(
      id: CommonWidgetId.smoothLineChartCard,
      name: '平滑折线图卡片',
      description: '带渐变填充的平滑折线图卡片',
      icon: Icons.show_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.verticalBarChartCard: const CommonWidgetMetadata(
      id: CommonWidgetId.verticalBarChartCard,
      name: '垂直柱状图卡片',
      description: '双数据系列垂直柱状图展示卡片',
      icon: Icons.bar_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.lineChartTrendCard: const CommonWidgetMetadata(
      id: CommonWidgetId.lineChartTrendCard,
      name: '折线图趋势卡片',
      description: '折线图趋势统计卡片',
      icon: Icons.show_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.inboxMessageCard: const CommonWidgetMetadata(
      id: CommonWidgetId.inboxMessageCard,
      name: '收件箱消息卡片',
      description: '显示消息列表和计数信息',
      icon: Icons.inbox,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.roundedTaskListCard: const CommonWidgetMetadata(
      id: CommonWidgetId.roundedTaskListCard,
      name: '圆角任务列表卡片',
      description: '显示任务列表和日期信息',
      icon: Icons.list_alt,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.roundedRemindersList: const CommonWidgetMetadata(
      id: CommonWidgetId.roundedRemindersList,
      name: '圆角提醒事项列表',
      description: '显示提醒事项列表和计数',
      icon: Icons.notification_important,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.dualSliderCard: const CommonWidgetMetadata(
      id: CommonWidgetId.dualSliderCard,
      name: '双滑块小组件',
      description: '通用双滑块数值显示组件，支持自定义标签和进度',
      icon: Icons.access_time,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.earningsTrendCard: const CommonWidgetMetadata(
      id: CommonWidgetId.earningsTrendCard,
      name: '收益趋势卡片',
      description: '显示收益趋势、货币数值、百分比变化和平滑折线图',
      icon: Icons.trending_up,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.revenueTrendCard: const CommonWidgetMetadata(
      id: CommonWidgetId.revenueTrendCard,
      name: '收入趋势卡片',
      description: '显示收入趋势、货币数值、百分比变化和曲线图，支持日期标签和高亮点',
      icon: Icons.trending_up,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.watchProgressCard: const CommonWidgetMetadata(
      id: CommonWidgetId.watchProgressCard,
      name: '观看进度卡片',
      description: '显示用户观看进度、当前/总数和观看项目列表',
      icon: Icons.play_circle_outline,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.stressLevelMonitor: const CommonWidgetMetadata(
      id: CommonWidgetId.stressLevelMonitor,
      name: '压力水平监测',
      description: '显示当前压力分数、状态描述和每周7天的柱状图数据，支持动画效果',
      icon: Icons.psychology_outlined,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.dailyTodoListCard: const CommonWidgetMetadata(
      id: CommonWidgetId.dailyTodoListCard,
      name: '每日待办事项卡片',
      description: '显示日期、时间和待办任务列表，支持任务切换和提醒信息',
      icon: Icons.check_circle_outline,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.upcomingTasksWidget: const CommonWidgetMetadata(
      id: CommonWidgetId.upcomingTasksWidget,
      name: '即将到来的任务小组件',
      description: '显示任务计数、任务列表和更多任务数量，支持动画效果',
      icon: Icons.task_alt,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.profileCardCard: const CommonWidgetMetadata(
      id: CommonWidgetId.profileCardCard,
      name: '个人资料卡片',
      description: '展示用户个人信息，包括背景图、姓名、认证标志、简介和关注统计',
      icon: Icons.account_circle,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.sleepStageChartCard: const CommonWidgetMetadata(
      id: CommonWidgetId.sleepStageChartCard,
      name: '睡眠阶段图表',
      description: '展示睡眠阶段的可视化图表，支持动画效果和时间范围选择',
      icon: Icons.bedtime_outlined,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.splitImageCard: const CommonWidgetMetadata(
      id: CommonWidgetId.splitImageCard,
      name: '图片分割卡片',
      description: '左右分屏布局的卡片组件，左侧展示图片，右侧展示信息',
      icon: Icons.image,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.socialProfileCard: const CommonWidgetMetadata(
      id: CommonWidgetId.socialProfileCard,
      name: '社交资料卡片',
      description: '显示用户头像、名称、账号、标签、内容和社交统计数据',
      icon: Icons.person,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.miniTrendCard: const CommonWidgetMetadata(
      id: CommonWidgetId.miniTrendCard,
      name: '迷你趋势卡片',
      description: '显示标题、图标、当前数值、单位、副标题、星期标签和趋势折线图',
      icon: Icons.show_chart,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.accountBalanceCard: const CommonWidgetMetadata(
      id: CommonWidgetId.accountBalanceCard,
      name: '账户余额卡片',
      description: '显示多个账户的余额信息，包括账户名称、图标、账单数量和余额，支持正负余额显示和入场动画效果',
      icon: Icons.account_balance,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.modernRoundedSpendingWidget: const CommonWidgetMetadata(
      id: CommonWidgetId.modernRoundedSpendingWidget,
      name: '现代圆角消费卡片',
      description: '显示当前消费、预算、分类进度条和分类列表，支持动画效果',
      icon: Icons.payments_outlined,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.walletBalanceCard: const CommonWidgetMetadata(
      id: CommonWidgetId.walletBalanceCard,
      name: '钱包余额概览卡片',
      description: '显示钱包余额、可用余额、收入支出统计和操作按钮，支持动画效果',
      icon: Icons.account_balance_wallet,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.scoreCardWidget: const CommonWidgetMetadata(
      id: CommonWidgetId.scoreCardWidget,
      name: '分数卡片',
      description: '显示分数、等级和行为列表，支持翻转计数动画和渐变背景',
      icon: Icons.scoreboard,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.trendValueCard: const CommonWidgetMetadata(
      id: CommonWidgetId.trendValueCard,
      name: '趋势数值卡片',
      description:
          '通用的数值展示卡片，支持数值和单位显示（带翻转动画）、趋势指示（上升/下降）、曲线图表（带渐变填充）和附加信息（日期、BMI等）',
      icon: Icons.trending_up,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.trendListCard: const CommonWidgetMetadata(
      id: CommonWidgetId.trendListCard,
      name: '趋势列表卡片',
      description: '股票/指数价格与涨跌幅列表卡片，支持多个趋势项展示，带翻转计数动画和入场效果',
      icon: Icons.trending_up,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.modernEgfrHealthWidget: const CommonWidgetMetadata(
      id: CommonWidgetId.modernEgfrHealthWidget,
      name: '健康指标卡片',
      description: '通用的健康指标展示卡片，支持标题、图标、数值（带翻转动画）、单位和状态指示器',
      icon: Icons.favorite,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.newsUpdateCard: const CommonWidgetMetadata(
      id: CommonWidgetId.newsUpdateCard,
      name: '新闻更新卡片',
      description: '显示新闻标题、时间戳和分页指示器，支持动画效果',
      icon: Icons.newspaper,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.newsCard: const CommonWidgetMetadata(
      id: CommonWidgetId.newsCard,
      name: '新闻卡片',
      description: '显示头条新闻、分类标签和新闻列表，支持动画效果',
      icon: Icons.article,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),

    CommonWidgetId.moodChartCard: const CommonWidgetMetadata(
      id: CommonWidgetId.moodChartCard,
      name: '心情图表卡片',
      description: '显示每日情绪柱状图和每周心情历史记录，支持动画效果和多种心情表情',
      icon: Icons.sentiment_satisfied_alt,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.dailyEventsCard: CommonWidgetMetadata(
      id: CommonWidgetId.dailyEventsCard,
      name: '每日事件卡片',
      description: '显示星期、日期和当日事件列表，支持翻转计数动画',
      icon: Icons.event,
      defaultSize: Large3Size(),
      supportedSizes: const [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.dailyReflectionCard: const CommonWidgetMetadata(
      id: CommonWidgetId.dailyReflectionCard,
      name: '每日反思卡片',
      description: '引导用户每日思考和记录的卡片，包含星期几、引导性问题和操作按钮',
      icon: Icons.lightbulb_outline,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.colorfulShortcutsGrid: const CommonWidgetMetadata(
      id: CommonWidgetId.colorfulShortcutsGrid,
      name: '彩色快捷方式网格',
      description: '显示带颜色背景的快捷方式网格，支持动画效果和自定义图标',
      icon: Icons.grid_view,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.journalPromptCard: const CommonWidgetMetadata(
      id: CommonWidgetId.journalPromptCard,
      name: '日记提示卡片',
      description: '显示星期几、提示性问题和操作按钮（新建、同步），支持动画效果和自定义蝴蝶图标',
      icon: Icons.book,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.socialActivityCard: const CommonWidgetMetadata(
      id: CommonWidgetId.socialActivityCard,
      name: '社交活动动态卡片',
      description: '显示用户头像、名称、关注数和社交动态列表，支持翻转计数动画和互动数据',
      icon: Icons.people,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.monthlyBillCard: const CommonWidgetMetadata(
      id: CommonWidgetId.monthlyBillCard,
      name: '月度账单卡片',
      description: '显示月度账单信息，包括收入、支出和结余，支持翻转计数动画和入场效果',
      icon: Icons.receipt_long,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.timelineStatusCard: const CommonWidgetMetadata(
      id: CommonWidgetId.timelineStatusCard,
      name: '时间线状态卡片',
      description: '显示位置、标题、描述和时间线进度，支持动画效果和网格背景',
      icon: Icons.timeline,
      defaultSize: MediumSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.spendingTrendChart: const CommonWidgetMetadata(
      id: CommonWidgetId.spendingTrendChart,
      name: '支出趋势折线图',
      description: '显示支出趋势对比的折线图卡片，支持当前月与上月对比、预算线显示和平滑曲线动画',
      icon: Icons.show_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.modernRoundedMoodWidget: const CommonWidgetMetadata(
      id: CommonWidgetId.modernRoundedMoodWidget,
      name: '现代化心情追踪',
      description: '周视图柱状图显示每日心情值，支持积极/消极情绪区分、7天心情历史和当前日期高亮',
      icon: Icons.sentiment_satisfied_alt,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.dailyScheduleCard: const CommonWidgetMetadata(
      id: CommonWidgetId.dailyScheduleCard,
      name: '每日日程卡片',
      description: '显示日期、今日活动和明日活动列表，支持时间活动和全天活动',
      icon: Icons.event,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.articleListCard: const CommonWidgetMetadata(
      id: CommonWidgetId.articleListCard,
      name: '文章列表卡片',
      description: '显示特色文章和普通文章列表，支持图片展示和动画效果',
      icon: Icons.article,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.eventCalendarWidget: const CommonWidgetMetadata(
      id: CommonWidgetId.eventCalendarWidget,
      name: '日历事件小组件',
      description: '显示日期、周日历和事件列表，支持活动计数和提醒信息',
      icon: Icons.calendar_today,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.roundedTaskProgressWidget: const CommonWidgetMetadata(
      id: CommonWidgetId.roundedTaskProgressWidget,
      name: '圆角任务进度小组件',
      description: '显示项目标题、进度条、待办任务列表、评论数、附件数和团队成员头像',
      icon: Icons.task_alt,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.dualRangeChartCard: const CommonWidgetMetadata(
      id: CommonWidgetId.dualRangeChartCard,
      name: '双范围图表统计卡片',
      description: '显示双范围柱状图，支持日期选择、周视图和范围汇总数据',
      icon: Icons.bar_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.dailyBarChartCard: const CommonWidgetMetadata(
      id: CommonWidgetId.dailyBarChartCard,
      name: '每日条形图卡片',
      description: '显示每日数据条形图，支持标题、副标题、数值显示和多种颜色',
      icon: Icons.bar_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.nutritionProgressCard: const CommonWidgetMetadata(
      id: CommonWidgetId.nutritionProgressCard,
      name: '营养进度卡片',
      description: '显示卡路里和营养素（蛋白质、碳水化合物、脂肪）进度，支持动画计数',
      icon: Icons.restaurant,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.portfolioStackedChart: const CommonWidgetMetadata(
      id: CommonWidgetId.portfolioStackedChart,
      name: '投资组合堆叠图',
      description: '显示投资组合的堆叠柱状图，支持多种资产类型和月度数据展示',
      icon: Icons.show_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.activityRingsCard: const CommonWidgetMetadata(
      id: CommonWidgetId.activityRingsCard,
      name: '活动圆环卡片',
      description: '显示活动圆环（步数、卡路里等），支持日期和状态显示',
      icon: Icons.fitness_center,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.categoryStackWidget: CommonWidgetMetadata(
      id: CommonWidgetId.categoryStackWidget,
      name: '分类堆叠消费卡片',
      description: '显示分类消费堆叠图，支持当前金额、目标金额和分类列表',
      icon: Icons.pie_chart,
      defaultSize: Large3Size(),
      supportedSizes: const [LargeSize()],
    ),
    CommonWidgetId.performanceBarChart: CommonWidgetMetadata(
      id: CommonWidgetId.performanceBarChart,
      name: '性能指标柱状图',
      description: '显示性能指标柱状图，支持增长百分比和时间周期',
      icon: Icons.bar_chart,
      defaultSize: Large3Size(),
      supportedSizes: const [LargeSize()],
    ),
    CommonWidgetId.rankedBarChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.rankedBarChartCard,
      name: '排名条形图卡片',
      description: '显示排名条形图列表，支持标题、副标题、条目计数和页脚文本',
      icon: Icons.bar_chart,
      defaultSize: Large3Size(),
      supportedSizes: const [LargeSize()],
    ),
    CommonWidgetId.rentalPreviewCard: const CommonWidgetMetadata(
      id: CommonWidgetId.rentalPreviewCard,
      name: '租赁预览卡片',
      description: '显示租赁信息的卡片，包含图片、标题、评分、描述和时间',
      icon: Icons.home_work,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.roundedPropertyCard: const CommonWidgetMetadata(
      id: CommonWidgetId.roundedPropertyCard,
      name: '圆角属性卡片',
      description: '显示房地产属性的卡片，包含图片、标题、元数据和描述',
      icon: Icons.home,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.taskListStatCard: const CommonWidgetMetadata(
      id: CommonWidgetId.taskListStatCard,
      name: '任务统计列表卡片',
      description: '显示任务统计和列表的卡片，包含图标、计数和任务列表',
      icon: Icons.format_list_bulleted,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.verticalPropertyCard: const CommonWidgetMetadata(
      id: CommonWidgetId.verticalPropertyCard,
      name: '垂直属性卡片',
      description: '显示属性信息的垂直卡片，包含图片、标题、元数据和操作按钮',
      icon: Icons.home_outlined,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.taskProgressList: const CommonWidgetMetadata(
      id: CommonWidgetId.taskProgressList,
      name: '任务进度列表',
      description: '显示任务进度列表，包含任务标题、时间和进度条',
      icon: Icons.task_alt,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.sleepDurationCard: const CommonWidgetMetadata(
      id: CommonWidgetId.sleepDurationCard,
      name: '睡眠时长统计卡片',
      description: '显示睡眠时长、趋势和睡眠周期可视化',
      icon: Icons.bedtime_outlined,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.moodTrackerCard: const CommonWidgetMetadata(
      id: CommonWidgetId.moodTrackerCard,
      name: '心情追踪卡片',
      description: '显示情绪记录和每周情绪数据',
      icon: Icons.sentiment_satisfied_alt,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.habitStreakTrackerCard: const CommonWidgetMetadata(
      id: CommonWidgetId.habitStreakTrackerCard,
      name: '习惯连续追踪卡片',
      description: '显示习惯打卡连续天数、最佳记录、里程碑和日期网格',
      icon: Icons.local_fire_department,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.monthlyDotTrackerCard: const CommonWidgetMetadata(
      id: CommonWidgetId.monthlyDotTrackerCard,
      name: '月度点追踪卡片',
      description: '显示当月的签到状态点阵、进度统计和状态标签',
      icon: Icons.calendar_month,
      defaultSize: Large3Size(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.checkinItemCard: const CommonWidgetMetadata(
      id: CommonWidgetId.checkinItemCard,
      name: '签到项目卡片',
      description: '显示签到项目的图标、名称、今日打卡状态和热力图',
      icon: Icons.checklist,
      defaultSize: MediumSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.activityHeatmapCard: const CommonWidgetMetadata(
      id: CommonWidgetId.activityHeatmapCard,
      name: '活动热力图卡片',
      description: '展示今日24小时的活动热力图，支持不同时间粒度（5/10/15/30/60分钟）',
      icon: Icons.grid_on,
      defaultSize: Large3Size(),
      supportedSizes: [Large3Size()],
    ),
    CommonWidgetId.activityTodayPieChartCard: const CommonWidgetMetadata(
      id: CommonWidgetId.activityTodayPieChartCard,
      name: '今日活动统计卡片',
      description: '使用饼状图展示今日活动统计，按标签统计时长',
      icon: Icons.pie_chart,
      defaultSize: Large3Size(),
      supportedSizes: [Large3Size()],
    ),
    CommonWidgetId.timelineScheduleCard: const CommonWidgetMetadata(
      id: CommonWidgetId.timelineScheduleCard,
      name: '时间线日程卡片',
      description: '显示今天和昨天的活动日程，支持动画效果',
      icon: Icons.timeline,
      defaultSize: Large3Size(),
      supportedSizes: [Large3Size()],
    ),
    CommonWidgetId.bloodPressureTracker: const CommonWidgetMetadata(
      id: CommonWidgetId.bloodPressureTracker,
      name: '双数值追踪卡片',
      description: '显示两个关联数值和周趋势柱状图，适用于血压、血糖等健康指标',
      icon: Icons.water_drop,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.trendLineChartCard: const CommonWidgetMetadata(
      id: CommonWidgetId.trendLineChartCard,
      name: '趋势折线图卡片',
      description: '带动画效果的折线图组件，支持显示标题、图标、数值和时间轴标签',
      icon: Icons.show_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.modernRoundedBalanceCard: const CommonWidgetMetadata(
      id: CommonWidgetId.modernRoundedBalanceCard,
      name: '现代圆角余额卡片',
      description: '展示余额和可用额度，带有每周数据柱状图',
      icon: Icons.account_balance_wallet,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.barChartStatsCard: const CommonWidgetMetadata(
      id: CommonWidgetId.barChartStatsCard,
      name: '柱状图统计卡片',
      description: '显示统计数据和日期范围的柱状图，支持动画效果',
      icon: Icons.bar_chart,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.expenseComparisonChart: const CommonWidgetMetadata(
      id: CommonWidgetId.expenseComparisonChart,
      name: '支出对比图表',
      description: '显示本月与上月对比，双数据系列柱状图',
      icon: Icons.compare_arrows,
      defaultSize: Large3Size(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.weeklyDiaryWidget: CommonWidgetMetadata(
      id: CommonWidgetId.weeklyDiaryWidget,
      name: '七日周报小组件',
      description: '显示本周七天日记的概览，包括日期、心情和标题',
      icon: Icons.calendar_view_week,
      defaultSize: Wide2Size(),
      supportedSizes: [const WideSize(), const Wide2Size()],
    ),
    CommonWidgetId.activityLastActivity: CommonWidgetMetadata(
      id: CommonWidgetId.activityLastActivity,
      name: '上次活动小组件',
      description: '显示距离上次活动经过的时间和上次活动的时间',
      icon: Icons.history,
      defaultSize: MediumSize(),
      supportedSizes: [MediumSize()],
    ),
    CommonWidgetId.folderNotesCard: CommonWidgetMetadata(
      id: CommonWidgetId.folderNotesCard,
      name: '文件夹笔记卡片',
      description: '显示文件夹名称和最近的笔记列表',
      icon: Icons.folder_open,
      defaultSize: LargeSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.goodsItemSelector: CommonWidgetMetadata(
      id: CommonWidgetId.goodsItemSelector,
      name: '物品选择器',
      description: '显示单个或多个物品信息，支持列表和网格视图',
      icon: Icons.inventory_2,
      defaultSize: MediumSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.habitHeatmapCard: CommonWidgetMetadata(
      id: CommonWidgetId.habitHeatmapCard,
      name: '习惯热力图卡片',
      description: '显示习惯的每日热力图，支持过去7天和当月两种视图模式',
      icon: Icons.grid_on,
      defaultSize: MediumSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.pointsGoalCard: CommonWidgetMetadata(
      id: CommonWidgetId.pointsGoalCard,
      name: '积分目标进度',
      description: '显示今日积分与目标的进度',
      icon: Icons.flag,
      defaultSize: MediumSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.storeProductSelector: CommonWidgetMetadata(
      id: CommonWidgetId.storeProductSelector,
      name: '商品选择器',
      description: '显示商品列表，支持单个或多个商品展示',
      icon: Icons.shopping_bag,
      defaultSize: LargeSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.storeUserItemSelector: CommonWidgetMetadata(
      id: CommonWidgetId.storeUserItemSelector,
      name: '用户物品选择器',
      description: '显示用户物品列表，支持单个或多个物品展示',
      icon: Icons.inventory_2,
      defaultSize: MediumSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.notebookListCard: CommonWidgetMetadata(
      id: CommonWidgetId.notebookListCard,
      name: '笔记本列表卡片',
      description: '显示笔记本和节点列表，支持展开/折叠',
      icon: Icons.book,
      defaultSize: LargeSize(),
      supportedSizes: [const LargeSize(), const Large3Size()],
    ),
    CommonWidgetId.nodeStatsCard: CommonWidgetMetadata(
      id: CommonWidgetId.nodeStatsCard,
      name: '节点统计卡片',
      description: '显示节点统计信息（总数、待办、进行中、已完成）',
      icon: Icons.bar_chart,
      defaultSize: LargeSize(),
      supportedSizes: [const LargeSize(), const Large3Size()],
    ),
    CommonWidgetId.todoNodesList: CommonWidgetMetadata(
      id: CommonWidgetId.todoNodesList,
      name: '待办节点列表',
      description: '显示所有待办节点列表',
      icon: Icons.check_circle_outline,
      defaultSize: LargeSize(),
      supportedSizes: [const LargeSize(), const Large3Size()],
    ),
    CommonWidgetId.recentContactCard: CommonWidgetMetadata(
      id: CommonWidgetId.recentContactCard,
      name: '最近联系人卡片',
      description: '显示最近30天内的联系人列表',
      icon: Icons.people,
      defaultSize: MediumSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.contactCard: CommonWidgetMetadata(
      id: CommonWidgetId.contactCard,
      name: '联系人卡片',
      description: '显示联系人信息（头像、姓名、最后联系时间、标签）',
      icon: Icons.person,
      defaultSize: MediumSize(),
      supportedSizes: [MediumSize(), LargeSize()],
    ),
    CommonWidgetId.timerCard: CommonWidgetMetadata(
      id: CommonWidgetId.timerCard,
      name: '计时器卡片',
      description: '显示计时器任务卡片，支持播放/暂停/重置功能',
      icon: Icons.timer,
      defaultSize: LargeSize(),
      supportedSizes: [LargeSize()],
    ),
    CommonWidgetId.habitCard: CommonWidgetMetadata(
      id: CommonWidgetId.habitCard,
      name: '习惯卡片',
      description: '显示习惯的打卡记录、统计和计时状态',
      icon: Icons.auto_awesome,
      defaultSize: LargeSize(),
      supportedSizes: [LargeSize()],
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
  ///
  /// 如果 props 中包含 `_pixelCategory`，会根据像素尺寸创建有效的 size，
  /// 使公共组件能响应窗口大小变化。
  static Widget build(
    BuildContext context,
    CommonWidgetId widgetId,
    Map<String, dynamic> props,
    HomeWidgetSize size, {
    bool inline = false,
  }) {
    // 将 inline 参数添加到 props 中，以便各个小组件可以读取
    final finalProps = Map<String, dynamic>.from(props);
    finalProps['inline'] = inline;

    // 如果 props 中有 _pixelCategory，使用它创建基于像素尺寸的有效 size
    // 这样公共组件可以根据实际像素尺寸调整布局
    final pixelCategory = props['_pixelCategory'] as SizeCategory?;
    final effectiveSize =
        pixelCategory != null
            ? HomeWidgetSize.fromCategory(pixelCategory)
            : size;

    switch (widgetId) {
      case CommonWidgetId.circularProgressCard:
        return CircularProgressCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.iconCircularProgressCard:
        return IconCircularProgressCardWidget.fromProps(
          finalProps,
          effectiveSize,
        );
      case CommonWidgetId.colorTagTaskCard:
        return ColorTagTaskCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.activityProgressCard:
        return CardDotProgressDisplay.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.halfGaugeCard:
        return HalfGaugeCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.taskProgressCard:
        return TaskProgressCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.taskListCard:
        return TaskListCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.audioWaveformCard:
        return AudioWaveformCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.segmentedProgressCard:
        return SegmentedProgressCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.milestoneCard:
        return MilestoneCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.monthlyProgressDotsCard:
        return MonthlyProgressWithDotsCardWidget.fromProps(
          finalProps,
          effectiveSize,
        );
      case CommonWidgetId.multiMetricProgressCard:
        return MultiMetricProgressCardWidget.fromProps(
          finalProps,
          effectiveSize,
        );
      case CommonWidgetId.circularMetricsCard:
        return CircularMetricsCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.smoothLineChartCard:
        return SmoothLineChartCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.lineChartTrendCard:
        return LineChartTrendCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.verticalBarChartCard:
        return VerticalBarChartCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.inboxMessageCard:
        return InboxMessageCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.roundedTaskListCard:
        return RoundedTaskListCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.roundedRemindersList:
        return ReminderListCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.dualSliderCard:
        return DualSliderWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.earningsTrendCard:
        return EarningsTrendCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.revenueTrendCard:
        return RevenueTrendCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.watchProgressCard:
        return WatchProgressCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.stressLevelMonitor:
        return CardBarChartMonitor.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.dailyTodoListCard:
        return DailyTodoListWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.upcomingTasksWidget:
        return UpcomingTasksWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.splitImageCard:
        return SplitImageCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.profileCardCard:
        return ProfileCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.sleepStageChartCard:
        return CardBubbleChartDisplay.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.imageDisplayCard:
        return ImageDisplayCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.weightTrendChart:
        return CardTrendLineChart.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.socialProfileCard:
        return SocialProfileCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.miniTrendCard:
        return MiniTrendCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.accountBalanceCard:
        return AccountBalanceCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.modernRoundedSpendingWidget:
        return ModernRoundedSpendingWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.walletBalanceCard:
        return WalletBalanceCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.scoreCardWidget:
        return ScoreCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.trendValueCard:
        return TrendValueCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.trendListCard:
        return TrendListCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.newsUpdateCard:
        return NewsUpdateCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.newsCard:
        return NewsCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.modernEgfrHealthWidget:
        return ModernFlipCounterCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.moodChartCard:
        return ChartIconDisplayCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.dailyEventsCard:
        return DailyEventsCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.dailyReflectionCard:
        return DailyReflectionCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.colorfulShortcutsGrid:
        return ColorfulShortcutsGridWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.journalPromptCard:
        return JournalPromptCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.socialActivityCard:
        return SocialActivityCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.monthlyBillCard:
        return MonthlyBillCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.timelineStatusCard:
        return TimelineStatusCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.spendingTrendChart:
        return SpendingTrendChartWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.modernRoundedMoodWidget:
        return ModernRoundedBarIconCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.dailyScheduleCard:
        return DailyScheduleCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.articleListCard:
        return ArticleListCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.eventCalendarWidget:
        return EventCalendarWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.roundedTaskProgressWidget:
        return RoundedTaskProgressWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.dualRangeChartCard:
        return DualRangeChartCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.dailyBarChartCard:
        return DailyBarChartCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.nutritionProgressCard:
        return SplitColumnProgressBarCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.portfolioStackedChart:
        return PortfolioStackedChartWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.activityRingsCard:
        return ActivityRingsCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.categoryStackWidget:
        return CategoryStackWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.performanceBarChart:
        return PerformanceBarChartWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.rankedBarChartCard:
        return RankedBarChartCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.rentalPreviewCard:
        return RentalPreviewCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.roundedPropertyCard:
        return RoundedPropertyCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.taskListStatCard:
        return TaskListStatCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.verticalPropertyCard:
        return VerticalPropertyCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.taskProgressList:
        return TaskProgressListWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.sleepDurationCard:
        return DarkBarChartCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.moodTrackerCard:
        return CardEmojiIconDisplay.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.habitStreakTrackerCard:
        return HabitStreakTrackerCardWidget.fromProps(
          finalProps,
          effectiveSize,
        );
      case CommonWidgetId.monthlyDotTrackerCard:
        return MonthlyDotTrackerCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.checkinItemCard:
        return CheckinItemCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.activityHeatmapCard:
        return ActivityHeatmapCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.activityTodayPieChartCard:
        return ActivityTodayPieChartCardWidget.fromProps(
          finalProps,
          effectiveSize,
        );
      case CommonWidgetId.timelineScheduleCard:
        return TimelineScheduleCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.bloodPressureTracker:
        return DualValueTrackerCardWrapper.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.trendLineChartCard:
        return TrendLineChartCardWrapper.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.modernRoundedBalanceCard:
        return ModernRoundedBalanceCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.barChartStatsCard:
        return BarChartStatsCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.expenseComparisonChart:
        return ExpenseComparisonChartCardWidget.fromProps(
          finalProps,
          effectiveSize,
        );
      case CommonWidgetId.weeklyDiaryWidget:
        return WeeklyDiaryWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.activityLastActivity:
        return ActivityLastActivityWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.folderNotesCard:
        return FolderNotesCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.goodsItemSelector:
        return GoodsItemSelectorWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.habitHeatmapCard:
        return HabitHeatmapCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.pointsGoalCard:
        return PointsGoalCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.storeProductSelector:
        return StoreProductSelectorCardWidget.fromProps(
          finalProps,
          effectiveSize,
        );
      case CommonWidgetId.storeUserItemSelector:
        return StoreUserItemSelectorCardWidget.fromProps(
          finalProps,
          effectiveSize,
        );
      case CommonWidgetId.notebookListCard:
        return NotebookListCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.nodeStatsCard:
        return NodeStatsCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.todoNodesList:
        return TodoNodesListWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.contactCard:
        return ContactCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.recentContactCard:
        return RecentContactCardWidget.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.habitCard:
        return HabitCard.fromProps(finalProps, effectiveSize);
      case CommonWidgetId.timerCard:
        return TimerCardWidget.fromProps(finalProps, effectiveSize);
    }
  }
}
