import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'widgets/circular_progress_card.dart';
import 'widgets/activity_progress_card.dart';
import 'widgets/half_gauge_card.dart';
import 'widgets/task_progress_card.dart';
import 'widgets/audio_waveform_card.dart';
import 'widgets/line_chart_trend_card.dart';
import 'widgets/earnings_trend_card.dart';
import 'widgets/watch_progress_card.dart';
import 'widgets/weekly_sleep_tracker_card.dart';
import 'widgets/sleep_tracking_card_widget.dart';
import 'widgets/stress_level_monitor_card.dart';
import 'widgets/sleep_stage_chart_card.dart';
import 'widgets/weight_trend_chart.dart';
import 'widgets/image_display_card.dart';
import 'widgets/split_image_card.dart';
import '../screens/segmented_progress_card_example.dart';
import 'widgets/profile_card_card.dart';
import '../screens/milestone_card_example.dart';
import '../screens/monthly_progress_with_dots_card_example.dart';
import '../screens/multi_metric_progress_card_example.dart';
import '../screens/contribution_heatmap_card_example.dart';
import '../screens/smooth_line_chart_card_example.dart';
import '../screens/vertical_bar_chart_card_example.dart';
import '../screens/message_list_card_example.dart';
import '../screens/revenue_trend_card_example.dart';
import '../screens/dual_slider_widget_example.dart';
import '../screens/daily_todo_list_widget_example.dart';
import '../screens/upcoming_tasks_widget_example.dart';
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

/// 公共小组件 ID 枚举
enum CommonWidgetId {
  circularProgressCard,
  activityProgressCard,
  halfGaugeCard,
  taskProgressCard,
  audioWaveformCard,
  segmentedProgressCard,
  milestoneCard,
  monthlyProgressDotsCard,
  multiMetricProgressCard,
  contributionHeatmapCard,
  smoothLineChartCard,
  lineChartTrendCard,
  verticalBarChartCard,
  messageListCard,
  dualSliderCard,
  earningsTrendCard,
  revenueTrendCard,
  watchProgressCard,
  stressLevelMonitor,
  weeklySleepTrackerCard,
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
    CommonWidgetId.weeklySleepTrackerCard: CommonWidgetMetadata(
      id: CommonWidgetId.weeklySleepTrackerCard,
      name: '每周睡眠追踪',
      description: '显示总睡眠时长、状态标签和每周7天的进度环，支持动画效果',
      icon: Icons.bedtime_rounded,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
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
      case CommonWidgetId.activityProgressCard:
        return ActivityProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.halfGaugeCard:
        return HalfGaugeCardWidget.fromProps(props, size);
      case CommonWidgetId.taskProgressCard:
        return TaskProgressCardWidget.fromProps(props, size);
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
      case CommonWidgetId.dualSliderCard:
        return DualSliderWidget.fromProps(props, size);
      case CommonWidgetId.earningsTrendCard:
        return EarningsTrendCardWidget.fromProps(props, size);
      case CommonWidgetId.revenueTrendCard:
        return RevenueTrendCardWidget.fromProps(props, size);
      case CommonWidgetId.watchProgressCard:
        return WatchProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.sleepTrackingCard:
        return SleepTrackingCardWidget.fromProps(props, size);
      case CommonWidgetId.stressLevelMonitor:
        return StressLevelMonitorWidget.fromProps(props, size);
      case CommonWidgetId.weeklySleepTrackerCard:
        return WeeklySleepTrackerCardWidget.fromProps(props, size);
      case CommonWidgetId.dailyTodoListCard:
        return DailyTodoListWidget.fromProps(props, size);
      case CommonWidgetId.upcomingTasksWidget:
        return UpcomingTasksWidget.fromProps(props, size);
      case CommonWidgetId.splitImageCard:
        return SplitImageCardWidget.fromProps(props, size);
      case CommonWidgetId.profileCardCard:
        return ProfileCardWidget.fromProps(props, size);
      case CommonWidgetId.sleepStageChartCard:
        return SleepStageChartCardWidget.fromProps(props, size);
      case CommonWidgetId.imageDisplayCard:
        return ImageDisplayCardWidget.fromProps(props, size);
      case CommonWidgetId.weightTrendChart:
        return WeightTrendChartWidget.fromProps(props, size);
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
    }
  }
}
