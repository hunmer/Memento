import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/todo/screens/todo_list_selector_screen.dart';
import 'package:Memento/plugins/todo/widgets/task_form.dart';
import 'package:Memento/plugins/todo/views/todo_main_view.dart';
import 'package:Memento/plugins/todo/models/task.dart';

/// 待办插件路由处理器
class TodoRouteHandler extends PluginRouteHandler {
  @override
  String get pluginId => 'todo';

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // 处理待办列表小组件配置路由
    // 格式: /todo_list_selector?widgetId={widgetId}
    // 或者 widgetId 通过 settings.arguments 传递
    if (routeName.startsWith('/todo_list_selector')) {
      return _handleListSelectorRoute(routeName, settings.arguments);
    }

    // 处理待办任务详情路由（从小组件打开）
    // 格式: /todo_task_detail?taskId={taskId}
    if (routeName.startsWith('/todo_task_detail')) {
      return _handleTaskDetailRoute(routeName, settings.arguments);
    }

    // 处理待办添加任务路由（从小组件打开）
    // 格式: /todo_add
    if (routeName == '/todo_add') {
      return _handleAddTaskRoute();
    }

    // 处理待办列表小组件点击路由（已配置状态）
    // 格式: /todo_list?taskId={taskId}
    if (routeName.startsWith('/todo_list') && !routeName.contains('_selector')) {
      return _handleListClickRoute();
    }

    return null;
  }

  /// 处理待办列表选择器路由
  Route<dynamic> _handleListSelectorRoute(String routeName, Object? arguments) {
    int? widgetId;

    // 优先从 arguments 中获取 widgetId（来自 main.dart 的路由处理）
    if (arguments is Map<String, dynamic>) {
      final widgetIdValue = arguments['widgetId'];
      if (widgetIdValue is int) {
        widgetId = widgetIdValue;
      } else if (widgetIdValue is String) {
        widgetId = int.tryParse(widgetIdValue);
      }
    } else if (arguments is Map<String, String>) {
      final widgetIdStr = arguments['widgetId'];
      widgetId = widgetIdStr != null ? int.tryParse(widgetIdStr) : null;
    }

    // 备用：从 URI 中解析 widgetId
    if (widgetId == null) {
      final uri = Uri.parse(routeName);
      final widgetIdStr = uri.queryParameters['widgetId'];
      widgetId = widgetIdStr != null ? int.tryParse(widgetIdStr) : null;
    }

    debugPrint('待办列表小组件配置路由: widgetId=$widgetId');
    return createRoute(TodoListSelectorScreen(widgetId: widgetId));
  }

  /// 处理任务详情路由
  Route<dynamic> _handleTaskDetailRoute(String routeName, Object? arguments) {
    String? taskId;

    if (arguments is Map<String, String>) {
      taskId = arguments['taskId'];
    } else {
      final uri = Uri.parse(routeName);
      taskId = uri.queryParameters['taskId'];
    }

    debugPrint('打开任务详情: taskId=$taskId');

    if (taskId != null) {
      // 查找任务
      final plugin = TodoPlugin.instance;
      final tasks = plugin.taskController.tasks.where((t) => t.id == taskId);

      if (tasks.isNotEmpty) {
        // 打开主界面并显示任务详情对话框
        final task = tasks.first;
        return createRoute(
          TodoMainViewWithTaskDetail(task: task),
        );
      }
    }

    // 没有找到任务，打开待办列表
    return createRoute(const TodoMainView());
  }

  /// 处理添加任务路由
  Route<dynamic> _handleAddTaskRoute() {
    debugPrint('打开添加任务界面');

    final plugin = TodoPlugin.instance;
    return createRoute(
      TaskForm(
        taskController: plugin.taskController,
        reminderController: plugin.reminderController,
      ),
    );
  }

  /// 处理列表点击路由
  Route<dynamic> _handleListClickRoute() {
    debugPrint('打开待办列表界面');

    // 打开待办插件主界面
    return createRoute(const TodoMainView());
  }
}

/// 带任务详情对话框的 TodoMainView
class TodoMainViewWithTaskDetail extends StatefulWidget {
  final Task task;

  const TodoMainViewWithTaskDetail({
    super.key,
    required this.task,
  });

  @override
  State<TodoMainViewWithTaskDetail> createState() =>
      _TodoMainViewWithTaskDetailState();
}

class _TodoMainViewWithTaskDetailState extends State<TodoMainViewWithTaskDetail> {
  late TodoPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = TodoPlugin.instance;

    // 延迟显示对话框，确保页面已加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTaskDetailDialog(context, widget.task);
    });
  }

  void _showTaskDetailDialog(BuildContext context, Task task) {
    final l10n = TodoLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty) ...[
                Text(
                  l10n.description,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(task.description!),
                const SizedBox(height: 16),
              ],
              if (task.tags.isNotEmpty) ...[
                Text(
                  l10n.tags,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: task.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Colors.blue.shade100,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.timer,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.formattedDuration,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: task.status == TaskStatus.inProgress
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.start),
                    onPressed: task.status != TaskStatus.inProgress
                        ? () {
                            _plugin.taskController.updateTaskStatus(
                              task.id,
                              TaskStatus.inProgress,
                            );
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.pause),
                    label: Text(l10n.pause),
                    onPressed: task.status == TaskStatus.inProgress
                        ? () {
                            _plugin.taskController.updateTaskStatus(
                              task.id,
                              TaskStatus.todo,
                            );
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text(l10n.complete),
                    onPressed: task.status != TaskStatus.done
                        ? () {
                            _plugin.taskController.updateTaskStatus(
                              task.id,
                              TaskStatus.done,
                            );
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 导航到编辑页面
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TaskForm(
                    task: task,
                    taskController: _plugin.taskController,
                    reminderController: _plugin.reminderController,
                  ),
                ),
              );
            },
            child: Text(l10n.edit),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.deleteTask),
                  content: Text(l10n.confirmDeleteThisTask),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _plugin.taskController.deleteTask(task.id);
                Navigator.of(context).pop();
              }
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const TodoMainView();
  }
}

