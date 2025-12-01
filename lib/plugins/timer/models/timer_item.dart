import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:Memento/core/notification_controller.dart';
import '../../../../core/event/event_manager.dart';

class TimerItemEventArgs extends EventArgs {
  final TimerItem timer;
  TimerItemEventArgs(this.timer, [String eventName = 'timer_item_changed'])
    : super(eventName);
}

/// 计时器类型枚举
enum TimerType {
  /// 正计时 - 从0开始向上计时
  countUp,

  /// 倒计时 - 从设定时间开始向下计时
  countDown,

  /// 番茄钟 - 工作和休息交替的计时方式
  pomodoro,
}

/// 计时器项，表示一个具体的计时器
class TimerItem {
  final String id;
  final String name;
  late String? description; // 计时器描述
  final TimerType type;
  final Duration duration; // 设定的时长
  Duration completedDuration; // 已完成的时长
  bool isRunning;
  DateTime? startTime; // 开始计时的时间
  Timer? _timer;
  Function? onComplete; // 计时器完成时的回调
  Function? onIntervalAlert; // 间隔提示回调
  Function(Duration)? onUpdate; // 计时更新回调

  // 间隔提示设置
  final Duration? intervalAlertDuration; // 间隔提示时长，如每5分钟提示一次
  Duration? _lastAlertTime; // 上次提示的时间点

  // 番茄钟特有属性
  final Duration? workDuration; // 工作时长
  final Duration? breakDuration; // 休息时长
  final int? cycles; // 循环次数
  int? currentCycle; // 当前循环
  bool? isWorkPhase; // 是否处于工作阶段
  late int repeatCount; // 配置的重复次数
  int _currentRepeatCount; // 当前剩余的重复次数
  late bool enableNotification; // 是否启用消息提醒

  TimerItem({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.duration,
    this.completedDuration = Duration.zero,
    this.isRunning = false,
    this.startTime,
    this.workDuration,
    this.breakDuration,
    this.cycles,
    this.currentCycle,
    this.isWorkPhase,
    this.intervalAlertDuration,
    this.onIntervalAlert,
    this.repeatCount = 1,
    this.enableNotification = false, // 默认关闭消息提醒
  }) : _currentRepeatCount = repeatCount;

  // 从JSON构造
  factory TimerItem.fromJson(Map<String, dynamic> json) {
    return TimerItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: TimerType.values[json['type'] as int],
      duration: Duration(seconds: json['duration'] as int),
      completedDuration: Duration(seconds: json['completedDuration'] as int),
      isRunning: false, // 加载时总是非运行状态
      workDuration:
          json['workDuration'] != null
              ? Duration(seconds: json['workDuration'] as int)
              : null,
      breakDuration:
          json['breakDuration'] != null
              ? Duration(seconds: json['breakDuration'] as int)
              : null,
      cycles: json['cycles'] as int?,
      currentCycle: json['currentCycle'] as int?,
      isWorkPhase: json['isWorkPhase'] as bool?,
      repeatCount: json['repeatCount'] as int? ?? 1,
      intervalAlertDuration:
          json['intervalAlertDuration'] != null
              ? Duration(seconds: json['intervalAlertDuration'] as int)
              : null,
      enableNotification: json['enableNotification'] as bool? ?? false,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'duration': duration.inSeconds,
      'completedDuration': completedDuration.inSeconds,
      'workDuration': workDuration?.inSeconds,
      'breakDuration': breakDuration?.inSeconds,
      'cycles': cycles,
      'currentCycle': currentCycle,
      'isWorkPhase': isWorkPhase,
      'repeatCount': repeatCount, // 序列化时只保存配置值
      'intervalAlertDuration': intervalAlertDuration?.inSeconds,
      'enableNotification': enableNotification,
    };
  }

  // 创建正计时器
  factory TimerItem.countUp({
    required String name,
    String? description,
    Duration? targetDuration,
    Duration? intervalAlertDuration,
    bool enableNotification = false,
  }) {
    return TimerItem(
      id: const Uuid().v4(),
      name: name,
      description: description,
      type: TimerType.countUp,
      duration: targetDuration ?? const Duration(hours: 1), // 默认目标1小时
      completedDuration: Duration.zero,
      intervalAlertDuration: intervalAlertDuration,
      enableNotification: enableNotification,
    );
  }

  // 创建倒计时器
  factory TimerItem.countDown({
    required String name,
    String? description,
    required Duration duration,
    Duration? intervalAlertDuration,
    bool enableNotification = false,
  }) {
    return TimerItem(
      id: const Uuid().v4(),
      name: name,
      type: TimerType.countDown,
      duration: duration,
      completedDuration: Duration.zero,
      intervalAlertDuration: intervalAlertDuration,
      enableNotification: enableNotification,
    );
  }

  // 创建番茄钟
  factory TimerItem.pomodoro({
    required String name,
    String? description,
    Duration workDuration = const Duration(minutes: 25),
    Duration breakDuration = const Duration(minutes: 5),
    int cycles = 4,
    Duration? intervalAlertDuration,
    bool enableNotification = false,
  }) {
    // 计算总时长 = 工作时长 * 循环次数 + 休息时长 * (循环次数 - 1)
    final totalDuration = workDuration * cycles + breakDuration * (cycles - 1);

    return TimerItem(
      id: const Uuid().v4(),
      name: name,
      type: TimerType.pomodoro,
      duration: totalDuration,
      completedDuration: Duration.zero,
      workDuration: workDuration,
      breakDuration: breakDuration,
      cycles: cycles,
      currentCycle: 1,
      isWorkPhase: true,
      intervalAlertDuration: intervalAlertDuration,
    );
  }

  // 启动计时器
  void start() {
    if (isRunning) return;

    isRunning = true;
    startTime = DateTime.now();

    // 重置上次提示时间
    if (intervalAlertDuration != null) {
      _lastAlertTime = Duration.zero;
    }

    // 创建定时器，每秒更新一次
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    EventManager.instance.broadcast(
      'timer_item_changed',
      TimerItemEventArgs(this),
    );
  }

  // 暂停计时器
  void pause() {
    if (!isRunning) return;

    isRunning = false;
    startTime = null;
    _timer?.cancel();
    _timer = null;
    EventManager.instance.broadcast(
      'timer_item_changed',
      TimerItemEventArgs(this),
    );
  }

  // 重置计时器
  void reset() {
    pause();
    completedDuration = Duration.zero;
    _lastAlertTime = null;

    if (type == TimerType.pomodoro) {
      currentCycle = 1;
      isWorkPhase = true;
    }
    EventManager.instance.broadcast(
      'timer_item_changed',
      TimerItemEventArgs(this),
    );
  }

  void resetRepeatCount() {
    _currentRepeatCount = repeatCount;
  }

  // 检查是否还有剩余重复次数
  bool get hasRemainingRepeats => _currentRepeatCount > 1;

  // 减少重复次数并重置计时器
  void decrementRepeatCount() {
    if (hasRemainingRepeats) {
      _currentRepeatCount--;
      reset();
      // 通知父级任务更新
      onUpdate?.call(completedDuration);
    }
  }

  int getCurrentRepeatCount() {
    return _currentRepeatCount;
  }

  // 定时器回调
  void _onTick(Timer timer) {
    switch (type) {
      case TimerType.countUp:
        _handleCountUp();
        break;
      case TimerType.countDown:
        _handleCountDown();
        break;
      case TimerType.pomodoro:
        _handlePomodoro();
        break;
    }
    // 通知父级任务更新通知
    onUpdate?.call(completedDuration);
    // 广播计时器进度更新
    EventManager.instance.broadcast(
      'timer_item_progress',
      TimerItemEventArgs(this),
    );
  }

  // 处理正计时逻辑
  void _handleCountUp() {
    if (startTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(startTime!);
    completedDuration += elapsed;
    startTime = now;

    // 检查是否需要发出间隔提示
    _checkIntervalAlert();

    // 如果达到目标时间，停止计时
    if (duration.inSeconds > 0 && completedDuration >= duration) {
      completedDuration = duration;
      pause();
      // 检查是否有剩余重复次数
      if (hasRemainingRepeats) {
        decrementRepeatCount();
        start(); // 重新启动计时器
      } else {
        // 发送完成通知
        if (enableNotification) {
          NotificationController.createBasicNotification(
            id: DateTime.now().millisecondsSinceEpoch,
            title: '正时器完成',
            body: '正时器"$name"已完成',
          );
        }
        onComplete?.call();
      }
      // 强制UI更新
      onUpdate?.call(completedDuration);
    }
  }

  // 处理倒计时逻辑
  void _handleCountDown() {
    if (startTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(startTime!);
    completedDuration += elapsed;
    startTime = now;

    // 检查是否需要发出间隔提示
    _checkIntervalAlert();

    // 如果倒计时结束，停止计时
    if (completedDuration >= duration) {
      completedDuration = duration;
      pause();
      // 检查是否有剩余重复次数
      if (hasRemainingRepeats) {
        decrementRepeatCount();
        start(); // 重新启动计时器
      } else {
        if (enableNotification) {
          NotificationController.createBasicNotification(
            id: DateTime.now().millisecondsSinceEpoch,
            title: '倒计时器完成',
            body: '倒计时器"$name"已完成',
          );
        }
        onComplete?.call();
      }
    }
  }

  // 处理番茄钟逻辑
  void _handlePomodoro() {
    if (startTime == null ||
        workDuration == null ||
        breakDuration == null ||
        cycles == null ||
        currentCycle == null ||
        isWorkPhase == null) {
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(startTime!);
    completedDuration += elapsed;
    startTime = now;

    // 检查是否需要发出间隔提示
    _checkIntervalAlert();

    // 计算当前阶段的时长
    final currentPhaseDuration = isWorkPhase! ? workDuration! : breakDuration!;

    // 计算当前阶段已完成的时间
    Duration phaseCompleted = Duration.zero;
    int completedPhases = 0;

    if (currentCycle! > 1) {
      // 已完成的完整循环
      final fullCycles = currentCycle! - 1;
      completedPhases = fullCycles * 2 - (isWorkPhase! ? 0 : 1);
    }

    // 计算当前阶段已经过的时间
    if (completedPhases > 0) {
      // 已完成的工作阶段
      final completedWorkPhases = (completedPhases + 1) ~/ 2;
      // 已完成的休息阶段
      final completedBreakPhases = completedPhases ~/ 2;

      phaseCompleted =
          workDuration! * completedWorkPhases +
          breakDuration! * completedBreakPhases;
    }

    final currentPhaseElapsed = completedDuration - phaseCompleted;

    // 检查当前阶段是否已完成
    if (currentPhaseElapsed >= currentPhaseDuration) {
      // 切换阶段
      isWorkPhase = !isWorkPhase!;

      // 如果从休息切换到工作，增加循环计数
      if (isWorkPhase!) {
        currentCycle = currentCycle! + 1;
      }

      // 如果已完成所有循环，停止计时
      if (currentCycle! > cycles!) {
        pause();

        // 检查是否有剩余重复次数
        if (hasRemainingRepeats) {
          decrementRepeatCount();
          start(); // 重新启动计时器
        } else {
          if (enableNotification) {
            NotificationController.createBasicNotification(
              id: DateTime.now().millisecondsSinceEpoch,
              title: '番茄钟计时器完成',
              body: '番茄钟计时器"$name"已完成',
            );
          }
          onComplete?.call();
        }
        return;
      }
    }
  }

  // 检查是否需要发出间隔提示
  void _checkIntervalAlert() {
    if (intervalAlertDuration == null || onIntervalAlert == null) return;

    // 如果是第一次检查，初始化上次提示时间
    _lastAlertTime ??= Duration.zero;

    // 计算自上次提示以来经过的时间
    final timeFromLastAlert = completedDuration - _lastAlertTime!;

    // 如果经过的时间超过或等于间隔提示时长，触发提示
    if (timeFromLastAlert >= intervalAlertDuration!) {
      onIntervalAlert?.call();

      // 更新上次提示时间（向下取整到最近的间隔倍数）
      final intervals =
          completedDuration.inSeconds ~/ intervalAlertDuration!.inSeconds;
      _lastAlertTime = Duration(
        seconds: intervals * intervalAlertDuration!.inSeconds,
      );
    }
  }

  // 获取剩余时间
  Duration get remainingDuration {
    switch (type) {
      case TimerType.countUp:
        return duration - completedDuration;
      case TimerType.countDown:
        return duration - completedDuration;
      case TimerType.pomodoro:
        if (workDuration == null ||
            breakDuration == null ||
            cycles == null ||
            currentCycle == null ||
            isWorkPhase == null) {
          return Duration.zero;
        }

        // 计算总剩余时间
        final totalDuration =
            workDuration! * cycles! + breakDuration! * (cycles! - 1);
        return totalDuration - completedDuration;
    }
  }

  // 检查计时器是否已完成
  bool get isCompleted {
    switch (type) {
      case TimerType.countUp:
        return duration.inSeconds > 0 && completedDuration >= duration;
      case TimerType.countDown:
        return completedDuration >= duration;
      case TimerType.pomodoro:
        if (cycles == null || currentCycle == null) return false;
        return currentCycle! > cycles!;
    }
  }

  // 获取当前阶段（仅用于番茄钟）
  String get currentPhase {
    if (type != TimerType.pomodoro || isWorkPhase == null) return '';
    return isWorkPhase! ? '工作' : '休息';
  }

  // 获取格式化的剩余时间
  String get formattedRemainingTime {
    final remaining = remainingDuration;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
