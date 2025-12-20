import 'package:get/get.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:Memento/plugins/todo/models/models.dart';

class TaskListView extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task, TaskStatus) onTaskStatusChanged;
  final Function(Task) onTaskDismissed;
  final Function(Task)? onTaskEdit;
  final Function(String taskId, String subtaskId, bool isCompleted)?
  onSubtaskStatusChanged;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskStatusChanged,
    required this.onTaskDismissed,
    this.onTaskEdit,
    this.onSubtaskStatusChanged,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  @override
  Widget build(BuildContext context) {
    return Column(
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
                          onTaskEdit: widget.onTaskEdit,
                          onSubtaskStatusChanged: widget.onSubtaskStatusChanged,
                        );
                      },
                    ),
          ),
      ],
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
  final Function(Task)? onTaskEdit;
  final Function(String taskId, String subtaskId, bool isCompleted)?
  onSubtaskStatusChanged;

  const _TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDismissed,
    this.onTaskEdit,
    this.onSubtaskStatusChanged,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  static const primaryColor = Color(0xFF607AFB);
  Timer? _timer;
  late AnimationController _confettiController;
  OverlayEntry? _confettiOverlay;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _confettiOverlay?.remove();
    _confettiOverlay = null;
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    // 检查是否有正在计时的任务
    if (widget.task.status == TaskStatus.inProgress &&
        widget.task.startTime != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _showConfettiAnimation() {
    // 移除之前的 overlay（如果存在）
    _confettiOverlay?.remove();
    _confettiOverlay = null;

    _confettiOverlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Lottie.asset(
                    'assets/animations/Confetti.json',
                    controller: _confettiController,
                    fit: BoxFit.contain,
                    frameRate: FrameRate(60), // 使用60FPS提供流畅体验
                    renderCache: RenderCache.raster, // 启用离屏缓存优化性能
                    onLoaded: (composition) {
                      _confettiController.duration = composition.duration;
                      _confettiController.forward(from: 0).then((_) {
                        // 动画播放完成后移除 overlay
                        if (mounted) {
                          _confettiOverlay?.remove();
                          _confettiOverlay = null;
                        }
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // 插入到 overlay
    Overlay.of(context).insert(_confettiOverlay!);
  }

  void _handleStatusChange(TaskStatus newStatus) {
    final oldStatus = widget.task.status;

    // 先调用状态变更回调
    widget.onStatusChanged(newStatus);

    // 如果从未完成状态变为完成状态，播放动画
    if (oldStatus != TaskStatus.done && newStatus == TaskStatus.done) {
      _showConfettiAnimation();
    }
  }

  @override
  void didUpdateWidget(_TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当任务状态改变时，重新启动定时器
    if (oldWidget.task.status != widget.task.status ||
        oldWidget.task.startTime != widget.task.startTime) {
      _startTimer();
    }
  }

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
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        color: Colors.blue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 左滑进入编辑页面 - 不移除任务
          if (widget.onTaskEdit != null) {
            widget.onTaskEdit!(widget.task);
          }
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // 右滑删除任务 - 显示确认对话框
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {

                return AlertDialog(
                title: Text('todo_deleteTaskTitle'.tr),
                content: Text('${'todo_deleteTaskMessage'.tr.replaceFirst('此任务', '')}"${widget.task.title}" 吗？'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('todo_cancel'.tr),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text('todo_delete'.tr),
                  ),
                ],
              );
            },
          ) ?? false;
        }
        return false;
      },
      onDismissed: (direction) {
        // 只在确认删除后才执行删除操作
        if (direction == DismissDirection.endToStart) {
          widget.onDismissed();
        }
      },
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
                          widget.task.icon ?? Icons.assignment, // 使用任务的图标，如果没有则使用默认图标
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
                            // Top Row: Title + Timer
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.task.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.grey[900],
                                      decoration:
                                          isDone ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                // 计时器显示区域（右上角）
                                GestureDetector(
                                  onTap: () {
                                    if (widget.task.status == TaskStatus.inProgress) {
                                      // 进行中任务点击直接标记为完成
                                      _handleStatusChange(TaskStatus.done);
                                    } else {
                                      // 待办或已完成任务点击开始计时
                                      _handleStatusChange(TaskStatus.inProgress);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (widget.task.status == TaskStatus.inProgress) ...[
                                          Icon(
                                            Icons.timer,
                                            size: 16,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.task.formattedDuration,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ] else if (widget.task.status == TaskStatus.done &&
                                            widget.task.duration != null) ...[
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.task.formattedDuration,
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
                                            color: primaryColor,
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
                                    'todo_highPriority'.tr,
                                    isDark,
                                    isHighPriority: true,
                                  ),
                                if (isOverdue)
                                  _buildTag('todo_overdue'.tr, isDark, isOverdue: true),
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
                      SizedBox(
                        width: 60,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Checkbox
                            GestureDetector(
                              onTap: () {
                                final newStatus =
                                    isDone ? TaskStatus.todo : TaskStatus.done;
                                _handleStatusChange(newStatus);
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
                                    _handleStatusChange(newStatus);
                                  },
                                ),
                              ),
                            ),
                            // Expand Icon
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
                                      isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[400],
                                ),
                              ),
                            ],
                          ],
                        ),
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
