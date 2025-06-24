import 'package:flutter/material.dart' hide ListTile, Row, Center, SizedBox;
import 'package:flutter/material.dart'
    as flutter
    show ListTile, Row, Center, SizedBox;
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/models/record.dart';
import 'package:Memento/plugins/tracker/controllers/tracker_controller.dart';
import 'package:Memento/plugins/tracker/widgets/goal_edit_page.dart';
import 'package:Memento/plugins/tracker/widgets/record_dialog.dart';
import 'package:provider/provider.dart';

class GoalDetailScreen extends StatelessWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackerController>(
      builder: (context, controller, child) {
        final currentValue =
            controller.goals.firstWhere((g) => g.id == goal.id).currentValue;
        final isCompleted = currentValue >= goal.targetValue;

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('确认清空'),
                          content: const Text('确定要清空所有记录吗？此操作不可撤销。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('确认'),
                            ),
                          ],
                        ),
                  );
                  if (confirmed == true) {
                    await controller.clearRecordsForGoal(goal.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('记录已清空')));
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              GoalEditPage(controller: controller, goal: goal),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '目标: ${goal.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const flutter.SizedBox(height: 16),
                LinearProgressIndicator(
                  value: controller.calculateProgress(goal),
                  backgroundColor: Colors.grey[200],
                  color:
                      isCompleted
                          ? Colors.green
                          : goal.progressColor != null
                          ? Color(goal.progressColor!)
                          : Theme.of(context).primaryColor,
                ),
                const flutter.SizedBox(height: 16),
                Text('当前进度: $currentValue/${goal.targetValue}'),
                const flutter.SizedBox(height: 16),
                if (goal.reminderTime != null)
                  Text('提醒时间: ${goal.reminderTime}'),
                const flutter.SizedBox(height: 16),
                Text('记录历史', style: Theme.of(context).textTheme.titleMedium),
                const flutter.SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<Record>>(
                    future: controller.getRecordsForGoal(goal.id),
                    builder: (context, initialSnapshot) {
                      if (initialSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const flutter.Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return StreamBuilder<List<Record>>(
                        stream: controller.watchRecordsForGoal(goal.id),
                        initialData: initialSnapshot.data,
                        builder: (context, snapshot) {
                          final records = snapshot.data ?? [];
                          if (records.isEmpty) {
                            return const flutter.Center(child: Text('暂无记录'));
                          }
                          return ListView.builder(
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final record = records[index];
                              return flutter.ListTile(
                                title: Text('${record.value}'),
                                subtitle: Text(
                                  record.recordedAt
                                      .toLocal()
                                      .toString()
                                      .split('.')
                                      .first,
                                ),
                                trailing: flutter.Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(record.note ?? ''),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text('确认删除'),
                                                    content: const Text(
                                                      '确定要删除这条记录吗？',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text('取消'),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text('确认'),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                        if (confirmed == true) {
                                          await controller.deleteRecord(
                                            record.id,
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('记录已删除'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) =>
                        RecordDialog(goal: goal, controller: controller),
              );
            },
          ),
        );
      },
    );
  }
}
