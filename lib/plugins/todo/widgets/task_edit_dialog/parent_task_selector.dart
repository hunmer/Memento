import 'package:flutter/material.dart';
import '../../models/task_item.dart';
import '../../services/todo_service.dart';
import 'task_tree_view.dart';

class ParentTaskSelector extends StatelessWidget {
  final String? parentTaskId;
  final TodoService todoService;
  final Function() onShowSelectionDialog;

  const ParentTaskSelector({
    super.key,
    required this.parentTaskId,
    required this.todoService,
    required this.onShowSelectionDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onShowSelectionDialog,
          child: InputDecorator(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.account_tree),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    parentTaskId != null
                        ? todoService.tasks
                                .where((t) => t.id == parentTaskId)
                                .map((t) => t.title)
                                .firstOrNull ??
                            '父任务不存在'
                        : '无父任务',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ParentTaskSelectionDialog extends StatelessWidget {
  final TodoService todoService;
  final TaskItem? currentTask;
  final String? selectedTaskId;
  final Function(String?) onTaskSelected;

  const ParentTaskSelectionDialog({
    super.key,
    required this.todoService,
    this.currentTask,
    this.selectedTaskId,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: const Row(
        children: [Icon(Icons.account_tree), SizedBox(width: 8), Text('选择父任务')],
      ),
      content: Container(
        width: double.maxFinite,
        height: 300,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
        child: TaskTreeView(
          todoService: todoService,
          currentTask: currentTask,
          selectedTaskId: selectedTaskId,
          onTaskSelected: (taskId) {
            onTaskSelected(taskId);
            Navigator.of(context).pop();
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            onTaskSelected(null);
            Navigator.of(context).pop();
          },
          child: const Text('清除选择'),
        ),
      ],
    );
  }
}
