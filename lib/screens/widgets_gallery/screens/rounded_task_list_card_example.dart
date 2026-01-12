import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 圆角任务列表卡片示例
class RoundedTaskListCardExample extends StatelessWidget {
  const RoundedTaskListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆角任务列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: RoundedTaskListCard(
            tasks: [
              TaskListItem(
                title: 'Design mobile UI dashboard',
                subtitle: 'Widgefy UI kit',
                date: '12 Jan 2021',
              ),
              TaskListItem(
                title: 'Calculate budget and contract',
                subtitle: 'BetaCRM',
                date: '1 Feb 2021',
              ),
              TaskListItem(
                title: 'Search for a UI kit',
                subtitle: 'Cardify landing pack',
                date: '9 Mar 2021',
              ),
              TaskListItem(
                title: 'Design search page for website',
                subtitle: 'IOTask UI kit',
                date: '10 Feb 2021',
              ),
              TaskListItem(
                title: 'Create HTML & CSS for startup',
                subtitle: 'Roomsfy',
                date: '21 Feb 2021',
              ),
            ],
            headerText: 'Upcoming',
          ),
        ),
      ),
    );
  }
}
