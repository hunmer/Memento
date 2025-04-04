import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'models/timer_task.dart';
import 'models/timer_item.dart';
import 'views/timer_main_view.dart';
import '../../widgets/group_management_dialog.dart';

class TimerPlugin extends BasePlugin {
  static final TimerPlugin instance = TimerPlugin._internal();
  static const MethodChannel _channel = MethodChannel(
    'github.hunmer.memento/timer_service',
  );

  TimerPlugin._internal();

  static const String _id = 'timer';
  static const String _name = '计时器';
  static const String _version = '1.0.0';
  static const String _description = '支持多种计时类型的任务管理器';
  static const String _author = 'Zulu';
  static const String _pluginDir = 'timer';

  List<TimerTask> _tasks = [];
  Map<String, bool> _expandedGroups = {};

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  String get version => _version;

  @override
  String get description => _description;

  @override
  String get author => _author;

  @override
  String get pluginDir => _pluginDir;

  @override
  Future<void> initialize() async {
    await _loadTasks();

    // 如果没有任何任务，添加默认示例任务
    if (_tasks.isEmpty) {
      await _addDefaultTasks();
    }
  }

  // 创建默认的计时器任务
  Future<void> _addDefaultTasks() async {
    // 1. 测试正计时器: 正计时1分钟
    final countUpTask = TimerTask.create(
      name: '测试正计时器',
      color: Colors.blue,
      icon: Icons.timer,
      group: '测试',
      timerItems: [
        TimerItem.countUp(
          name: '正计时1分钟',
          targetDuration: const Duration(minutes: 1),
        ),
      ],
    );

    // 2. 测试倒计时器: 倒计时1分钟
    final countDownTask = TimerTask.create(
      name: '测试倒计时器',
      color: Colors.red,
      icon: Icons.hourglass_empty,
      group: '测试',
      timerItems: [
        TimerItem.countDown(
          name: '倒计时1分钟',
          duration: const Duration(minutes: 1),
        ),
      ],
    );

    // 3. 测试番茄钟：25秒专注 5秒休息
    final pomodoroTask = TimerTask.create(
      name: '测试番茄钟',
      color: Colors.green,
      icon: Icons.local_cafe,
      group: '工作效率',
      timerItems: [
        TimerItem.pomodoro(
          name: '番茄工作法',
          workDuration: const Duration(seconds: 25),
          breakDuration: const Duration(seconds: 5),
          cycles: 4,
        ),
      ],
    );

    // 4. 测试多计时器：正计时10秒 倒计时10秒
    final multiTimerTask = TimerTask.create(
      name: '测试多计时器',
      color: Colors.purple,
      icon: Icons.timer_outlined,
      group: '测试',
      timerItems: [
        TimerItem.countUp(
          name: '正计时10秒',
          targetDuration: const Duration(seconds: 10),
        ),
        TimerItem.countDown(
          name: '倒计时10秒',
          duration: const Duration(seconds: 10),
        ),
      ],
    );

    // 添加所有默认任务
    await addTask(countUpTask);
    await addTask(countDownTask);
    await addTask(pomodoroTask);
    await addTask(multiTimerTask);
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 注册插件配置
    await configManager.savePluginConfig(_id, {
      'maxTasksPerRow': 2, // 默认一行显示2个任务
      'maxTasksPerRowLimit': 6, // 最大支持一行显示6个任务
    });
  }

  @override
  Widget buildMainView(BuildContext context) {
    return TimerMainView(plugin: this);
  }

  // 获取所有计时器任务
  List<TimerTask> getTasks() => _tasks;

  // 获取分组列表
  List<String> get groups =>
      _tasks.map((task) => task.group).toSet().toList()..sort();

  // 获取分组展开状态
  Map<String, bool> get expandedGroups => _expandedGroups;

  // 切换分组展开状态
  void toggleGroupExpansion(String group) {
    _expandedGroups[group] = !(_expandedGroups[group] ?? true);
  }

  // 添加新任务
  Future<void> addTask(TimerTask task) async {
    _tasks.add(task);
    await _saveTasks();
  }

  // 删除任务
  Future<void> removeTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks();
  }

  // 更新任务
  Future<void> updateTask(TimerTask task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await _saveTasks();
      await _updateNotification(task);
    }
  }

  // 启动前台通知服务
  Future<void> startNotificationService(TimerTask task) async {
    try {
      print('Starting notification service for task: ${task.name}');
      await _channel.invokeMethod('startTimerService', {
        'taskId': task.id,
        'taskName': task.name,
        'totalSeconds': task.totalDuration.inSeconds,
        'currentSeconds': task.elapsedDuration.inSeconds,
      });
      print('Notification service started successfully');
    } catch (e) {
      print('Error starting notification service: $e');
    }
  }

  // 更新前台通知
  Future<void> _updateNotification(TimerTask task) async {
    if (task.isRunning) {
      try {
        print('Updating notification for task: ${task.name}');
        await _channel.invokeMethod('updateTimerService', {
          'taskId': task.id,
          'taskName': task.name,
          'totalSeconds': task.totalDuration.inSeconds,
          'currentSeconds': task.elapsedDuration.inSeconds,
        });
        print('Notification updated successfully');
      } catch (e) {
        print('Error updating notification: $e');
      }
    } else {
      await stopNotificationService(task.id);
    }
  }

  // 停止前台通知服务
  Future<void> stopNotificationService([String? taskId]) async {
    try {
      print(
        'Stopping notification service' +
            (taskId != null ? ' for task: $taskId' : ''),
      );
      await _channel.invokeMethod('stopTimerService', {'taskId': taskId ?? ''});
      print('Notification service stopped successfully');
    } catch (e) {
      print('Error stopping notification service: $e');
    }
  }

  // 从存储加载任务
  Future<void> _loadTasks() async {
    try {
      final data = await storage.read('$_id.tasks');
      final tasksData = data['tasks'] as List?;
      if (tasksData != null) {
        _tasks =
            tasksData
                .map((data) => TimerTask.fromJson(data as Map<String, dynamic>))
                .toList();
      }
      final expandedGroupsData =
          data['expandedGroups'] as Map<String, dynamic>?;
      if (expandedGroupsData != null) {
        _expandedGroups = Map<String, bool>.from(expandedGroupsData);
      }
    } catch (e) {
      // 如果文件不存在或读取出错，使用空列表
      _tasks = [];
      _expandedGroups = {};
    }
  }

  // 保存任务到存储
  Future<void> _saveTasks() async {
    final tasksData = _tasks.map((task) => task.toJson()).toList();
    await storage.write('$_id.tasks', {
      'tasks': tasksData,
      'expandedGroups': _expandedGroups,
    });
  }

  // 显示分组管理对话框
  void showGroupManagementDialog(BuildContext context) {
    final dialog = GroupManagementDialog<TimerTask>(
      context: context,
      items: _tasks,
      getGroupName: (task) => task.group,
      getItemName: (task) => task.name,
      isItemChecked: (task) => task.isRunning,
      updateItemGroup: (task, newGroup) async {
        task.group = newGroup;
        _expandedGroups.remove(task.group);
        _expandedGroups[newGroup] = true;
        await _saveTasks();
      },
      createNewGroup: (name, icon, color) async {
        final newTask = TimerTask.create(
          name: name,
          color: color,
          icon: icon,
          group: name,
          timerItems: [],
        );
        await addTask(newTask);
        _expandedGroups[name] = true;
      },
      onStateChanged: () async {
        await _saveTasks();
      },
    );
    dialog.show();
  }
}
