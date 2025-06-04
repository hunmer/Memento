import 'dart:io';
import 'package:Memento/plugins/tracker/widgets/timer_dialog.dart';
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/record.dart';
import '../controllers/tracker_controller.dart';
import 'package:Memento/utils/image_utils.dart';

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
    final remainingDays =
        goal.dateSettings.endDate != null
            ? goal.dateSettings.endDate!.difference(DateTime.now()).inDays
            : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (goal.imagePath != null && goal.imagePath!.isNotEmpty)
            Positioned.fill(
              child: FutureBuilder<String>(
                future: ImageUtils.getAbsolutePath(goal.imagePath),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Image.file(
                      File(snapshot.data!),
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildBackgroundContainer(context, isCompleted),
                    );
                  }
                  return _buildBackgroundContainer(context, isCompleted);
                },
              ),
            )
          else
            Positioned.fill(
              child: _buildBackgroundContainer(context, isCompleted),
            ),
          InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            goal.imagePath != null && goal.imagePath!.isNotEmpty
                                ? FutureBuilder<String>(
                                  future: ImageUtils.getAbsolutePath(
                                    goal.imagePath,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data!.isNotEmpty) {
                                      return ClipOval(
                                        child: Image.file(
                                          File(snapshot.data!),
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildIconContainer(
                                                    context,
                                                    isCompleted,
                                                  ),
                                        ),
                                      );
                                    }
                                    return _buildIconContainer(
                                      context,
                                      isCompleted,
                                    );
                                  },
                                )
                                : _buildIconContainer(context, isCompleted),
                            const SizedBox(width: 12),
                            Text(
                              goal.name,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                decoration:
                                    isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(1.0, 1.0),
                                    blurRadius: 3.0,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () => _showQuickRecordDialog(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.timer, color: Colors.white),
                          onPressed: () => _startTimer(context),
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
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      color:
                          isCompleted
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${goal.currentValue.toStringAsFixed(1)}/${goal.targetValue}${goal.unitType}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                        if (remainingDays != null)
                          Text(
                            remainingDays > 0 ? '剩余$remainingDays天' : '已过期',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  remainingDays <= 0
                                      ? Colors.red
                                      : Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startTimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TimerDialog(goal: goal, controller: controller),
    );
  }

  Widget _buildIconContainer(BuildContext context, bool isCompleted) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          IconData(int.parse(goal.icon), fontFamily: 'MaterialIcons'),
          size: 20,
          color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildBackgroundContainer(BuildContext context, bool isCompleted) {
    return Container(
      decoration: BoxDecoration(
        color: (isCompleted ? Colors.green : Theme.of(context).primaryColor)
            .withOpacity(0.15),
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
