/// 统一计时器控制器
///
/// 这是整个计时器系统的核心，负责：
/// - 全局管理所有计时器
/// - 提供统一的计时器操作API
/// - 管理通知栏同步
/// - 处理事件广播
/// - 状态持久化
library;

import 'dart:async';
import 'dart:io';

import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/event_args.dart';
import 'package:flutter/material.dart';

import '../foreground_timer_service.dart';
import 'events/timer_events.dart';
import 'models/timer_state.dart';
import 'storage/timer_storage.dart';

/// 统一计时器控制器（单例）
class UnifiedTimerController {
  static UnifiedTimerController? _instance;

  factory UnifiedTimerController() =>
      _instance ??= UnifiedTimerController._internal();

  UnifiedTimerController._internal();

  // ========== 核心数据 ==========

  /// 所有活动计时器 Map[id -> TimerState]
  final Map<String, TimerState> _timers = {};

  /// 全局更新计时器（每秒更新一次）
  Timer? _globalUpdateTimer;

  /// 是否已初始化
  bool _initialized = false;

  // ========== 公共API ==========

  /// 初始化统一计时器控制器
  ///
  /// [onTimerUpdate] 可选的计时器更新回调
  Future<void> initialize({Function(TimerState)? onTimerUpdate}) async {
    if (_initialized) {
      print('UnifiedTimerController already initialized');
      return;
    }

    print('Initializing UnifiedTimerController...');

    // 加载活动计时器
    await _loadActiveTimers();

    // 启动全局更新计时器
    _startGlobalUpdateTimer();

    _initialized = true;
    print('UnifiedTimerController initialized successfully');
  }

  /// 启动计时器
  ///
  /// [id] 计时器唯一ID
  /// [name] 计时器名称
  /// [type] 计时器类型
  /// [color] 主题色
  /// [icon] 图标
  /// [targetDuration] 目标时长（倒计时需要）
  /// [stages] 多阶段配置（可选）
  /// [pluginId] 插件ID
  Future<void> startTimer({
    required String id,
    required String name,
    required TimerType type,
    required Color color,
    IconData icon = Icons.timer,
    Duration? targetDuration,
    List<TimerItemConfig> stages = const [],
    String pluginId = 'timer',
  }) async {
    // 检查是否已存在
    if (_timers.containsKey(id)) {
      print('Timer $id already exists');
      return;
    }

    // 创建计时器状态
    final state = TimerState(
      id: id,
      name: name,
      type: type,
      status: TimerStatus.running,
      elapsed: Duration.zero,
      targetDuration: targetDuration,
      isCountdown: type == TimerType.countDown,
      color: color,
      icon: icon,
      stages: stages,
      pluginId: pluginId,
    );

    // 添加到活动计时器
    _timers[id] = state;

    // 启动计时器
    state.start();

    // 更新通知栏
    await _updateNotification(state);

    // 广播事件
    _broadcastEvent(state, TimerEventType.started);

    // 保存状态
    await _saveActiveTimers();

    print('Timer $id started: $name');
  }

  /// 暂停计时器
  Future<void> pauseTimer(String id) async {
    final state = _timers[id];
    if (state == null || state.status != TimerStatus.running) {
      print('Timer $id not found or not running');
      return;
    }

    state.pause();

    // 更新通知栏
    await _updateNotification(state);

    // 广播事件
    _broadcastEvent(state, TimerEventType.paused);

    // 保存状态
    await _saveActiveTimers();

    print('Timer $id paused: ${state.name}');
  }

  /// 恢复计时器
  Future<void> resumeTimer(String id) async {
    final state = _timers[id];
    if (state == null || state.status != TimerStatus.paused) {
      print('Timer $id not found or not paused');
      return;
    }

    state.start();

    // 更新通知栏
    await _updateNotification(state);

    // 广播事件
    _broadcastEvent(state, TimerEventType.resumed);

    // 保存状态
    await _saveActiveTimers();

    print('Timer $id resumed: ${state.name}');
  }

  /// 停止计时器
  Future<void> stopTimer(String id) async {
    final state = _timers[id];
    if (state == null) {
      print('Timer $id not found');
      return;
    }

    final wasRunning = state.status == TimerStatus.running;

    state.stop();

    // 停止通知栏（延迟5秒后清除，给用户时间看到完成状态）
    if (wasRunning) {
      Timer(const Duration(seconds: 5), () {
        ForegroundTimerService.stopService(id);
      });
    }

    // 广播事件
    _broadcastEvent(state, TimerEventType.stopped);

    // 保存历史记录
    await TimerStorage.saveTimerHistory(
      timerId: id,
      timerName: state.name,
      pluginId: state.pluginId,
      duration: state.elapsed,
      completed: state.isCompleted,
      color: state.color,
      icon: state.icon,
    );

    // 移除活动计时器
    _timers.remove(id);

    // 保存状态
    await _saveActiveTimers();

    print('Timer $id stopped: ${state.name}');
  }

  /// 重置计时器
  Future<void> resetTimer(String id) async {
    final state = _timers[id];
    if (state == null) {
      print('Timer $id not found');
      return;
    }

    state.reset();

    // 更新通知栏
    await _updateNotification(state);

    // 广播事件
    _broadcastEvent(state, TimerEventType.updated);

    // 保存状态
    await _saveActiveTimers();

    print('Timer $id reset: ${state.name}');
  }

  /// 获取计时器状态
  TimerState? getTimer(String id) => _timers[id];

  /// 获取所有活动计时器
  List<TimerState> getActiveTimers() {
    return _timers.values.toList();
  }

  /// 获取指定插件的活动计时器
  List<TimerState> getActiveTimersByPlugin(String pluginId) {
    return _timers.values.where((timer) => timer.pluginId == pluginId).toList();
  }

  /// 检查计时器是否存在
  bool hasTimer(String id) => _timers.containsKey(id);

  /// 检查是否有活动计时器
  bool hasActiveTimers() => _timers.isNotEmpty;

  /// 检查指定插件是否有活动计时器
  bool hasActiveTimerByPlugin(String pluginId) {
    return _timers.values.any((timer) => timer.pluginId == pluginId);
  }

  /// 获取活动计时器数量
  int getActiveTimerCount() => _timers.length;

  /// 立即更新通知栏
  Future<void> refreshNotification(String id) async {
    final state = _timers[id];
    if (state != null) {
      await _updateNotification(state);
    }
  }

  /// 批量更新所有活动计时器的通知栏
  Future<void> refreshAllNotifications() async {
    for (final state in _timers.values) {
      await _updateNotification(state);
    }
  }

  /// 获取存储信息
  Future<Map<String, dynamic>> getStorageInfo() async {
    return await TimerStorage.getStorageInfo();
  }

  /// 导出所有数据
  Future<String> exportData() async {
    return await TimerStorage.exportData();
  }

  /// 导入数据
  Future<void> importData(String jsonData) async {
    await TimerStorage.importData(jsonData);
    await _loadActiveTimers();
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    await TimerStorage.clearAll();
    _timers.clear();
    await _saveActiveTimers();
  }

  // ========== 私有方法 ==========

  /// 启动全局更新计时器
  void _startGlobalUpdateTimer() {
    _globalUpdateTimer?.cancel();
    _globalUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateAllTimers();
    });
  }

  /// 更新所有活动计时器
  void _updateAllTimers() {
    if (_timers.isEmpty) return;

    final completedTimers = <String>[];

    for (final state in _timers.values) {
      if (state.status == TimerStatus.running) {
        // 更新计时器状态
        state.tick();

        // 检查是否完成
        if (state.isCompleted) {
          completedTimers.add(state.id);
          _broadcastEvent(state, TimerEventType.completed);
          print('Timer completed: ${state.name}');
        } else {
          // 广播更新事件
          _broadcastEvent(state, TimerEventType.updated);
        }
      }
    }

    // 异步更新通知栏
    _updateAllNotificationsAsync();

    // 处理已完成的计时器
    for (final id in completedTimers) {
      _handleTimerCompleted(id);
    }
  }

  /// 异步更新所有通知栏
  Future<void> _updateAllNotificationsAsync() async {
    for (final state in _timers.values) {
      if (state.status == TimerStatus.running ||
          state.status == TimerStatus.paused) {
        // 使用 microtask 避免阻塞主循环
        Future.microtask(() => _updateNotification(state));
      }
    }
  }

  /// 更新单个通知栏
  Future<void> _updateNotification(TimerState state) async {
    if (!Platform.isAndroid) return;

    try {
      final displayText = state.getCurrentStageDisplay();
      final progress = state.getProgress();
      final maxProgress = state.getMaxProgress();

      if (maxProgress == 0) {
        // 正计时无上限，显示无限进度条
        await ForegroundTimerService.startService(
          id: state.id,
          title: '${_getPluginDisplayName(state.pluginId)} - ${state.name}',
          content: '$displayText (${_getStatusText(state.status)})',
          progress: progress,
          maxProgress: 100,
          color: state.color,
        );
      } else {
        // 倒计时或多阶段计时器，有明确上限
        await ForegroundTimerService.startService(
          id: state.id,
          title: '${_getPluginDisplayName(state.pluginId)} - ${state.name}',
          content: '$displayText (${_getStatusText(state.status)})',
          progress: progress,
          maxProgress: 100,
          color: state.color,
        );
      }
    } catch (e) {
      print('Error updating notification for timer ${state.id}: $e');
    }
  }

  /// 处理计时器完成
  Future<void> _handleTimerCompleted(String id) async {
    final state = _timers[id];
    if (state == null) return;

    // 停止通知栏（延迟清除）
    Timer(const Duration(seconds: 10), () {
      ForegroundTimerService.stopService(id);
    });

    // 保存历史记录
    await TimerStorage.saveTimerHistory(
      timerId: id,
      timerName: state.name,
      pluginId: state.pluginId,
      duration: state.elapsed,
      completed: true,
      color: state.color,
      icon: state.icon,
    );

    // 移除活动计时器
    _timers.remove(id);
    await _saveActiveTimers();
  }

  /// 加载活动计时器
  Future<void> _loadActiveTimers() async {
    try {
      final activeTimers = await TimerStorage.loadActiveTimers();
      _timers.clear();
      _timers.addAll(activeTimers);

      // 重新启动已保存的计时器
      for (final state in _timers.values) {
        if (state.status == TimerStatus.running) {
          // 重新设置开始时间
          state.start();
        }
      }

      print('Loaded ${_timers.length} active timers');
    } catch (e) {
      print('Error loading active timers: $e');
      _timers.clear();
    }
  }

  /// 保存活动计时器
  Future<void> _saveActiveTimers() async {
    try {
      await TimerStorage.saveActiveTimers(_timers.values.toList());
    } catch (e) {
      print('Error saving active timers: $e');
    }
  }

  /// 广播事件
  void _broadcastEvent(TimerState state, TimerEventType type) {
    try {
      // 统一事件系统
      final unifiedEvent = UnifiedTimerEventArgs(state, type);
      EventManager.instance.broadcast(
        TimerEventHelper.getEventName(type),
        unifiedEvent as EventArgs,
      );

      // 转发给插件专用事件系统
      _forwardToPluginEvents(state, type);
    } catch (e) {
      print('Error broadcasting event: $e');
    }
  }

  /// 转发事件到插件专用系统
  void _forwardToPluginEvents(TimerState state, TimerEventType type) {
    switch (state.pluginId) {
      case 'timer':
        // Timer插件的事件处理将在TimerPluginAdapter中实现
        break;
      case 'habits':
        if (type == TimerEventType.started) {
          EventManager.instance.broadcast(
            TimerEventNames.habitTimerStarted,
            Values<String, bool>(state.id, true),
          );
        } else if (type == TimerEventType.stopped ||
            type == TimerEventType.completed) {
          EventManager.instance.broadcast(
            TimerEventNames.habitTimerStopped,
            Values<String, bool>(state.id, false),
          );
        }
        break;
      case 'todo':
        // Todo插件当前无专用事件系统
        break;
      case 'tracker':
        // Tracker插件当前无专用事件系统
        break;
    }
  }

  /// 获取插件显示名称
  String _getPluginDisplayName(String pluginId) {
    const Map<String, String> names = {
      'timer': '计时器',
      'habits': '习惯追踪',
      'todo': '待办事项',
      'tracker': '目标追踪',
    };
    return names[pluginId] ?? 'Memento';
  }

  /// 获取状态显示文本
  String _getStatusText(TimerStatus status) {
    switch (status) {
      case TimerStatus.running:
        return '运行中';
      case TimerStatus.paused:
        return '已暂停';
      case TimerStatus.completed:
        return '已完成';
      case TimerStatus.stopped:
        return '已停止';
    }
  }

  // ========== 清理 ==========

  /// 释放资源
  void dispose() {
    _globalUpdateTimer?.cancel();
    _globalUpdateTimer = null;
    _timers.clear();
    _instance = null;
    _initialized = false;
    print('UnifiedTimerController disposed');
  }
}

/// 全局实例
final unifiedTimerController = UnifiedTimerController();
