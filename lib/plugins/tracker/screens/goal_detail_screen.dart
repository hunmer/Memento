
import 'package:flutter/material.dart';
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
    final controller = context.read<TrackerController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalEditPage(
                    controller: controller,
                    goal: goal,
                  ),
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
            const SizedBox(height: 16),
            Text('记录历史', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Record>>(
                future: controller.getRecordsForGoal(goal.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('暂无记录'));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final record = snapshot.data![index];
                      return ListTile(
                        title: Text('${record.value}${goal.unitType}'),
                        subtitle: Text(record.recordedAt.toLocal().toString()),
                        trailing: Text(record.note ?? ''),
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
            builder: (context) => RecordDialog(
              goal: goal,
              controller: controller,
            ),
          );
        },
      ),
    );
  }
}
