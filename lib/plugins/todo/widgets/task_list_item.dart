import 'package:flutter/material.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(TaskStatus) onStatusChanged;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: IconButton(
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
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.done
                ? TextDecoration.lineThrough
                : null,
            fontWeight: task.priority == TaskPriority.high
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isOverdue ? Colors.red : theme.disabledColor,
                ),
                const SizedBox(width: 4),
                Text(
                  dueDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : theme.disabledColor,
                  ),
                ),
                if (task.subtasks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_box,
                    size: 14,
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
              ],
            ),
          ],
        ),
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: task.priorityColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}