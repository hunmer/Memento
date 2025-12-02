import 'package:flutter/material.dart';
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/todo/screens/todo_list_selector_screen.dart';
import 'package:Memento/plugins/todo/widgets/task_detail_view.dart';
import 'package:Memento/plugins/todo/widgets/task_form.dart';
import 'package:Memento/plugins/todo/views/todo_main_view.dart';

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
        return createRoute(
          TaskDetailView(
            task: tasks.first,
            taskController: plugin.taskController,
            reminderController: plugin.reminderController,
          ),
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
