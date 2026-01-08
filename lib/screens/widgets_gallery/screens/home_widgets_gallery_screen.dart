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
            icon: Icons.donut_large,
            title: '堆叠环形图统计卡片',
            subtitle: 'StackedRingChartWidget - 多类别环形图统计卡片',
            route: '/widgets_gallery/stacked_ring_chart',
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
