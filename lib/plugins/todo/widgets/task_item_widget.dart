import 'package:flutter/material.dart';
import '../models/task_item.dart';
import 'task_item_menus.dart';

class TaskItemWidget extends StatefulWidget {
  final TaskItem task;
  final List<TaskItem> subTasks;
  final bool isTreeView;
  final VoidCallback onToggleComplete;
  final Function(TaskItem task)? onEdit;
  final Function(TaskItem task)? onDelete;
  final Function(int oldIndex, int newIndex)? onReorderSubTasks;
  final int level; // 添加层级属性

  static const double baseIndent = 16.0; // 基础缩进值
  static const int maxLevel = 5; // 最大层级数

  // 计算层级对应的边距
  static double calculateLevelIndent(int level) {
    // 确保层级不超过最大层级
    final int effectiveLevel = level < maxLevel ? level : maxLevel - 1;
    return baseIndent * effectiveLevel;
  }

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.subTasks,
    this.isTreeView = true,
    required this.onToggleComplete,
    this.onEdit,
    this.onDelete,
    this.onReorderSubTasks,
    this.level = 0, // 默认为顶层
  });

  @override
  State<TaskItemWidget> createState() => TaskItemWidgetState();
}

class TaskItemWidgetState extends State<TaskItemWidget>
    with TickerProviderStateMixin {
  AnimationController? _checkmarkController;
  bool _localCompletionState = false;
  bool _isPartiallyCompleted = false;

  // 计算任务的实际层级
  int _calculateTaskLevel() {
    int level = 0;
    String? currentParentId = widget.task.parentTaskId;

    // 遍历父任务链直到找到顶层任务
    while (currentParentId != null && level < TaskItemWidget.maxLevel) {
      level++;
      // 在所有任务中查找当前父任务
      final parentTask = _findParentTask(currentParentId, widget.subTasks);
      currentParentId = parentTask?.parentTaskId;
    }

    return level;
  }

  // 在任务列表中查找指定ID的任务
  TaskItem? _findParentTask(String parentId, List<TaskItem> tasks) {
    for (var task in tasks) {
      if (task.id == parentId) {
        return task;
      }
    }
    return null;
  }

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
      _isPartiallyCompleted = widget.task.isPartiallyCompleted;
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

  // 检查所有直接子任务是否完成
  bool get _isAllSubTasksCompleted {
    if (widget.subTasks.isEmpty) return false;
    return widget.subTasks.every((subTask) => subTask.isCompleted);
  }

  // 检查是否部分子任务完成（包括子任务的子任务）
  bool get _isPartiallySubTasksCompleted {
    if (widget.subTasks.isEmpty) return false;
    return widget.subTasks.any(
      (subTask) => subTask.isCompleted || subTask.isPartiallyCompleted,
    );
  }

  // 更新所有子任务的完成状态（递归）
  void _updateSubTasksStatus(bool completed) {
    if (widget.subTasks.isEmpty) return;

    setState(() {
      // 获取直接子任务
      final directSubTasks =
          widget.subTasks
              .where((task) => task.parentTaskId == widget.task.id)
              .toList();

      // 递归更新所有子任务的完成状态
      _recursiveUpdateTaskStatus(directSubTasks, completed);
    });
  }

  // 递归更新任务状态
  void _recursiveUpdateTaskStatus(List<TaskItem> tasks, bool completed) {
    for (var task in tasks) {
      // 更新当前任务状态
      task.completedAt = completed ? DateTime.now() : null;
      task.isPartiallyCompleted = false; // 重置部分完成状态

      // 获取当前任务的直接子任务
      final childTasks =
          widget.subTasks
              .where((childTask) => childTask.parentTaskId == task.id)
              .toList();

      // 如果有子任务，递归更新
      if (childTasks.isNotEmpty) {
        _recursiveUpdateTaskStatus(childTasks, completed);
      }
    }
  }

  // 更新父任务状态基于所有子任务（包括子任务的子任务）完成情况
  void _updateParentTaskStatus() {
    if (!mounted) return;

    final bool shouldBeCompleted = _isAllSubTasksCompleted;
    final bool isPartiallyCompleted = _isPartiallySubTasksCompleted;

    setState(() {
      if (shouldBeCompleted) {
        widget.task.completedAt = DateTime.now();
        _localCompletionState = true;
        _isPartiallyCompleted = false;
        _checkmarkController?.forward();
      } else if (isPartiallyCompleted) {
        widget.task.completedAt = null;
        _localCompletionState = false;
        _isPartiallyCompleted = true;
        _checkmarkController?.reverse();
      } else {
        widget.task.completedAt = null;
        _localCompletionState = false;
        _isPartiallyCompleted = false;
        _checkmarkController?.reverse();
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

  // 构建子任务列表
  Widget _buildSubTasksList() {
    if (widget.onReorderSubTasks != null) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.subTasks.length,
        onReorder: (oldIndex, newIndex) {
          if (widget.onReorderSubTasks != null) {
            widget.onReorderSubTasks!(
              oldIndex,
              newIndex > oldIndex ? newIndex - 1 : newIndex,
            );
          }
        },
        itemBuilder:
            (context, index) => _buildSubTaskItem(widget.subTasks[index]),
      );
    }

    return Column(children: widget.subTasks.map(_buildSubTaskItem).toList());
  }

  // 构建单个子任务项
  Widget _buildSubTaskItem(TaskItem subTask) {
    // 只获取直接子任务，避免重复显示
    final List<TaskItem> directSubTasks = List<TaskItem>.from(
      widget.subTasks.where((task) => task.parentTaskId == subTask.id),
    );

    return TaskItemWidget(
      key: ValueKey(subTask.id),
      task: subTask,
      subTasks: directSubTasks,
      onToggleComplete: () {
        setState(() {});
        widget.onToggleComplete();
      },
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      onReorderSubTasks: widget.onReorderSubTasks,
      level: widget.level + 1, // 增加层级
    );
  }

  // 递归获取所有子任务（仅在需要时使用）
  List<TaskItem> _getAllSubTasks(String parentId) {
    // 创建一个新的可修改列表来存储子任务
    List<TaskItem> allSubTasks = [];

    // 使用Set来避免重复添加任务
    Set<String> processedTaskIds = {};

    // 确保widget.subTasks不为null
    if (widget.subTasks.isEmpty) {
      return allSubTasks;
    }

    // 使用队列进行广度优先搜索，避免递归调用可能导致的栈溢出
    List<TaskItem> queue =
        widget.subTasks.where((task) => task.parentTaskId == parentId).toList();

    while (queue.isNotEmpty) {
      TaskItem current = queue.removeAt(0);

      // 如果已处理过该任务，跳过
      if (processedTaskIds.contains(current.id)) {
        continue;
      }

      // 添加到结果列表并标记为已处理
      allSubTasks.add(current);
      processedTaskIds.add(current.id);

      // 将当前任务的子任务添加到队列
      queue.addAll(
        widget.subTasks.where((task) => task.parentTaskId == current.id),
      );
    }

    return allSubTasks;
  }

  Widget _buildTaskItem() {
    // 检查是否有直接子任务（当前任务作为父任务被引用）
    // 检查当前任务是否有直接子任务
    final bool hasDirectSubTasks = widget.subTasks.any(
      (task) => task.parentTaskId == widget.task.id,
    );

    // 只要有直接子任务就使用可展开控件
    final bool useExpansionTile = hasDirectSubTasks;

    // 计算任务的实际层级并获取对应的缩进值
    final int taskLevel = _calculateTaskLevel();
    final double levelIndent = TaskItemWidget.calculateLevelIndent(taskLevel);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      margin: EdgeInsets.only(left: levelIndent),
      child: GestureDetector(
        onLongPressStart: (details) {
          TaskItemMenus.showTaskMenu(
            context,
            widget.task,
            widget.onEdit ?? (_) {},
            widget.onDelete,
            details.globalPosition,
            onAddSubTask: (newSubTask) {
              // 直接使用传入的子任务对象
              if (widget.onEdit != null) {
                widget.onEdit!(newSubTask);
              }
            },
          );
        },
        child:
            useExpansionTile
                ? ExpansionTile(
                  initiallyExpanded: widget.task.isExpanded,
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
                                        : _isPartiallyCompleted
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color
                                            ?.withAlpha((0.8 * 255).round())
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
                                      : _isPartiallyCompleted
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.5)
                                      : Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            color:
                                _localCompletionState
                                    ? Theme.of(context).colorScheme.primary
                                    : _isPartiallyCompleted
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2)
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
                                  : _isPartiallyCompleted
                                  ? Icon(
                                    Icons.remove,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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

                    // 保存展开状态
                    setState(() {
                      widget.task.isExpanded = expanded;
                    });

                    // 只在需要保存展开状态时更新任务
                    if (widget.onEdit != null &&
                        widget.task.isExpanded != expanded) {
                      widget.task.isExpanded = expanded;
                      widget.onEdit!(widget.task);
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
                    if (hasDirectSubTasks)
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: _buildSubTasksList(),
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

  // 此方法已移除，使用递归的TaskItemWidget替代
}
