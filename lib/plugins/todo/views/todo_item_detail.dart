import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/plugins/todo/controllers/task_controller.dart';
import 'package:Memento/plugins/todo/widgets/task_form.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';

class TodoItemDetail extends StatefulWidget {
  final Task task;
  final TaskController taskController;
  final bool isReadOnly;

  const TodoItemDetail({
    super.key,
    required this.task,
    required this.taskController,
    this.isReadOnly = false,
  });

  @override
  State<TodoItemDetail> createState() => _TodoItemDetailState();
}

class _TodoItemDetailState extends State<TodoItemDetail> {
  Timer? _timer;
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    if (_task.status == TaskStatus.inProgress) {
      _startTimerUpdate();
    }
  }

  @override
  void didUpdateWidget(TodoItemDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task != oldWidget.task) {
      _task = widget.task;
      if (_task.status == TaskStatus.inProgress) {
        _startTimerUpdate();
      } else {
        _timer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Refresh UI to show updated duration
      });
    });
  }

  Color get _priorityColor {
    switch (_task.priority) {
      case TaskPriority.high:
        return Colors.red.shade400;
      case TaskPriority.medium:
        return Colors.orange.shade400;
      case TaskPriority.low:
        return Colors.green.shade400;
    }
  }

  Color get _priorityBgColor {
    switch (_task.priority) {
      case TaskPriority.high:
        return Colors.red.withOpacity(0.1);
      case TaskPriority.medium:
        return Colors.orange.withOpacity(0.1);
      case TaskPriority.low:
        return Colors.green.withOpacity(0.1);
    }
  }

  String get _priorityText {
    switch (_task.priority) {
      case TaskPriority.high:
        return '紧急且重要'; // Using simplified text based on html example, though logic might vary
      case TaskPriority.medium:
        return '重要';
      case TaskPriority.low:
        return '普通';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to controller changes to update the task object
    return AnimatedBuilder(
      animation: widget.taskController,
      builder: (context, child) {
        // Find the task in the controller's list to get the latest state
        try {
          if (widget.isReadOnly) {
            _task = widget.task;
          } else {
            _task = widget.taskController.tasks.firstWhere(
              (t) => t.id == widget.task.id,
            );
          }
        } catch (e) {
          if (widget.isReadOnly) {
            _task = widget.task;
          } else {
            // Task might have been deleted
            return const SizedBox.shrink();
          }
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Only take needed height
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black54,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Section
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _task.icon ?? Icons.work,
                                    color: Colors.red.shade400,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _task.title,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!widget.isReadOnly) ...[
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                if (_task.status == TaskStatus.inProgress) {
                                  // If running, complete the task (and stop timer)
                                  widget.taskController.updateTaskStatus(
                                    _task.id,
                                    TaskStatus.done,
                                  );
                                  _timer?.cancel();
                                } else {
                                  // If not running, start the timer
                                  widget.taskController.updateTaskStatus(
                                    _task.id,
                                    TaskStatus.inProgress,
                                  );
                                  _startTimerUpdate();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _task.status == TaskStatus.inProgress
                                          ? Colors.green // Green for "Complete" action
                                          : const Color(0xFF1392EC),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _task.status == TaskStatus.inProgress
                                          ? Icons.check
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _task.status == TaskStatus.inProgress
                                          ? '完成'
                                          : '开始',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_task.status == TaskStatus.inProgress)
                            _buildTag(
                              icon: Icons.circle,
                              text: '进行中',
                              color: Colors.blue.shade400,
                              bgColor: Colors.blue.withOpacity(0.1),
                              iconSize: 14,
                            ),
                          _buildTag(
                            icon: Icons.flag,
                            text: _priorityText,
                            color: _priorityColor,
                            bgColor: _priorityBgColor,
                            iconSize: 14,
                          ),
                          _buildTag(
                            icon: Icons.timer,
                            text: _task.formattedDuration,
                            color: Colors.black54,
                            bgColor: Colors.black.withOpacity(0.05),
                            iconSize: 14,
                          ),
                          ..._task.tags.map(
                            (tag) => _buildTag(
                              icon: Icons.label,
                              text: tag,
                              color: Colors.black54,
                              bgColor: Colors.black.withOpacity(0.05),
                              iconSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      if (_task.description != null &&
                          _task.description!.isNotEmpty)
                        Text(
                          _task.description!,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Subtasks
                      if (_task.subtasks.isNotEmpty) ...[
                        const Text(
                          '子任务',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._task.subtasks.map(
                          (subtask) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: subtask.isCompleted,
                                    onChanged: widget.isReadOnly ? null : (value) {
                                      if (value != null) {
                                        widget.taskController
                                            .updateSubtaskStatus(
                                              _task.id,
                                              subtask.id,
                                              value,
                                            );
                                      }
                                    },
                                    activeColor: const Color(0xFF1392EC),
                                    checkColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.black26,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    subtask.title,
                                    style: TextStyle(
                                      color:
                                          subtask.isCompleted
                                              ? Colors.black38
                                              : Colors.black87,
                                      fontSize: 16,
                                      decoration:
                                          subtask.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                      decorationColor: Colors.black38,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Add Subtask or Edit (Optional, based on "Edit" button in original dialog)
                      if (!widget.isReadOnly)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close detail first
                                NavigationHelper.push(
                                  context,
                                  TaskForm(
                                    task: _task,
                                    taskController: widget.taskController,
                                    reminderController:
                                        TodoPlugin.instance.reminderController,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, color: Colors.black54),
                              label: const Text(
                                '编辑任务',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 16),

                      // Metadata
                      _buildMetadataRow(
                        '创建日期',
                        DateFormat('yyyy年MM月dd日').format(_task.createdAt),
                      ),
                      if (_task.dueDate != null)
                        _buildMetadataRow(
                          '截止日期',
                          DateFormat('yyyy年MM月dd日').format(_task.dueDate!),
                        ),
                      // Assuming reminders is a list of DateTime
                      if (_task.reminders.isNotEmpty)
                        _buildMetadataRow(
                          '提醒日期',
                          DateFormat(
                            'yyyy年MM月dd日 HH:mm',
                          ).format(_task.reminders.first),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
    required double iconSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
