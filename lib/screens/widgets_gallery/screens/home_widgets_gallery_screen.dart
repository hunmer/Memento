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
          _buildSectionHeader(context, '可用组件'),
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
            icon: Icons.flag,
            title: '里程碑追踪卡片',
            subtitle: 'MilestoneCard - 时间里程碑追踪展示卡片',
            route: '/widgets_gallery/milestone_card',
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
            icon: Icons.calendar_month,
            title: '月度进度圆点卡片',
            subtitle: 'MonthlyProgressWithDotsCard - 圆点矩阵月度进度卡片',
            route: '/widgets_gallery/monthly_progress_with_dots_card',
          ),
          _buildListItem(
            context,
            icon: Icons.dashboard,
            title: '多追踪器卡片',
            subtitle: 'MultiTrackerCard - 多指标追踪展示卡片',
            route: '/widgets_gallery/multi_tracker_card',
          ),
          _buildListItem(
            context,
            icon: Icons.show_chart,
            title: '折线图趋势卡片',
            subtitle: 'LineChartTrendCard - 折线图趋势统计卡片',
            route: '/widgets_gallery/line_chart_trend_card',
          ),
          _buildListItem(
            context,
            icon: Icons.article,
            title: '文章列表卡片',
            subtitle: 'ArticleListCard - 文章内容展示列表卡片',
            route: '/widgets_gallery/article_list_card',
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
            icon: Icons.thermostat,
            title: '趋势折线图',
            subtitle: 'TrendLineChartWidget - 平滑曲线趋势展示组件',
            route: '/widgets_gallery/trend_line_chart_widget',
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
            icon: Icons.trending_up,
            title: '收益趋势卡片',
            subtitle: 'EarningsTrendCard - 收益趋势与折线图展示卡片',
            route: '/widgets_gallery/earnings_trend_card',
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
            icon: Icons.show_chart,
            title: '平滑折线图卡片',
            subtitle: 'SmoothLineChartCard - 带渐变填充的平滑折线图卡片',
            route: '/widgets_gallery/smooth_line_chart_card',
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
            icon: Icons.graphic_eq,
            title: '音频波形小组件',
            subtitle: 'AudioWaveformWidget - 音频播放波形动画展示组件',
            route: '/widgets_gallery/audio_waveform_widget',
          ),
          _buildListItem(
            context,
            icon: Icons.access_time,
            title: '时区滑块小组件',
            subtitle: 'TimeZoneSliderWidget - 世界时区双滑块时间显示组件',
            route: '/widgets_gallery/time_zone_slider_widget',
          ),
          _buildListItem(
            context,
            icon: Icons.storage,
            title: '存储分段小组件',
            subtitle: 'StorageBreakdownWidget - 设备存储分段统计展示组件',
            route: '/widgets_gallery/storage_breakdown_widget',
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
            icon: Icons.play_circle,
            title: '观看进度卡片',
            subtitle: 'WatchProgressCard - 观看进度与历史记录展示卡片',
            route: '/widgets_gallery/watch_progress_card',
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
            icon: Icons.directions_run,
            title: '活动进度卡片',
            subtitle: 'ActivityProgressCard - 活动里程进度与点状进度卡片',
            route: '/widgets_gallery/activity_progress_card',
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
            icon: Icons.account_balance_wallet,
            title: '钱包余额概览卡片',
            subtitle: 'WalletBalanceCard - 钱包余额与收支统计卡片',
            route: '/widgets_gallery/wallet_balance_card',
          ),
          _buildListItem(
            context,
            icon: Icons.local_fire_department,
            title: '习惯连续打卡追踪器',
            subtitle: 'HabitStreakTracker - 连续打卡天数追踪展示组件',
            route: '/widgets_gallery/habit_streak_tracker',
          ),
          _buildListItem(
            context,
            icon: Icons.music_note,
            title: '音乐播放器卡片',
            subtitle: 'MusicPlayerCard - 音乐播放控制与歌词展示卡片',
            route: '/widgets_gallery/music_player_card',
          ),
          _buildListItem(
            context,
            icon: Icons.event,
            title: '日历事件卡片',
            subtitle: 'EventCalendarWidget - 日历事件周视图与提醒卡片',
            route: '/widgets_gallery/event_calendar_widget',
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
            icon: Icons.donut_large,
            title: '支出分类环形图',
            subtitle: 'ExpenseDonutChart - 支出类别环形统计图',
            route: '/widgets_gallery/expense_donut_chart',
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
            icon: Icons.pie_chart,
            title: '投资组合堆叠图',
            subtitle: 'PortfolioStackedChart - 资产配置堆叠柱状图',
            route: '/widgets_gallery/portfolio_stacked_chart',
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
            icon: Icons.favorite,
            title: '血压追踪器',
            subtitle: 'BloodPressureTracker - 血压数值与周趋势展示卡片',
            route: '/widgets_gallery/blood_pressure_tracker',
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
            icon: Icons.psychology,
            title: '压力水平监测卡片',
            subtitle: 'StressLevelMonitor - 压力分数与每周趋势追踪',
            route: '/widgets_gallery/stress_level_monitor',
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
            icon: Icons.check_circle,
            title: '每日待办事项卡片',
            subtitle: 'DailyTodoListWidget - 任务列表与提醒信息展示卡片',
            route: '/widgets_gallery/daily_todo_list_widget',
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
            icon: Icons.bar_chart,
            title: '双范围图表统计卡片',
            subtitle: 'DualRangeChartCard - 双数值范围周统计图表卡片',
            route: '/widgets_gallery/dual_range_chart_card',
          ),
          _buildListItem(
            context,
            icon: Icons.donut_large,
            title: '周点阵追踪卡片',
            subtitle: 'WeeklyDotTrackerCard - 周进度点阵追踪展示卡片',
            route: '/widgets_gallery/weekly_dot_tracker_card',
          ),
          _buildListItem(
            context,
            icon: Icons.show_chart,
            title: '迷你趋势卡片',
            subtitle: 'MiniTrendCard - 迷你折线图趋势展示卡片',
            route: '/widgets_gallery/mini_trend_card',
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
            icon: Icons.scoreboard,
            title: '分数卡片',
            subtitle: 'ScoreCardWidget - 分数与行为记录展示卡片',
            route: '/widgets_gallery/score_card_widget',
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
            icon: Icons.schedule,
            title: '时间线日程卡片',
            subtitle: 'TimelineScheduleCard - 双日时间线日程展示卡片',
            route: '/widgets_gallery/timeline_schedule_card',
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
            icon: Icons.today,
            title: '每日日程卡片',
            subtitle: 'DailyScheduleCard - 每日活动日程展示卡片',
            route: '/widgets_gallery/daily_schedule_card',
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
            icon: Icons.all_inclusive,
            title: '活动圆环卡片',
            subtitle: 'ActivityRingsCard - 活动进度圆环展示卡片',
            route: '/widgets_gallery/activity_rings_card',
          ),
          // 未来可以在这里添加更多桌面小组件示例
        ],
      ),
    );
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
