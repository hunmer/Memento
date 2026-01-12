import 'package:Memento/widgets/common/index.dart';
import 'package:flutter/material.dart';

/// 圆角提醒事项列表卡片示例
class RoundedRemindersListExample extends StatelessWidget {
  const RoundedRemindersListExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆角提醒事项列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: ReminderListCard(
            itemCount: 18,
            items: [
              ReminderItem(text: 'Pick up arts & crafts supplies'),
              ReminderItem(text: 'Send cookie recipe to Rigo'),
              ReminderItem(text: 'Book club prep'),
              ReminderItem(text: 'Hike with Darla'),
              ReminderItem(text: 'Schedule car maintenance'),
              ReminderItem(text: 'Cancel membership'),
              ReminderItem(text: 'Check spare tire'),
            ],
          ),
        ),
      ),
    );
  }
}
