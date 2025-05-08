
import 'package:flutter/material.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/models/record.dart';
import 'package:Memento/plugins/tracker/controllers/tracker_controller.dart';
import 'package:provider/provider.dart';

class GoalDetailScreen extends StatelessWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TrackerController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => controller.toggleGoalCompletion(goal.id),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目标: ${goal.name}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: controller.calculateProgress(goal),
              backgroundColor: Colors.grey[200],
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text('当前进度: ${goal.currentValue}/${goal.targetValue}${goal.unitType}'),
            const SizedBox(height: 16),
            if (goal.reminderTime != null)
              Text('提醒时间: ${goal.reminderTime}'),
            const Spacer(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // TODO: 实现快速记录功能
          final record = Record(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            goalId: goal.id,
            value: 1, // 默认值
            recordedAt: DateTime.now(),
          );
          controller.addRecord(record, goal);
        },
      ),
    );
  }
}
