import 'package:flutter/material.dart';
import 'package:Memento/plugins/todo/models/models.dart';
import 'package:Memento/plugins/todo/models/task.dart';

class TodoFourQuadrantView extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task, TaskStatus) onTaskStatusChanged;

  const TodoFourQuadrantView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Categorize tasks
    final q1 = <Task>[]; // Urgent & Important
    final q2 = <Task>[]; // Important & Not Urgent
    final q3 = <Task>[]; // Urgent & Not Important
    final q4 = <Task>[]; // Not Urgent & Not Important

    final now = DateTime.now();
    // Definition of Urgent: Due date is today, overdue, or within next 2 days
    final urgentThreshold = now.add(const Duration(days: 2));

    for (final task in tasks) {
      if (task.status == TaskStatus.done) continue;

      // Definition of Important: High or Medium Priority
      final isImportant = task.priority == TaskPriority.high || task.priority == TaskPriority.medium;
      
      bool isUrgent = false;
      if (task.dueDate != null) {
        // Check if due date is before threshold (inclusive of today/overdue)
        // Using isBefore, so anything before now+2days is urgent.
        if (task.dueDate!.isBefore(urgentThreshold)) {
          isUrgent = true;
        }
      }

      if (isImportant && isUrgent) {
        q1.add(task);
      } else if (isImportant && !isUrgent) {
        q2.add(task);
      } else if (!isImportant && isUrgent) {
        q3.add(task);
      } else {
        q4.add(task);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildQuadrant(
                    context,
                    title: '紧急且重要', // Urgent & Important
                    color: Colors.red,
                    tasks: q1,
                  ),
                ),
                Expanded(
                  child: _buildQuadrant(
                    context,
                    title: '重要但不紧急', // Important & Not Urgent
                    color: Colors.green,
                    tasks: q2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildQuadrant(
                    context,
                    title: '紧急但不重要', // Urgent & Not Important
                    color: Colors.orange,
                    tasks: q3,
                    emptyIcon: Icons.inbox,
                  ),
                ),
                Expanded(
                  child: _buildQuadrant(
                    context,
                    title: '不紧急不重要', // Not Urgent & Not Important
                    color: Colors.blue,
                    tasks: q4,
                    emptyIcon: Icons.archive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrant(
    BuildContext context, {
    required String title,
    required Color color,
    required List<Task> tasks,
    IconData? emptyIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Colors derived from tailwind logic in HTML
    // header bg: color/10
    // header border: color/30
    // text: color-400 (which is usually a lighter/brighter shade in dark mode)
    
    final headerBgColor = color.withOpacity(0.1);
    final headerBorderColor = color.withOpacity(0.3);
    // Use a slightly lighter shade for text in dark mode to match "text-red-400"
    final titleColor = isDark ? color.withOpacity(0.8) : color; 

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBgColor,
              border: Border(bottom: BorderSide(color: headerBorderColor)),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // List
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (emptyIcon != null)
                          Icon(
                            emptyIcon,
                            size: 40,
                            color: Theme.of(context).disabledColor.withOpacity(0.2),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '无待办事项',
                          style: TextStyle(
                            color: Theme.of(context).disabledColor.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return InkWell(
                        onTap: () => onTaskTap(task),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              // Custom Checkbox appearance to match HTML
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Transform.scale(
                                  scale: 1.0,
                                  child: Checkbox(
                                    value: task.status == TaskStatus.done,
                                    onChanged: (val) {
                                      onTaskStatusChanged(
                                        task,
                                        val == true
                                            ? TaskStatus.done
                                            : TaskStatus.todo,
                                      );
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                      width: 2,
                                    ),
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // 计时器显示区域（右上角）
                              GestureDetector(
                                onTap: () {
                                  if (task.status == TaskStatus.inProgress) {
                                    // 进行中任务点击直接标记为完成
                                    onTaskStatusChanged(task, TaskStatus.done);
                                  } else {
                                    // 待办或已完成任务点击开始计时
                                    onTaskStatusChanged(task, TaskStatus.inProgress);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (task.status == TaskStatus.inProgress) ...[
                                        Icon(
                                          Icons.timer,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          task.formattedDuration,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ] else if (task.status == TaskStatus.done &&
                                          task.duration != null) ...[
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          task.formattedDuration,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                            color: Colors.green,
                                          ),
                                        ),
                                      ] else ...[
                                        Icon(
                                          Icons.play_circle_outline,
                                          size: 16,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '00:00',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                            color: isDark
                                                ? Colors.grey[500]
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
