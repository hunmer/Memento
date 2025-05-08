
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../controllers/tracker_controller.dart';
import 'record_dialog.dart';
import 'goal_edit_page.dart';

class GoalDetailPage extends StatelessWidget {
  final Goal goal;
  final TrackerController controller;

  const GoalDetailPage({
    super.key,
    required this.goal,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final records = controller.records
        .where((r) => r.goalId == goal.id)
        .toList()
        .reversed
        .toList();
    final progress = controller.calculateProgress(goal);

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditPage(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      IconData(int.parse(goal.icon), fontFamily: 'MaterialIcons'),
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${goal.targetValue}${goal.unitType}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% 完成',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return ListTile(
                  leading: Text(
                    '+${record.value}${goal.unitType}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text(
                    record.note ?? '无备注',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    _formatDateTime(record.recordedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showRecordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RecordDialog(
        goal: goal,
        controller: controller,
      ),
    );
  }

  void _navigateToEditPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalEditPage(
        controller: controller,
        goal: goal,
      ),
      ),
    );
  }
}
