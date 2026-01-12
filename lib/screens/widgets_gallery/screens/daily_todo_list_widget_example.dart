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
        child: const Center(
          child: DailyTodoListWidget(
            date: 'Thu, 2 May 2024',
            time: '15:30',
            tasks: [
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
    );
  }
}
