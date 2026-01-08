import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/routing/route_helpers.dart';

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
