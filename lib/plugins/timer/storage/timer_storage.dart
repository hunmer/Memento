import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:flutter/material.dart';

import '../models/timer_task.dart';

class TimerStorage {
  final String pluginId;
  final StorageManager storage;

  TimerStorage(this.pluginId, this.storage);

  // 从存储加载任务
  Future<Map<String, dynamic>> loadTasks() async {
    try {
      final data = await storage.read('$pluginId.tasks');
      return {
        'tasks':
            data['tasks'] != null
                ? (data['tasks'] as List)
                    .map(
                      (data) =>
                          TimerTask.fromJson(data as Map<String, dynamic>),
                    )
                    .toList()
                : <TimerTask>[],
        'expandedGroups':
            data['expandedGroups'] != null
                ? Map<String, bool>.from(data['expandedGroups'])
                : <String, bool>{},
      };
    } catch (e) {
      return {'tasks': <TimerTask>[], 'expandedGroups': <String, bool>{}};
    }
  }

  // 保存任务到存储
  Future<void> saveTasks(
    List<TimerTask> tasks,
    Map<String, bool> expandedGroups,
  ) async {
    final tasksData = tasks.map((task) => task.toJson()).toList();
    await storage.write('$pluginId.tasks', {
      'tasks': tasksData,
      'expandedGroups': expandedGroups,
    });
  }

  // 创建默认的计时器任务
  static List<TimerTask> createDefaultTasks() {
    return [
      // 1. 测试正计时器: 正计时1分钟
      TimerTask.create(
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
      ),
      // 2. 测试倒计时器: 倒计时1分钟
      TimerTask.create(
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
      ),
      // 3. 测试番茄钟：25秒专注 5秒休息
      TimerTask.create(
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
      ),
      // 4. 测试多计时器：正计时10秒 倒计时10秒
      TimerTask.create(
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
      ),
    ];
  }
}
