import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'controllers/controllers.dart';
import 'models/models.dart';
import 'views/todo_bottombar_view.dart';

// 导入 UseCase 相关
import 'package:shared_models/shared_models.dart';
import 'repositories/client_todo_repository.dart';

part 'todo_js_api.dart';
part 'todo_data_selectors.dart';

class TodoPlugin extends BasePlugin with ChangeNotifier, JSBridgePlugin {
  late TaskController taskController;
  late ReminderController reminderController;

  // UseCase 相关
  late ClientTodoRepository _repository;
  late TodoUseCase _todoUseCase;

  static TodoPlugin? _instance;
  static TodoPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (_instance == null) {
        throw StateError('TodoPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String get id => 'todo';

  @override
  IconData get icon => Icons.check_box;

  @override
  Color get color => Colors.blue;

  @override
  String? getPluginName(context) {
    return 'todo_name'.tr;
  }

  @override
  Future<void> initialize() async {
    taskController = TaskController(storageManager, storageDir);
    reminderController = ReminderController();

    // 初始化提醒控制器（使用系统日历）
    await reminderController.initialize();

    // 创建 Repository 和 UseCase 实例
    _repository = ClientTodoRepository(taskController);
    _todoUseCase = TodoUseCase(_repository);

    // 加载默认设置
    await loadSettings({
      'defaultView': 'list', // 'list' or 'grid'
      'defaultSortBy': 'dueDate', // 'dueDate', 'priority', or 'custom'
      'reminderAdvanceTime': 60, // minutes
    });

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 注册数据选择器
    _registerDataSelectors();
  }

  @override
  Future<void> registerToApp(
    
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 注册插件相关服务
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const TodoBottomBarView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    final totalTasks = taskController.getTotalTaskCount();
    final weeklyTasks = taskController.getWeeklyTaskCount();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                'todo_name'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'todo_totalTasksCount'.tr,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '$totalTasks',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'todo_weeklyTasksCount'.tr,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '$weeklyTasks',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Future<void> uninstall() async {
    // 清理插件数据
    await storageManager.delete(storageDir);
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 任务查询
      'getTasks': _jsGetTasks,
      'getTask': _jsGetTask,
      'getTodayTasks': _jsGetTodayTasks,
      'getOverdueTasks': _jsGetOverdueTasks,
      'getUpcomingTasks': _jsGetUpcomingTasks,

      // 任务操作
      'createTask': _jsCreateTask,
      'updateTask': _jsUpdateTask,
      'deleteTask': _jsDeleteTask,
      'completeTask': _jsCompleteTask,

      // 任务查找方法
      'findTaskBy': _jsFindTaskBy,
      'findTaskById': _jsFindTaskById,
      'findTaskByTitle': _jsFindTaskByTitle,
      'findTasksByTag': _jsFindTasksByTag,
      'findTasksByStatus': _jsFindTasksByStatus,
      'findTasksByPriority': _jsFindTasksByPriority,
    };
  }
}
