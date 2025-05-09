
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/record.dart';
import '../controllers/tracker_controller.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final TrackerController controller;
  final VoidCallback onTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = controller.calculateProgress(goal);
    final isCompleted = progress >= 1.0;
    final remainingDays = goal.dateSettings.endDate != null
        ? goal.dateSettings.endDate!.difference(DateTime.now()).inDays
        : null;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (isCompleted ? Colors.green : Theme.of(context).primaryColor).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            IconData(int.parse(goal.icon), fontFamily: 'MaterialIcons'),
                            size: 20,
                            color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showQuickRecordDialog(context),
                      ),
                      Checkbox(
                        value: isCompleted,
                        onChanged: (value) {
                          final newValue = value ?? false;
                          controller.updateGoal(
                            goal.id,
                            goal.copyWith(
                              currentValue: newValue ? goal.targetValue : 0,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.currentValue.toStringAsFixed(1)}/${goal.targetValue}${goal.unitType}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (remainingDays != null)
                    Text(
                      remainingDays > 0 
                          ? '剩余$remainingDays天' 
                          : '已过期',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: remainingDays <= 0 ? Colors.red : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickRecordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final recordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Form(
          key: formKey,
          child: AlertDialog(
            title: Text('快速记录 - ${goal.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: recordController,
                  decoration: InputDecoration(
                    labelText: '记录值 (${goal.unitType})',
                    hintText: '请输入要增加的数值',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入记录值';
                    }
                    if (double.tryParse(value) == null) {
                      return '请输入有效的数字';
                    }
                    return null;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final recordValue = double.parse(recordController.text);
                    controller.addRecord(
                      Record(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        goalId: goal.id,
                        value: recordValue,
                        recordedAt: DateTime.now(),
                        note: null,
                      ),
                      goal,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        );
      },
    );
  }
}
