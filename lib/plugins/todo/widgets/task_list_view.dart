import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class TaskListView extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task, TaskStatus) onTaskStatusChanged;
  final Function(Task) onTaskDismissed;
  final Function(String taskId, String subtaskId, bool isCompleted)?
  onSubtaskStatusChanged;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskStatusChanged,
    required this.onTaskDismissed,
    this.onSubtaskStatusChanged,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F1323) : const Color(0xFFF5F6F8);

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          Expanded(
            child:
                widget.tasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.tasks.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final task = widget.tasks[index];
                        return _TaskCard(
                          key: ValueKey(task.id),
                          task: task,
                          onTap: () => widget.onTaskTap(task),
                          onStatusChanged:
                              (status) =>
                                  widget.onTaskStatusChanged(task, status),
                          onDismissed: () => widget.onTaskDismissed(task),
                          onSubtaskStatusChanged: widget.onSubtaskStatusChanged,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.task_alt, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No tasks yet\nTap + to add a new task',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(TaskStatus) onStatusChanged;
  final VoidCallback onDismissed;
  final Function(String taskId, String subtaskId, bool isCompleted)?
  onSubtaskStatusChanged;

  const _TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDismissed,
    this.onSubtaskStatusChanged,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isExpanded = false;
  static const primaryColor = Color(0xFF607AFB);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = widget.task.status == TaskStatus.done;
    final isOverdue =
        widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(DateTime.now()) &&
        !isDone;

    Color borderColor;
    if (isDone) {
      borderColor = Colors.transparent;
    } else {
      switch (widget.task.priority) {
        case TaskPriority.high:
          borderColor = Colors.red;
          break;
        case TaskPriority.medium:
          borderColor = Colors.amber;
          break;
        case TaskPriority.low:
          borderColor = primaryColor; // Use primary for low/default
          break;
      }
    }

    // Overdue overrides priority color in some designs, but keeping priority border for now
    // HTML shows "Overdue" tag but border color might be specific.
    // HTML example: "border-l-4 border-red-500" for Design (High Priority)
    // "border-l-4 border-amber-500" for Develop (Medium/Starts soon)
    // "border-l-4 border-transparent" for Done task (opacity-60)

    if (isDone) {
      borderColor = Colors.transparent;
    }

    return Dismissible(
      key: widget.key!,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDismissed(),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border(left: BorderSide(color: borderColor, width: 4)),
        ),
        child: Opacity(
          opacity: isDone ? 0.6 : 1.0,
          child: Column(
            children: [
              InkWell(
                onTap: () => widget.onTap(),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft:
                      _isExpanded ? Radius.zero : const Radius.circular(12),
                  bottomRight:
                      _isExpanded ? Radius.zero : const Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Box
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _getCategoryIcon(),
                          color: isDark ? Colors.white : Colors.grey[900],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Main Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.grey[900],
                                decoration:
                                    isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Tags
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ...widget.task.tags.map(
                                  (tag) => _buildTag(tag, isDark),
                                ),
                                if (widget.task.priority == TaskPriority.high)
                                  _buildTag(
                                    'High Priority',
                                    isDark,
                                    isHighPriority: true,
                                  ),
                                if (isOverdue)
                                  _buildTag('Overdue', isDark, isOverdue: true),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Date and Time
                            Row(
                              children: [
                                if (widget.task.dueDate != null) ...[
                                  Text(
                                    DateFormat(
                                      'MMM d',
                                    ).format(widget.task.dueDate!),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[500],
                                      decoration:
                                          isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (widget.task.reminders.isNotEmpty) ...[
                                  Icon(
                                    isDone
                                        ? Icons.notifications_off
                                        : Icons.notifications_active,
                                    size: 16,
                                    color:
                                        isDone
                                            ? (isDark
                                                ? Colors.grey[500]
                                                : Colors.grey[400])
                                            : primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(widget.task.reminders.first),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDone
                                              ? (isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[400])
                                              : primaryColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!isDone && widget.task.dueDate != null) ...[
                              const SizedBox(height: 4),
                              _buildRemainingTime(widget.task.dueDate!, isDark),
                            ],
                          ],
                        ),
                      ),
                      // Checkbox & Expand Icon
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final newStatus =
                                  isDone ? TaskStatus.todo : TaskStatus.done;
                              widget.onStatusChanged(newStatus);
                            },
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: isDone,
                                activeColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: BorderSide(
                                  color:
                                      isDark
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.grey[400]!,
                                  width: 2,
                                ),
                                onChanged: (value) {
                                  final newStatus =
                                      value == true
                                          ? TaskStatus.done
                                          : TaskStatus.todo;
                                  widget.onStatusChanged(newStatus);
                                },
                              ),
                            ),
                          ),
                          if (widget.task.subtasks.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                              child: Icon(
                                _isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color:
                                    isDark ? Colors.grey[500] : Colors.grey[400],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded Section
              if (_isExpanded)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (widget.task.subtasks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Column(
                            children:
                                widget.task.subtasks.map((subtask) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: Checkbox(
                                            value: subtask.isCompleted,
                                            activeColor: primaryColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            side: BorderSide(
                                              color:
                                                  isDark
                                                      ? Colors.white
                                                          .withOpacity(0.2)
                                                      : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                            onChanged: (value) {
                                              // Optimistic update
                                              setState(() {
                                                subtask.isCompleted =
                                                    value ?? false;
                                              });
                                              if (widget
                                                      .onSubtaskStatusChanged !=
                                                  null) {
                                                widget.onSubtaskStatusChanged!(
                                                  widget.task.id,
                                                  subtask.id,
                                                  value ?? false,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            subtask.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color:
                                                  isDark
                                                      ? Colors.white
                                                      : Colors.grey[900],
                                              decoration:
                                                  subtask.isCompleted
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      // Timer Section
                      if (widget.task.status == TaskStatus.inProgress ||
                          widget.task.duration != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? primaryColor.withOpacity(0.1)
                                    : primaryColor.withOpacity(0.05),
                            border: Border(
                              top: BorderSide(
                                color:
                                    isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey[200]!,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.task.formattedDuration,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.task.status == TaskStatus.inProgress)
                                IconButton(
                                  icon: const Icon(Icons.pause_circle_filled),
                                  color: primaryColor,
                                  iconSize: 32,
                                  onPressed: () {
                                    widget.onStatusChanged(
                                      TaskStatus.todo,
                                    ); // Pause (back to todo/pending)
                                  },
                                )
                              else if (!isDone)
                                IconButton(
                                  icon: const Icon(Icons.play_circle_fill),
                                  color: primaryColor,
                                  iconSize: 32,
                                  onPressed: () {
                                    widget.onStatusChanged(
                                      TaskStatus.inProgress,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    // Simple mapping based on tags or random for variety since we don't have category field
    if (widget.task.tags.contains('Design') ||
        widget.task.title.toLowerCase().contains('design')) {
      return Icons.palette;
    } else if (widget.task.tags.contains('Frontend') ||
        widget.task.title.toLowerCase().contains('code')) {
      return Icons.code;
    } else if (widget.task.tags.contains('Admin') ||
        widget.task.tags.contains('Reporting')) {
      return Icons
          .school; // Close enough to the "school" icon in HTML for Admin/Report
    }
    return Icons.assignment;
  }

  Widget _buildTag(
    String text,
    bool isDark, {
    bool isHighPriority = false,
    bool isOverdue = false,
  }) {
    Color bg;
    Color fg;

    if (isOverdue) {
      bg =
          isDark
              ? Colors.red.withOpacity(0.2)
              : const Color(0xFFFEF2F2); // red-50 / red-500/20
      fg = isDark ? Colors.red[200]! : Colors.red[800]!;
    } else if (isHighPriority) {
      bg =
          isDark
              ? Colors.purple.withOpacity(0.2)
              : const Color(0xFFF3E8FF); // purple-100
      fg = isDark ? Colors.purple[200]! : Colors.purple[800]!;
    } else if (text == 'Frontend' || text == 'UI/UX') {
      bg =
          isDark
              ? Colors.blue.withOpacity(0.2)
              : const Color(0xFFDBEAFE); // blue-100
      fg = isDark ? Colors.blue[200]! : Colors.blue[800]!;
    } else {
      bg = isDark ? Colors.grey.withOpacity(0.2) : Colors.grey[200]!;
      fg = isDark ? Colors.grey[300]! : Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildRemainingTime(DateTime dueDate, bool isDark) {
    final now = DateTime.now();
    final diff = dueDate.difference(now);

    String text;
    Color bg;
    Color fg;

    if (diff.isNegative) {
      // Handled by Overdue tag usually, but if needed here
      return const SizedBox.shrink();
    }

    if (diff.inDays > 0) {
      text = '${diff.inDays} days remaining';
    } else {
      text = '${diff.inHours} hours remaining';
    }

    bg =
        isDark
            ? Colors.amber.withOpacity(0.2)
            : const Color(0xFFFFFBEB); // amber-50
    fg = isDark ? Colors.amber[200]! : Colors.amber[700]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
