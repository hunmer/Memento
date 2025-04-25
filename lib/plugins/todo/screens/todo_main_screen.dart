import 'package:Memento/core/plugin_manager.dart';
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
    // 如果是编辑现有任务，使用任务自己的父任务ID
    if (task != null && task.id.isNotEmpty) {
      // 查找此任务的父任务
      parentTaskId =
          _todoService.tasks
              .firstWhere(
                (t) => t.subTaskIds.contains(task.id),
                orElse:
                    () =>
                        TaskItem(id: '', title: '', createdAt: DateTime.now()),
              )
              .id;
      if (parentTaskId.isEmpty) {
        parentTaskId = null;
      }
    }
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
        // 任务已经通过 TodoService 添加或更新，这里只需要触发重建即可
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
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
                      // 如果是新建子任务（空ID），则传递父任务ID
                      if (taskToEdit.id.isEmpty &&
                          taskToEdit.parentTaskId != null) {
                        _showAddTaskDialog(
                          parentTaskId: taskToEdit.parentTaskId,
                        );
                      } else {
                        _showAddTaskDialog(task: taskToEdit);
                      }
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
