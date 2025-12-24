import 'package:flutter/material.dart';
import 'package:Memento/widgets/route_history_dialog/route_history_dialog.dart';

/// 路由历史对话框示例
class RouteHistoryExample extends StatelessWidget {
  const RouteHistoryExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('路由历史对话框'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RouteHistoryDialog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个路由历史对话框组件，用于显示和导航历史记录。'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showRouteHistory(context),
                icon: const Icon(Icons.history),
                label: const Text('查看路由历史'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRouteHistory(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const RouteHistoryDialog(),
    );
  }
}
