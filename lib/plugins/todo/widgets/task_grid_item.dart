import 'package:flutter/material.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class TaskGridItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(TaskStatus) onStatusChanged;

  const TaskGridItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 格式化日期
    final dateFormat = DateFormat('MMM d, yyyy');
    final dueDate = task.dueDate != null
        ? dateFormat.format(task.dueDate!)
        : 'No due date';
        
    // 检查是否过期
    final bool isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != TaskStatus.done;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.priorityColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: task.status == TaskStatus.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      task.statusIcon,
                      color: task.status == TaskStatus.done
                          ? Colors.green
                          : theme.disabledColor,
                    ),
                    onPressed: () {
                      // 循环切换状态
                      final newStatus = TaskStatus.values[
                          (task.status.index + 1) % TaskStatus.values.length];
                      onStatusChanged(newStatus);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (task.description != null && task.description!.isNotEmpty) ...[
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: isOverdue ? Colors.red : theme.disabledColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dueDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : theme.disabledColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_box,
                      size: 12,
                      color: theme.disabledColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}