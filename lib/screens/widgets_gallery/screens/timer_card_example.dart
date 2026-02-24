import 'package:flutter/material.dart';
import 'package:Memento/plugins/timer/models/timer_task.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/widgets/common/timer_card_widget.dart';

/// TimerCard 示例
///
/// 展示如何使用 TimerCardWidget 组件
class TimerCardExample extends StatelessWidget {
  const TimerCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 创建示例计时器任务
    final timerTask = TimerTask.create(
      id: 'example-task-1',
      name: '工作专注计时',
      color: const Color(0xFF3B82F6),
      icon: Icons.work,
      timerItems: [
        TimerItem.countUp(
          name: '工作',
          targetDuration: const Duration(minutes: 25),
        ),
        TimerItem.countDown(name: '休息', duration: const Duration(minutes: 5)),
      ],
      repeatCount: 4,
      enableNotification: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('TimerCard 小组件示例'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TimerCard 小组件使用示例',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '展示计时器任务卡片，支持播放/暂停/重置功能',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // 基础用法
            const Text(
              '基础用法',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TimerCardWidget(
                task: timerTask,
                onTap: (task) {
                  // 点击进入详情页
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('点击了任务: ${task.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onEdit: (task) {
                  // 编辑任务
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('编辑任务: ${task.name}'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                onReset: (task) {
                  // 重置任务
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('重置任务: ${task.name}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                onDelete: (task) {
                  // 删除任务
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('删除任务: ${task.name}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // 自定义样式用法
            const Text(
              '自定义样式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TimerCardWidget(
                task: timerTask,
                borderColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFFF0FDF4),
                textColor: const Color(0xFF065F46),
                showActionButtons: false, // 隐藏操作按钮
                onTap: (task) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('点击了任务: ${task.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // JSON 配置示例
            const Text(
              'JSON 配置示例',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '在公共小组件系统中使用:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade100,
                    child: const Text.rich(
                      TextSpan(
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                        children: [
                          TextSpan(text: "{'timerCard': {\n"),
                          TextSpan(text: "  'task': {\n"),
                          TextSpan(text: "    'id': 'task-1',\n"),
                          TextSpan(text: "    'name': '任务名称',\n"),
                          TextSpan(text: "    'color': 0xFF3B82F6,\n"),
                          TextSpan(text: "    'icon': 58223,\n"),
                          TextSpan(text: "    'timerItems': [...],\n"),
                          TextSpan(text: "    'repeatCount': 1,\n"),
                          TextSpan(text: "    'isRunning': false,\n"),
                          TextSpan(text: "    'enableNotification': false\n"),
                          TextSpan(text: "  },\n"),
                          TextSpan(text: "  'showActionButtons': true,\n"),
                          TextSpan(text: "  'borderColor': 0xFF10B981,\n"),
                          TextSpan(text: "  'backgroundColor': 0xFFF0FDF4,\n"),
                          TextSpan(text: "  'textColor': 0xFF065F46\n"),
                          TextSpan(text: "}}\n"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
