import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../models/task_item.dart';
import '../widgets/task_item_widget.dart';
import '../widgets/task_edit_dialog.dart';
import '../widgets/group_management_dialog.dart';

class TodoMainScreen extends StatefulWidget {
  const TodoMainScreen({super.key});

  @override
  _TodoMainScreenState createState() => _TodoMainScreenState();
}

class _TodoMainScreenState extends State<TodoMainScreen> {
  final TodoService _todoService = TodoService();
  String _currentGroup = '';

  @override
  void initState() {
    super.initState();
    _todoService.init();
  }

  // 显示新建/编辑任务对话框
  Future<void> _showAddTaskDialog({
    TaskItem? task,
    String? parentTaskId,
  }) async {
    final result = await showDialog<TaskItem>(
      context: context,
      builder:
          (context) => TaskEditDialog(task: task, parentTaskId: parentTaskId),
    );

    if (result != null) {
      setState(() {
        // 刷新UI
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks =
        _currentGroup.isEmpty
            ? _todoService.getMainTasks()
            : _todoService.getTasksByGroup(_currentGroup);

    return Scaffold(
      appBar: AppBar(
        title: Text('任务插件', style: TextStyle(fontSize: 20)),
        centerTitle: false, // 标题靠左
        actions: [],
      ),
      body:
          tasks.isEmpty
              ? Center(
                child: Text(
                  '没有任务',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
              : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskItemWidget(
                    task: task,
                    subTasks: _todoService.getSubTasks(task.id),
                    isTreeView: true,
                    onToggleComplete: () {
                      setState(() {
                        task.toggleComplete();
                        _todoService.updateTask(task);
                      });
                    },
                    onEdit: (taskToEdit) {
                      _showAddTaskDialog(task: taskToEdit);
                    },
                    onDelete: (taskToDelete) {
                      setState(() {
                        _todoService.deleteTask(taskToDelete.id);
                      });
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
