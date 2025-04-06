import 'package:flutter/material.dart';
import '../models/task_item.dart';
import 'task_item_menus.dart';
import 'task_sub_item_widget.dart';

class TaskItemWidget extends StatefulWidget {
  final TaskItem task;
  final List<TaskItem> subTasks;
  final bool isTreeView;
  final VoidCallback onToggleComplete;
  final Function(TaskItem task)? onEdit;
  final Function(TaskItem task)? onDelete;
  final Function(int oldIndex, int newIndex)? onReorderSubTasks;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.subTasks,
    this.isTreeView = true,
    required this.onToggleComplete,
    this.onEdit,
    this.onDelete,
    this.onReorderSubTasks,
  });

  @override
  State<TaskItemWidget> createState() => TaskItemWidgetState();
}

class TaskItemWidgetState extends State<TaskItemWidget>
    with TickerProviderStateMixin {
  AnimationController? _checkmarkController;
  bool _localCompletionState = false;

  @override
  void initState() {
    super.initState();
    _localCompletionState = widget.task.isCompleted;
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    if (_localCompletionState) {
      _checkmarkController!.value = 1.0;
    }
  }

  @override
  void dispose() {
    _checkmarkController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TaskItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.isCompleted != widget.task.isCompleted) {
      _updateLocalState();
    }
  }

  void _updateLocalState() {
    if (!mounted) return;
    setState(() {
      _localCompletionState = widget.task.isCompleted;
      if (_checkmarkController != null) {
        if (_localCompletionState) {
          _checkmarkController!.forward();
        } else {
          _checkmarkController!.reverse();
        }
      }
    });
  }

  List<Widget> _buildActionButtons() {
    if (widget.subTasks.isEmpty) {
      return [];
    }

    return [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
    ];
  }

  bool get _isAllSubTasksCompleted {
    if (widget.subTasks.isEmpty) return false;
    return widget.subTasks.every((subTask) => subTask.isCompleted);
  }

  // 更新所有子任务的完成状态
  void _updateSubTasksStatus(bool completed) {
    if (widget.subTasks.isEmpty) return;

    setState(() {
      for (var subTask in widget.subTasks) {
        subTask.completedAt = completed ? DateTime.now() : null;
      }
    });
  }

  // 更新父任务状态基于子任务完成情况
  void _updateParentTaskStatus() {
    if (!mounted) return;

    bool shouldBeCompleted = _isAllSubTasksCompleted;
    // 移除条件判断，确保状态始终同步
    setState(() {
      widget.task.completedAt = shouldBeCompleted ? DateTime.now() : null;
      _localCompletionState = shouldBeCompleted;
      if (_checkmarkController != null) {
        if (shouldBeCompleted) {
          _checkmarkController!.forward();
        } else {
          _checkmarkController!.reverse();
        }
      }
    });
    // 通知父组件状态变化
    widget.onToggleComplete();
  }

  // 构建信息按钮
  Widget _buildInfoButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: Color.fromRGBO(
                (color.r * 0.5).round(),
                (color.g * 0.5).round(),
                (color.b * 0.5).round(),
                1,
              ),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTaskItem();
  }

  Widget _buildTaskItem() {
    // 检查是否有子任务
    final bool hasSubTasks = widget.subTasks.isNotEmpty;

    // 检查是否有备注
    final bool hasNotes =
        widget.task.notes != null && widget.task.notes!.isNotEmpty;

    // 只有在有子任务时才使用可展开控件
    final bool useExpansionTile = hasSubTasks;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: GestureDetector(
        onLongPressStart: (details) {
          TaskItemMenus.showTaskMenu(
            context,
            widget.task,
            widget.onEdit ?? (_) {},
            widget.onDelete,
            details.globalPosition,
          );
        },
        child:
            useExpansionTile
                ? ExpansionTile(
                  expandedAlignment: Alignment.centerLeft,
                  shape: Border(), // 移除描边
                  collapsedShape: Border(), // 移除描边
                  maintainState: true,
                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration:
                                    _localCompletionState
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                color:
                                    _localCompletionState
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color
                                            ?.withAlpha((0.5 * 255).round())
                                        : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (widget.task.subtitle != null &&
                                widget.task.subtitle!.isNotEmpty)
                              Text(
                                widget.task.subtitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withAlpha((0.7 * 255).round()),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  leading: InkWell(
                    onTap: () {
                      setState(() {
                        _localCompletionState = !_localCompletionState;
                        widget.task.completedAt =
                            _localCompletionState ? DateTime.now() : null;
                        if (_localCompletionState) {
                          _checkmarkController?.forward();
                        } else {
                          _checkmarkController?.reverse();
                        }
                        // 手动点击父任务时，同步更新所有子任务状态
                        _updateSubTasksStatus(_localCompletionState);
                      });
                      widget.onToggleComplete();
                    },
                    child: AnimatedBuilder(
                      animation:
                          _checkmarkController ??
                          AnimationController(
                            vsync: this,
                            duration: const Duration(milliseconds: 300),
                          ),
                      builder: (context, child) {
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  _localCompletionState
                                      ? Colors.transparent
                                      : Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            color:
                                _localCompletionState
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                          ),
                          child:
                              _localCompletionState
                                  ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  )
                                  : null,
                        );
                      },
                    ),
                  ),
                  onExpansionChanged: (expanded) {
                    // 如果没有子任务和备注，则不展开
                    if (expanded &&
                        widget.subTasks.isEmpty &&
                        (widget.task.notes == null ||
                            widget.task.notes!.isEmpty)) {
                      return;
                    }
                  },
                  trailing:
                      _buildActionButtons().isNotEmpty
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _buildActionButtons(),
                          )
                          : null,
                  children: [
                    if (hasNotes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          widget.task.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    if (hasSubTasks)
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child:
                            widget.onReorderSubTasks != null
                                ? ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: widget.subTasks.length,
                                  onReorder: (oldIndex, newIndex) {
                                    if (widget.onReorderSubTasks != null) {
                                      widget.onReorderSubTasks!(
                                        oldIndex,
                                        newIndex > oldIndex
                                            ? newIndex - 1
                                            : newIndex,
                                      );
                                    }
                                  },
                                  itemBuilder: (context, index) {
                                    return _buildSubTaskItem(
                                      widget.subTasks[index],
                                    );
                                  },
                                )
                                : Column(
                                  children:
                                      widget.subTasks.map((task) {
                                        return _buildSubTaskItem(task);
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
                          setState(() {
                            _localCompletionState = !_localCompletionState;
                            widget.task.completedAt =
                                _localCompletionState ? DateTime.now() : null;
                            if (_localCompletionState) {
                              _checkmarkController?.forward();
                            } else {
                              _checkmarkController?.reverse();
                            }
                            // 手动点击父任务时，同步更新所有子任务状态
                            _updateSubTasksStatus(_localCompletionState);
                          });
                          widget.onToggleComplete();
                        },
                        child: AnimatedBuilder(
                          animation:
                              _checkmarkController ??
                              AnimationController(
                                vsync: this,
                                duration: const Duration(milliseconds: 300),
                              ),
                          builder: (context, child) {
                            return Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      _localCompletionState
                                          ? Colors.transparent
                                          : Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                  width: 2,
                                ),
                                color:
                                    _localCompletionState
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                              ),
                              child:
                                  _localCompletionState
                                      ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      )
                                      : null,
                            );
                          },
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.task.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    decoration:
                                        _localCompletionState
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                    color:
                                        _localCompletionState
                                            ? Theme.of(context).disabledColor
                                            : null,
                                  ),
                                ),
                                if (widget.task.subtitle != null &&
                                    widget.task.subtitle!.isNotEmpty)
                                  Text(
                                    widget.task.subtitle!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.7),
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
                                widget.task.priority,
                              ),
                              color: TaskItemMenus.getPriorityColor(
                                widget.task.priority,
                              ),
                              onTap:
                                  widget.onEdit != null
                                      ? () => TaskItemMenus.showPriorityMenu(
                                        context,
                                        widget.task,
                                        widget.onEdit ?? (_) {},
                                      )
                                      : null,
                            ),
                            if (widget.task.tags.isNotEmpty)
                              _buildInfoButton(
                                icon: Icons.label,
                                label: '${widget.task.tags.length}个标签',
                                color: Colors.blue,
                                onTap:
                                    widget.onEdit != null
                                        ? () => TaskItemMenus.showTagsMenu(
                                          context,
                                          widget.task,
                                          widget.onEdit ?? (_) {},
                                        )
                                        : null,
                              ),
                            _buildInfoButton(
                              icon: Icons.folder,
                              label: widget.task.group,
                              color: Colors.purple,
                              onTap:
                                  widget.onEdit != null
                                      ? () => TaskItemMenus.showGroupsMenu(
                                        context,
                                        widget.task,
                                        widget.onEdit ?? (_) {},
                                      )
                                      : null,
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildActionButtons(),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSubTaskItem(TaskItem subTask) {
    return TaskSubItemWidget(
      key: ValueKey(subTask.id),
      subTask: subTask,
      onToggleComplete: () {
        // 先执行子任务的状态切换回调
        widget.onToggleComplete();
        // 然后检查并更新父任务状态
        _updateParentTaskStatus();
      },
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      onActivateMoveMode: () {},
      updateParentStatus: _updateParentTaskStatus,
    );
  }
}
