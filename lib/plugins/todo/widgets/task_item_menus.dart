import 'package:flutter/material.dart';
import '../models/task_item.dart';

class TaskItemMenus {
  static void showPriorityMenu(
    BuildContext context,
    TaskItem task,
    Function(TaskItem) onEdit,
  ) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + button.size.width,
        offset.dy + button.size.height,
      ),
      items:
          Priority.values.map((priority) {
            final bool isSelected = task.priority == priority;
            return PopupMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(Icons.flag, color: getPriorityColor(priority)),
                  SizedBox(width: 8),
                  Text(
                    getPriorityText(priority),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: 8),
                    Icon(Icons.check, size: 18),
                  ],
                ],
              ),
            );
          }).toList(),
    ).then((selectedPriority) {
      if (selectedPriority != null && selectedPriority != task.priority) {
        final updatedTask = task.copyWith(priority: selectedPriority);
        onEdit(updatedTask);
      }
    });
  }

  static void showTagsMenu(
    BuildContext context,
    TaskItem task,
    Function(TaskItem) onEdit,
  ) {
    showGroupsMenu(context, task, onEdit, isTagMode: true);
  }

  static void showAddTagDialog(
    BuildContext context,
    TaskItem task,
    Function(TaskItem) onEdit,
  ) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('添加标签'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: '输入标签名称'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final updatedTags = List<String>.from(task.tags);
                  if (!updatedTags.contains(controller.text)) {
                    updatedTags.add(controller.text);
                    final updatedTask = task.copyWith(tags: updatedTags);
                    onEdit(updatedTask);
                  }
                }
                Navigator.of(context).pop();
              },
              child: Text('添加'),
            ),
          ],
        );
      },
    );
  }

  static void showGroupsMenu(
    BuildContext context,
    TaskItem task,
    Function(TaskItem) onEdit, {
    bool isTagMode = false,
  }) {
    final List<String> availableItems =
        isTagMode ? task.tags : ['工作', '个人', '学习', '家庭', '健康', '其他'];

    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: Text(isTagMode ? '标签管理' : '分组管理'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (availableItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              '暂无分组',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: availableItems.length,
                            itemBuilder: (context, index) {
                              final item = availableItems[index];
                              final bool isCurrentItem =
                                  isTagMode
                                      ? task.tags.contains(item)
                                      : task.group == item;

                              return ListTile(
                                leading: Icon(
                                  isTagMode
                                      ? Icons.label_outline
                                      : Icons.folder_outlined,
                                ),
                                title: Text(item),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isCurrentItem)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          isTagMode ? '已选' : '当前',
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: isTagMode ? '编辑标签' : '编辑分组',
                                      onPressed: () {
                                        if (isTagMode) {
                                          _showEditTagDialog(
                                            context: context,
                                            oldTag: item,
                                            task: task,
                                            onEdit: onEdit,
                                            onComplete: () {
                                              if (context.mounted) {
                                                Navigator.of(context).pop();
                                              }
                                            },
                                          );
                                        } else {
                                          _showEditGroupDialog(
                                            context: context,
                                            group: item,
                                            task: task,
                                            onEdit: onEdit,
                                            onComplete: () {
                                              if (context.mounted) {
                                                Navigator.of(context).pop();
                                              }
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (isTagMode) {
                                    final updatedTags = List<String>.from(
                                      task.tags,
                                    );
                                    if (isCurrentItem) {
                                      updatedTags.remove(item);
                                    } else {
                                      updatedTags.add(item);
                                    }
                                    final updatedTask = task.copyWith(
                                      tags: updatedTags,
                                    );
                                    onEdit(updatedTask);
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  } else if (!isCurrentItem) {
                                    final updatedTask = task.copyWith(
                                      group: item,
                                    );
                                    onEdit(updatedTask);
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (isTagMode) {
                        showAddTagDialog(context, task, onEdit);
                      } else {
                        showAddGroupDialog(context, task, onEdit);
                      }
                    },
                    child: const Text('新建'),
                  ),
                ],
              );
            },
          ),
    );
  }

  static void _showEditTagDialog({
    required BuildContext context,
    required String oldTag,
    required TaskItem task,
    required Function(TaskItem) onEdit,
    required VoidCallback onComplete,
  }) {
    final TextEditingController controller = TextEditingController(
      text: oldTag,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('编辑标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '标签名称',
                  hintText: '请输入标签名称',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty && controller.text != oldTag) {
                  final updatedTags = List<String>.from(task.tags);
                  updatedTags.remove(oldTag);
                  updatedTags.add(controller.text);
                  final updatedTask = task.copyWith(tags: updatedTags);
                  onEdit(updatedTask);
                  Navigator.of(context).pop();
                  onComplete();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }

  static void _showEditGroupDialog({
    required BuildContext context,
    required String group,
    required TaskItem task,
    required Function(TaskItem) onEdit,
    required VoidCallback onComplete,
  }) {
    final TextEditingController controller = TextEditingController(text: group);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('编辑分组'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '分组名称',
                  hintText: '请输入分组名称',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty && controller.text != group) {
                  final updatedTask = task.copyWith(group: controller.text);
                  onEdit(updatedTask);
                  Navigator.of(context).pop();
                  onComplete();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }

  static void showAddGroupDialog(
    BuildContext context,
    TaskItem task,
    Function(TaskItem) onEdit,
  ) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('新建分组'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: '输入分组名称'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final updatedTask = task.copyWith(group: controller.text);
                  onEdit(updatedTask);
                }
                Navigator.of(context).pop();
              },
              child: Text('添加'),
            ),
          ],
        );
      },
    );
  }

  static void showTaskMenu(
    BuildContext context,
    TaskItem task,
    Function(TaskItem)? onEdit,
    Function(TaskItem)? onDelete,
    Offset? position, {
    Function(TaskItem)? onAddSubTask,
  }) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    late final RelativeRect menuPosition;

    if (position != null) {
      menuPosition = RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      );
    } else {
      final RenderBox button = context.findRenderObject() as RenderBox;
      final Offset offset = button.localToGlobal(Offset.zero);
      menuPosition = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + button.size.width,
        offset.dy + button.size.height,
      );
    }

    showMenu(
      context: context,
      position: menuPosition,
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text('编辑'),
            dense: true,
          ),
          onTap: () {
            if (onEdit != null) {
              // 延迟执行以确保菜单先关闭
              Future.delayed(Duration.zero, () {
                onEdit(task);
              });
            }
          },
        ),
        if (onAddSubTask != null)
          PopupMenuItem(
            child: ListTile(
              leading: Icon(
                Icons.add_task,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('增加子任务'),
              dense: true,
            ),
            onTap: () {
              // 延迟执行以确保菜单先关闭
              Future.delayed(Duration.zero, () {
                // 创建一个新的空白子任务
                final newSubTask = TaskItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: '',
                  createdAt: DateTime.now(),
                  group: task.group,
                  priority: task.priority,
                  parentTaskId: task.id, // 设置父任务ID
                );

                // 调用onAddSubTask来触发子任务的创建对话框
                if (onAddSubTask != null) {
                  onAddSubTask(newSubTask);
                }
              });
            },
          ),
        if (onDelete != null)
          PopupMenuItem(
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('删除', style: TextStyle(color: Colors.red)),
              dense: true,
            ),
            onTap: () {
              // 延迟执行以确保菜单先关闭
              Future.delayed(Duration.zero, () {
                onDelete(task);
              });
            },
          ),
      ],
    );
  }

  static Color getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.importantUrgent:
        return Colors.red;
      case Priority.importantNotUrgent:
        return Colors.orange;
      case Priority.notImportantUrgent:
        return Colors.amber.shade600; // 使用较深的琥珀色替代鲜黄色
      case Priority.notImportantNotUrgent:
        return Colors.green;
    }
  }

  static String getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.importantUrgent:
        return '重要且紧急';
      case Priority.importantNotUrgent:
        return '重要不紧急';
      case Priority.notImportantUrgent:
        return '紧急不重要';
      case Priority.notImportantNotUrgent:
        return '不紧急不重要';
    }
  }
}
