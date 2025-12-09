import 'package:get/get.dart';
import 'package:Memento/plugins/todo/views/todo_item_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/plugins/todo/controllers/task_controller.dart';

class HistoryCompletedView extends StatefulWidget {
  final List<Task> completedTasks;
  final TaskController taskController;

  const HistoryCompletedView({
    super.key,
    required this.completedTasks,
    required this.taskController,
  });

  @override
  State<HistoryCompletedView> createState() => _HistoryCompletedViewState();
}

class _HistoryCompletedViewState extends State<HistoryCompletedView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'todo_noCompletedTasks'.tr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.completedTasks.length,
        itemBuilder: (context, index) {
          final task = widget.completedTasks[index];
          return _buildTaskCard(context, task);
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 格式化日期
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final createdAtStr = dateFormat.format(task.createdAt.toLocal());
    final completedAtStr = task.completedDate != null
        ? dateFormat.format(task.completedDate!.toLocal())
        : '-';

    // 计算完成耗时
    String? durationStr;
    if (task.completedDate != null) {
      final duration = task.completedDate!.difference(task.createdAt);
      durationStr = _formatDuration(duration);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => TodoItemDetail(
              task: task,
              taskController: widget.taskController,
              isReadOnly: true,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：图标 + 标题 + 删除按钮
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 任务图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: task.priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      task.icon ?? Icons.check_circle,
                      color: task.priorityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 标题和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 删除按钮
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: () => _showDeleteConfirmation(context, task),
                    tooltip: 'todo_delete'.tr,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 分隔线
              Divider(
                height: 1,
                color: colorScheme.outline.withOpacity(0.2),
              ),
              const SizedBox(height: 10),
              // 底部：时间信息
              Row(
                children: [
                  // 创建时间
                  Expanded(
                    child: _buildTimeInfo(
                      context,
                      icon: Icons.add_circle_outline,
                      label: 'todo_createdAt'.tr,
                      value: createdAtStr,
                      color: colorScheme.primary,
                    ),
                  ),
                  // 完成时间
                  Expanded(
                    child: _buildTimeInfo(
                      context,
                      icon: Icons.check_circle_outline,
                      label: 'todo_completedOn'.tr,
                      value: completedAtStr,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              // 耗时和标签信息
              if (durationStr != null || task.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    // 耗时
                    if (durationStr != null)
                      _buildChip(
                        context,
                        icon: Icons.timer_outlined,
                        label: durationStr,
                        color: colorScheme.tertiary,
                      ),
                    if (durationStr != null && task.tags.isNotEmpty)
                      const SizedBox(width: 8),
                    // 标签
                    if (task.tags.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: task.tags
                                .take(3)
                                .map((tag) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: _buildChip(
                                        context,
                                        icon: Icons.label_outline,
                                        label: tag,
                                        color: colorScheme.secondary,
                                      ),
                                    ))
                                .toList(),
                          ),
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

  Widget _buildTimeInfo(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '<1m';
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Task task) async {

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        title: Text('todo_deleteTaskTitle'.tr),
        content: Text('todo_deleteTaskMessage'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('todo_cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('todo_delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.taskController.removeFromHistory(task.id);
      setState(() {});
    }
  }
}
