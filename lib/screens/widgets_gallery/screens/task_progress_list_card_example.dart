import 'package:Memento/widgets/common/index.dart';
import 'package:flutter/material.dart';

/// 任务进度列表卡片示例
class TaskProgressListCardExample extends StatelessWidget {
  const TaskProgressListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('任务进度列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: TaskProgressListCard(
                      tasks: [
                        TaskItem(
                          title: '设计移动端 UI 仪表板',
                          time: '24 分钟前',
                          progress: 1.0,
                          status: TaskStatus.completed,
                        ),
                        TaskItem(
                          title: '计算预算和合同',
                          time: '54 分钟前',
                          progress: 0.67,
                          status: TaskStatus.inProgress,
                        ),
                        TaskItem(
                          title: '搜索 UI 套件',
                          time: '54 分钟前',
                          progress: 1.0,
                          status: TaskStatus.completed,
                        ),
                        TaskItem(
                          title: '设计网站搜索页面',
                          time: '54 分钟前',
                          progress: 0.25,
                          status: TaskStatus.started,
                        ),
                        TaskItem(
                          title: '为初创公司创建 HTML 和 CSS',
                          time: '54 分钟前',
                          progress: 0.25,
                          status: TaskStatus.started,
                        ),
                      ],
                      moreCount: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: TaskProgressListCard(
                      tasks: [
                        TaskItem(
                          title: '设计移动端 UI 仪表板',
                          time: '24 分钟前',
                          progress: 1.0,
                          status: TaskStatus.completed,
                        ),
                        TaskItem(
                          title: '计算预算和合同',
                          time: '54 分钟前',
                          progress: 0.67,
                          status: TaskStatus.inProgress,
                        ),
                        TaskItem(
                          title: '搜索 UI 套件',
                          time: '54 分钟前',
                          progress: 1.0,
                          status: TaskStatus.completed,
                        ),
                        TaskItem(
                          title: '设计网站搜索页面',
                          time: '54 分钟前',
                          progress: 0.25,
                          status: TaskStatus.started,
                        ),
                        TaskItem(
                          title: '为初创公司创建 HTML 和 CSS',
                          time: '54 分钟前',
                          progress: 0.25,
                          status: TaskStatus.started,
                        ),
                      ],
                      moreCount: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: TaskProgressListCard(
                      tasks: [
                        TaskItem(
                          title: '设计移动端 UI 仪表板',
                          time: '24 分钟前',
                          progress: 1.0,
                          status: TaskStatus.completed,
                        ),
                        TaskItem(
                          title: '计算预算和合同',
                          time: '54 分钟前',
                          progress: 0.67,
                          status: TaskStatus.inProgress,
                        ),
                        TaskItem(
                          title: '搜索 UI 套件',
                          time: '54 分钟前',
                          progress: 1.0,
                          status: TaskStatus.completed,
                        ),
                        TaskItem(
                          title: '设计网站搜索页面',
                          time: '54 分钟前',
                          progress: 0.25,
                          status: TaskStatus.started,
                        ),
                        TaskItem(
                          title: '为初创公司创建 HTML 和 CSS',
                          time: '54 分钟前',
                          progress: 0.25,
                          status: TaskStatus.started,
                        ),
                      ],
                      moreCount: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
