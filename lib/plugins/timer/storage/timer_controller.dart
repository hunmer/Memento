import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/timer_task.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';

class TimerController {
  final StorageManager storage;
  List<TimerTask> _tasks = [];

  TimerController(this.storage);

  List<TimerTask> getTasks() => _tasks;

  // 从存储加载任务
  Future<Map<String, dynamic>> loadTasks() async {
    try {
      final data = await storage.read('timer/tasks');
      _tasks =
          data['tasks'] != null
              ? (data['tasks'] as List)
                  .map(
                    (data) => TimerTask.fromJson(data as Map<String, dynamic>),
                  )
                  .toList()
              : <TimerTask>[];
      return {'tasks': _tasks};
    } catch (e) {
      _tasks = <TimerTask>[];
      return {'tasks': _tasks};
    }
  }

  // 保存任务到存储
  Future<void> saveTasks(List<TimerTask> tasks) async {
    final tasksData = tasks.map((task) => task.toJson()).toList();
    await storage.write('timer/tasks', {'tasks': tasksData});
    await _syncWidget();
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    await PluginWidgetSyncHelper.instance.syncTimer();
  }

  // 获取所有任务的分组名称（去重）
  List<String> getGroups() {
    final groups = _tasks.map((task) => task.group).toSet().toList();
    return groups;
  }

  // 更新所有任务的分组名称
  void updateTaskGroups(String oldName, String newName) {
    for (var task in _tasks) {
      if (task.group == oldName) {
        task.group = newName;
      }
    }
    saveTasks(_tasks);
  }

  // 删除分组并将相关任务移动到默认分组
  void deleteGroup(String groupName) {
    for (var task in _tasks) {
      if (task.group == groupName) {
        task.group = '默认';
      }
    }
    saveTasks(_tasks);
  }

  // 创建默认的计时器任务
  static List<TimerTask> createDefaultTasks() {
    return [
      // 1. 测试正计时器: 正计时1分钟
      TimerTask.create(
        id: Uuid().v4(),
        name: '测试正计时器',
        color: Colors.blue,
        icon: Icons.timer,
        group: '测试',
        timerItems: [
          TimerItem.countUp(
            name: '正计时',
            targetDuration: const Duration(seconds: 3),
          ),
        ],
      ),
      // 2. 测试倒计时器: 倒计时1分钟
      TimerTask.create(
        id: Uuid().v4(),
        name: '测试倒计时器',
        color: Colors.red,
        icon: Icons.hourglass_empty,
        group: '测试',
        timerItems: [
          TimerItem.countDown(
            name: '倒计时',
            duration: const Duration(seconds: 3),
          ),
        ],
      ),
      // 3. 测试番茄钟：25秒专注 5秒休息
      TimerTask.create(
        id: Uuid().v4(),
        name: '测试番茄钟',
        color: Colors.green,
        icon: Icons.local_cafe,
        group: '工作效率',
        timerItems: [
          TimerItem.pomodoro(
            name: '番茄工作法',
            workDuration: const Duration(seconds: 5),
            breakDuration: const Duration(seconds: 5),
            cycles: 4,
          ),
        ],
      ),
      // 4. 测试多计时器：正计时10秒 倒计时10秒
      TimerTask.create(
        id: Uuid().v4(),
        name: '测试多计时器',
        color: Colors.purple,
        icon: Icons.timer_outlined,
        group: '测试',
        timerItems: [
          TimerItem.countUp(
            name: '正计时10秒',
            targetDuration: const Duration(seconds: 3),
          ),
          TimerItem.countDown(
            name: '倒计时10秒',
            duration: const Duration(seconds: 3),
          ),
        ],
      ),
    ];
  }
}
