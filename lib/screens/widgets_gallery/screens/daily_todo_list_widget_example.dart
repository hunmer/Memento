import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/daily_todo_list_widget.dart';

/// 每日待办事项卡片示例
class DailyTodoListWidgetExample extends StatelessWidget {
  const DailyTodoListWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每日待办事项卡片')),
      body: Container(
        color: isDark ? const Color(0xFF09090B) : const Color(0xFFF4F4F5),
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
                    height: 180,
                    child: DailyTodoListWidget(
                      date: 'Thu, 2 May 2024',
                      time: '15:30',
                      tasks: const [
                        TodoTask(title: 'Design a new shot', isCompleted: false),
                        TodoTask(title: 'Make a twitter post', isCompleted: true),
                      ],
                      reminder: const TodoReminder(
                        text: "Don't forget to",
                        hashtag: '#todo',
                        hashtagEmoji: 'today',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 250,
                    child: DailyTodoListWidget(
                      date: 'Thu, 2 May 2024',
                      time: '15:30',
                      tasks: const [
                        TodoTask(title: 'Design a new shot', isCompleted: false),
                        TodoTask(title: 'Make a twitter post', isCompleted: true),
                        TodoTask(title: 'Finish UI updates', isCompleted: false),
                        TodoTask(title: 'Drink water', isCompleted: true),
                      ],
                      reminder: const TodoReminder(
                        text: "Don't forget to",
                        hashtag: '#daily',
                        hashtagEmoji: 'goals',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 320,
                    child: DailyTodoListWidget(
                      date: 'Thu, 2 May 2024',
                      time: '15:30',
                      tasks: const [
                        TodoTask(title: 'Design a new shot', isCompleted: false),
                        TodoTask(title: 'Make a twitter post', isCompleted: true),
                        TodoTask(
                          title: 'Finish UI updates on the web app',
                          isCompleted: false,
                        ),
                        TodoTask(title: 'Drink water', isCompleted: true),
                        TodoTask(title: 'Grocery shopping', isCompleted: false),
                        TodoTask(title: 'Zoom call with Jordan', isCompleted: false),
                      ],
                      reminder: TodoReminder(
                        text: "Don't forget to do a",
                        hashtag: '#daily-ui',
                        hashtagEmoji: 'challenge!!!',
                      ),
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
