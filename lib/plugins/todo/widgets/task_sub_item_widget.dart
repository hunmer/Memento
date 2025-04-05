import 'package:flutter/material.dart';
import '../models/task_item.dart';
import 'task_item_menus.dart';

class TaskSubItemWidget extends StatefulWidget {
  final TaskItem subTask;
  final VoidCallback onToggleComplete;
  final Function(TaskItem task)? onEdit;
  final Function(TaskItem task)? onDelete;
  final VoidCallback onActivateMoveMode;
  final Function() updateParentStatus;
  final Function(int oldIndex, int newIndex)? onReorderSubTasks;
  final int index;
  final List<TaskItem> subTasks; // 添加子任务列表

  const TaskSubItemWidget({
    super.key,
    required this.subTask,
    required this.onToggleComplete,
    this.onEdit,
    this.onDelete,
    required this.onActivateMoveMode,
    required this.updateParentStatus,
    this.onReorderSubTasks,
    this.index = 0,
    this.subTasks = const [],
  });

  @override
  State<TaskSubItemWidget> createState() => _TaskSubItemWidgetState();
}

class _TaskSubItemWidgetState extends State<TaskSubItemWidget> {
  // 获取优先级标签
  String _getPriorityLabel(Priority priority) {
    switch (priority) {
      case Priority.importantUrgent:
        return '重要紧急';
      case Priority.importantNotUrgent:
        return '重要不紧急';
      case Priority.notImportantUrgent:
        return '不重要紧急';
      case Priority.notImportantNotUrgent:
        return '不重要不紧急';
      default:
        return '未设置';
    }
  }

  // 获取优先级颜色
  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.importantUrgent:
        return Colors.red;
      case Priority.importantNotUrgent:
        return Colors.orange;
      case Priority.notImportantUrgent:
        return Colors.blue;
      case Priority.notImportantNotUrgent:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _updateSubTasksStatus(bool completed) {
    if (widget.subTasks.isEmpty) return;
    setState(() {
      for (var subTask in widget.subTasks) {
        subTask.completedAt = completed ? DateTime.now() : null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.subTask.isCompleted;

    // 检查是否有子任务或备注
    final bool hasSubTasks = widget.subTasks.isNotEmpty;
    final bool hasNotes =
        widget.subTask.notes != null && widget.subTask.notes!.isNotEmpty;
    final bool shouldUseExpansionTile = hasSubTasks || hasNotes;

    return GestureDetector(
      onLongPressStart:
          (details) => TaskItemMenus.showTaskMenu(
            context,
            widget.subTask,
            widget.onEdit ?? (_) {},
            widget.onDelete,
            details.globalPosition,
          ),
      child: Container(
        margin: const EdgeInsets.only(top: 0, left: 32),
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withAlpha(179), // 0.7 * 255 ≈ 179
        child:
            shouldUseExpansionTile
                ? ExpansionTile(
                  onExpansionChanged: (expanded) {
                    // 如果没有子任务和备注，则不展开
                    if (expanded && !hasSubTasks && !hasNotes) {
                      return;
                    }
                    // 无需保存展开状态
                    setState(() {});
                  },
                  expandedAlignment: Alignment.centerLeft,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  maintainState: true,
                  leading: InkWell(
                    onTap: () {
                      // 更新子任务状态
                      widget.subTask.completedAt =
                          isCompleted ? null : DateTime.now();
                      // 更新所有子任务的状态
                      _updateSubTasksStatus(!isCompleted);
                      // 先触发父组件的回调
                      widget.onToggleComplete();
                      // 然后更新父任务状态
                      Future.microtask(() => widget.updateParentStatus());
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isCompleted
                                  ? Colors.green
                                  : Theme.of(context).dividerColor,
                          width: 2,
                        ),
                        color:
                            isCompleted
                                ? Colors.green.withAlpha(51)
                                : Colors.transparent,
                      ),
                      child:
                          isCompleted
                              ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.green,
                              )
                              : null,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.subTask.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration:
                                      isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                  color:
                                      isCompleted
                                          ? Theme.of(context).disabledColor
                                          : null,
                                ),
                              ),
                            ),
                            if (widget.subTask.subtitle != null &&
                                widget.subTask.subtitle!.isNotEmpty)
                              Text(
                                " · ${widget.subTask.subtitle!}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                  decoration:
                                      isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                  decorationColor:
                                      Theme.of(context).hintColor, // 添加删除线颜色
                                  decorationThickness: 2.0, // 调整删除线粗细
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        _buildInfoButton(
                          icon: Icons.flag,
                          label: TaskItemMenus.getPriorityText(
                            widget.subTask.priority,
                          ),
                          color: TaskItemMenus.getPriorityColor(
                            widget.subTask.priority,
                          ),
                          onTap:
                              widget.onEdit != null
                                  ? () => TaskItemMenus.showPriorityMenu(
                                    context,
                                    widget.subTask,
                                    widget.onEdit!,
                                  )
                                  : null,
                        ),
                        if (widget.subTask.tags.isNotEmpty)
                          _buildInfoButton(
                            icon: Icons.label,
                            label: '${widget.subTask.tags.length}个标签',
                            color: Colors.blue,
                            onTap:
                                widget.onEdit != null
                                    ? () => TaskItemMenus.showTagsMenu(
                                      context,
                                      widget.subTask,
                                      widget.onEdit!,
                                    )
                                    : null,
                          ),
                        _buildInfoButton(
                          icon: Icons.folder,
                          label: widget.subTask.group,
                          color: Colors.purple,
                          onTap:
                              widget.onEdit != null
                                  ? () => TaskItemMenus.showGroupsMenu(
                                    context,
                                    widget.subTask,
                                    widget.onEdit!,
                                  )
                                  : null,
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasSubTasks)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withAlpha(26), // 0.1 * 255 ≈ 26
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${widget.subTasks.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (widget.onReorderSubTasks != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ReorderableDragStartListener(
                            index: widget.index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ),
                    ],
                  ),
                  children: [
                    if (hasNotes)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 56,
                          right: 16,
                          bottom: 8.0,
                        ),
                        child: Text(
                          widget.subTask.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    if (hasSubTasks)
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Column(
                          children:
                              widget.subTasks.map((task) {
                                // 这里不再获取嵌套子任务
                                return TaskSubItemWidget(
                                  key: ValueKey(task.id),
                                  subTask: task,
                                  onToggleComplete: () {
                                    setState(() {});
                                    widget.onToggleComplete();
                                  },
                                  onEdit: widget.onEdit,
                                  onDelete: widget.onDelete,
                                  onActivateMoveMode: widget.onActivateMoveMode,
                                  updateParentStatus: () {
                                    setState(() {});
                                    widget.updateParentStatus();
                                  },
                                  index: widget.subTasks.indexOf(task),
                                );
                              }).toList(),
                        ),
                      ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ),
                      leading: InkWell(
                        onTap: () {
                          // 更新子任务状态
                          widget.subTask.completedAt =
                              widget.subTask.isCompleted
                                  ? null
                                  : DateTime.now();
                          // 先触发父组件的回调
                          widget.onToggleComplete();
                          // 然后更新父任务状态
                          Future.microtask(() => widget.updateParentStatus());
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  widget.subTask.isCompleted
                                      ? Colors.green
                                      : Theme.of(context).dividerColor,
                              width: 2,
                            ),
                            color:
                                widget.subTask.isCompleted
                                    ? Colors.green.withAlpha(51)
                                    : Colors.transparent,
                          ),
                          child:
                              widget.subTask.isCompleted
                                  ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.green,
                                  )
                                  : null,
                        ),
                      ),
                      title: Text(
                        widget.subTask.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration:
                              widget.subTask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          color:
                              widget.subTask.isCompleted
                                  ? Theme.of(context).disabledColor
                                  : null,
                        ),
                      ),
                      subtitle:
                          widget.subTask.subtitle != null &&
                                  widget.subTask.subtitle!.isNotEmpty
                              ? Text(
                                widget.subTask.subtitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                  decoration:
                                      widget.subTask.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                ),
                              )
                              : null,
                      trailing:
                          widget.onReorderSubTasks != null
                              ? ReorderableDragStartListener(
                                index: widget.index,
                                child: const Icon(Icons.drag_handle),
                              )
                              : null,
                    ),
                    // 添加标签、文件夹和优先级信息
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // 优先级
                          if (widget.subTask.priority !=
                              Priority.notImportantNotUrgent)
                            _buildInfoButton(
                              icon: Icons.flag,
                              label: _getPriorityLabel(widget.subTask.priority),
                              color: _getPriorityColor(
                                widget.subTask.priority!,
                              ),
                              onTap:
                                  widget.onEdit != null
                                      ? () => TaskItemMenus.showPriorityMenu(
                                        context,
                                        widget.subTask,
                                        widget.onEdit!,
                                      )
                                      : null,
                            ),
                          // 标签
                          if (widget.subTask.tags != null &&
                              widget.subTask.tags!.isNotEmpty)
                            _buildInfoButton(
                              icon: Icons.label,
                              label: widget.subTask.tags!.join(', '),
                              color: Colors.blue,
                              onTap:
                                  widget.onEdit != null
                                      ? () => TaskItemMenus.showTagsMenu(
                                        context,
                                        widget.subTask,
                                        widget.onEdit!,
                                      )
                                      : null,
                            ),
                          // 文件夹
                          if (widget.subTask.group != null &&
                              widget.subTask.group!.isNotEmpty)
                            _buildInfoButton(
                              icon: Icons.folder,
                              label: widget.subTask.group!,
                              color: Colors.orange,
                              onTap:
                                  widget.onEdit != null
                                      ? () => TaskItemMenus.showGroupsMenu(
                                        context,
                                        widget.subTask,
                                        widget.onEdit!,
                                      )
                                      : null,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8), // 底部间距
                  ],
                ),
      ),
    );
  }

  // 构建信息按钮 - 使用带背景色的badge样式
  Widget _buildInfoButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    // 创建一个较浅的背景色
    final backgroundColor = Color.fromRGBO(
      (color.red.toInt() + 200).clamp(0, 255),
      (color.green.toInt() + 200).clamp(0, 255),
      (color.blue.toInt() + 200).clamp(0, 255),
      0.15,
    );

    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      labelPadding: const EdgeInsets.only(left: 0), // 减少图标和文字之间的间距
      label: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Text(label, style: TextStyle(fontSize: 12, color: color)),
      ),
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withAlpha(76),
          width: 1,
        ), // 0.3 * 255 ≈ 76
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}
