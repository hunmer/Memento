import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../models/task_item.dart';
import '../widgets/task_item_widget.dart';
import '../widgets/task_edit_dialog.dart';
import '../../plugin_widget.dart';

class TodoMainScreen extends StatefulWidget {
  const TodoMainScreen({super.key});

  @override
  State<TodoMainScreen> createState() => TodoMainScreenState();
}

class TodoMainScreenState extends State<TodoMainScreen> {
  late TodoService _todoService;
  String currentGroup = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 在 initState 中不要访问 context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // 获取插件实例
      final pluginWidget = PluginWidget.of(context);
      if (pluginWidget == null) {
        throw Exception('TodoMainScreen must be a child of a PluginWidget');
      }
      _todoService = TodoService.getInstance(pluginWidget.plugin.storage);
      _todoService.init();
      _isInitialized = true;
    }
  }

  // 显示新建/编辑任务对话框
  Future<void> _showAddTaskDialog({
    TaskItem? task,
    String? parentTaskId,
  }) async {
    // 获取当前的 PluginWidget
    final pluginWidget = PluginWidget.of(context);
    if (pluginWidget == null) {
      throw Exception('TodoMainScreen must be a child of a PluginWidget');
    }

    final result = await showDialog<TaskItem>(
      context: context,
      builder:
          (context) => PluginWidget(
            plugin: pluginWidget.plugin,
            child: TaskEditDialog(task: task, parentTaskId: parentTaskId),
          ),
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
        currentGroup.isEmpty
            ? _todoService.getMainTasks()
            : _todoService.getTasksByGroup(currentGroup);

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
        onPressed: () => _showAddTaskDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
