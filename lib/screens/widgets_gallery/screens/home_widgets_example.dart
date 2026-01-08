import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/screens/half_circle_gauge_widget_example.dart';

/// 桌面小组件示例列表页面
///
/// 展示各种可用于桌面的小组件示例
class HomeWidgetsExample extends StatelessWidget {
  const HomeWidgetsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('桌面小组件示例'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, '统计图表类'),
          _buildListItem(
            context,
            icon: Icons.speed,
            title: '半圆形统计小组件',
            subtitle: 'HalfCircleGaugeWidget - 预算/进度显示',
            route: '/widgets_gallery/half_circle_gauge_widget',
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, '待开发'),
          _buildDisabledListItem(
            context,
            icon: Icons.calendar_today,
            title: '日历小组件',
            subtitle: 'CalendarWidget - 即将推出',
          ),
          _buildDisabledListItem(
            context,
            icon: Icons.check_circle,
            title: '待办事项小组件',
            subtitle: 'TodoWidget - 即将推出',
          ),
          _buildDisabledListItem(
            context,
            icon: Icons.timer,
            title: '计时器小组件',
            subtitle: 'TimerWidget - 即将推出',
          ),
          _buildDisabledListItem(
            context,
            icon: Icons.show_chart,
            title: '习惯追踪小组件',
            subtitle: 'HabitWidget - 即将推出',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
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
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  Widget _buildDisabledListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(
        title,
        style: const TextStyle(color: Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      enabled: false,
    );
  }
}
