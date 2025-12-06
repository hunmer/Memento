/// 统一计时器状态数据模型
///
/// 这个类定义了所有计时器的统一状态格式，支持：
/// - 基础计时功能（启动、暂停、停止）
/// - 多阶段计时器序列
/// - 倒计时/正计时模式
/// - 番茄钟计时器
/// - JSON 序列化/反序列化
library;

import 'package:flutter/material.dart';

/// 计时器类型
enum TimerType {
  /// 正计时：从0开始向上计时
  countUp,

  /// 倒计时：从目标时间向下计时
  countDown,

  /// 番茄钟：工作/休息交替循环
  pomodoro,
}

/// 计时器状态
enum TimerStatus {
  /// 已停止
  stopped,

  /// 运行中
  running,

  /// 已暂停
  paused,

  /// 已完成
  completed,
}

/// 计时器阶段配置
class TimerItemConfig {
  /// 阶段名称
  final String name;

  /// 阶段时长
  final Duration duration;

  /// 阶段颜色（可选）
  final Color? color;

  /// 图标（可选）
  final IconData? icon;

  TimerItemConfig({
    required this.name,
    required this.duration,
    this.color,
    this.icon,
  });

  /// 从 JSON 构造
  factory TimerItemConfig.fromJson(Map<String, dynamic> json) {
    return TimerItemConfig(
      name: json['name'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      color: json['color'] != null ? Color(json['color'] as int) : null,
      icon: json['icon'] != null
          ? IconData(json['icon'] as int, fontFamily: 'MaterialIcons')
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'duration': duration.inMilliseconds,
      'color': color?.value,
      'icon': icon?.codePoint,
    };
  }
}

/// 统一计时器状态
class TimerState {
  /// 计时器唯一ID
  final String id;

  /// 计时器名称
  final String name;

  /// 计时器类型
  final TimerType type;

  /// 计时器状态
  TimerStatus status;

  /// 已用时长
  Duration elapsed;

  /// 目标时长（倒计时需要）
  Duration? targetDuration;

  /// 是否倒计时模式
  final bool isCountdown;

  /// 主题色
  final Color color;

  /// 图标
  final IconData icon;

  /// 多阶段配置（可选）
  final List<TimerItemConfig> stages;

  /// 插件ID（timer/todo/tracker/habits）
  final String pluginId;

  /// 当前阶段索引
  int _currentStageIndex = 0;

  /// 当前阶段已用时长
  Duration _stageElapsed = Duration.zero;

  /// 开始时间（用于计算实际经过时间）
  DateTime? _startTime;

  /// 构造函数
  TimerState({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.elapsed,
    this.targetDuration,
    required this.isCountdown,
    required this.color,
    required this.icon,
    this.stages = const [],
    this.pluginId = 'timer',
  }) {
    // 初始化当前阶段
    if (stages.isNotEmpty) {
      _currentStageIndex = 0;
      _stageElapsed = Duration.zero;
    }
  }

  /// 获取当前阶段配置
  TimerItemConfig? get currentStage {
    if (stages.isEmpty || _currentStageIndex >= stages.length) {
      return null;
    }
    return stages[_currentStageIndex];
  }

  /// 获取当前阶段显示文本
  String getCurrentStageDisplay() {
    if (stages.isEmpty) {
      return isCountdown
          ? '${_formatDuration(targetDuration ?? elapsed)} / ${_formatDuration(targetDuration ?? Duration.zero)}'
          : _formatDuration(elapsed);
    }

    if (_currentStageIndex < stages.length) {
      final stage = stages[_currentStageIndex];
      return '${stage.name}: ${_formatDuration(_stageElapsed)}/${_formatDuration(stage.duration)}';
    }
    return '已完成';
  }

  /// 获取进度百分比（0-100）
  int getProgress() {
    if (stages.isNotEmpty) {
      // 多阶段计时器：计算当前阶段的进度
      final stage = currentStage;
      if (stage != null && stage.duration.inMilliseconds > 0) {
        return (_stageElapsed.inMilliseconds / stage.duration.inMilliseconds * 100)
            .clamp(0, 100)
            .toInt();
      }
      return 100;
    }

    // 单阶段计时器
    if (targetDuration != null && targetDuration!.inMilliseconds > 0) {
      final progress = elapsed.inMilliseconds / targetDuration!.inMilliseconds * 100;
      return progress.clamp(0, 100).toInt();
    }

    // 正计时无上限
    return 0;
  }

  /// 获取最大进度值
  int getMaxProgress() {
    if (stages.isNotEmpty) {
      final stage = currentStage;
      if (stage != null) {
        return stage.duration.inMilliseconds;
      }
      return 0;
    }

    return targetDuration?.inMilliseconds ?? 0;
  }

  /// 检查是否完成
  bool get isCompleted {
    if (stages.isNotEmpty) {
      return _currentStageIndex >= stages.length;
    }

    if (targetDuration != null) {
      return elapsed >= targetDuration!;
    }

    return false;
  }

  /// 更新计时器状态（在每秒tick时调用）
  void tick() {
    if (status != TimerStatus.running) return;

    final now = DateTime.now();

    if (_startTime == null) {
      _startTime = now;
      return;
    }

    final delta = now.difference(_startTime!);
    _startTime = now;

    if (stages.isNotEmpty) {
      _updateMultiStage(delta);
    } else {
      _updateSingleStage(delta);
    }
  }

  /// 更新多阶段计时器
  void _updateMultiStage(Duration delta) {
    if (_currentStageIndex >= stages.length) {
      // 所有阶段已完成
      status = TimerStatus.completed;
      return;
    }

    _stageElapsed += delta;

    // 检查当前阶段是否完成
    final currentStage = stages[_currentStageIndex];
    if (_stageElapsed >= currentStage.duration) {
      _currentStageIndex++;
      _stageElapsed = Duration.zero;

      // 检查是否所有阶段完成
      if (_currentStageIndex >= stages.length) {
        status = TimerStatus.completed;
        elapsed = stages.fold(Duration.zero, (sum, stage) => sum + stage.duration);
      }
    }
  }

  /// 更新单阶段计时器
  void _updateSingleStage(Duration delta) {
    elapsed += delta;

    if (targetDuration != null && elapsed >= targetDuration!) {
      elapsed = targetDuration!;
      status = TimerStatus.completed;
    }
  }

  /// 启动计时器
  void start() {
    status = TimerStatus.running;
    _startTime = DateTime.now();
  }

  /// 暂停计时器
  void pause() {
    status = TimerStatus.paused;
    _startTime = null;
  }

  /// 停止计时器
  void stop() {
    status = TimerStatus.stopped;
    _startTime = null;
  }

  /// 重置计时器
  void reset() {
    status = TimerStatus.stopped;
    elapsed = Duration.zero;
    _stageElapsed = Duration.zero;
    _currentStageIndex = 0;
    _startTime = null;
  }

  /// 格式化时长显示
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 从 JSON 构造
  factory TimerState.fromJson(Map<String, dynamic> json) {
    return TimerState(
      id: json['id'] as String,
      name: json['name'] as String,
      type: TimerType.values[json['type'] as int],
      status: TimerStatus.values[json['status'] as int],
      elapsed: Duration(milliseconds: json['elapsed'] as int),
      targetDuration: json['targetDuration'] != null
          ? Duration(milliseconds: json['targetDuration'] as int)
          : null,
      isCountdown: json['isCountdown'] as bool,
      color: Color(json['color'] as int),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      stages: json['stages'] != null
          ? (json['stages'] as List)
              .map((stage) => TimerItemConfig.fromJson(stage))
              .toList()
          : [],
      pluginId: json['pluginId'] as String? ?? 'timer',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'status': status.index,
      'elapsed': elapsed.inMilliseconds,
      'targetDuration': targetDuration?.inMilliseconds,
      'isCountdown': isCountdown,
      'color': color.value,
      'icon': icon.codePoint,
      'stages': stages.map((stage) => stage.toJson()).toList(),
      'pluginId': pluginId,
    };
  }

  /// 复制并修改
  TimerState copyWith({
    String? id,
    String? name,
    TimerType? type,
    TimerStatus? status,
    Duration? elapsed,
    Duration? targetDuration,
    bool? isCountdown,
    Color? color,
    IconData? icon,
    List<TimerItemConfig>? stages,
    String? pluginId,
  }) {
    return TimerState(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      targetDuration: targetDuration ?? this.targetDuration,
      isCountdown: isCountdown ?? this.isCountdown,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      stages: stages ?? this.stages,
      pluginId: pluginId ?? this.pluginId,
    );
  }

  @override
  String toString() {
    return 'TimerState(id: $id, name: $name, type: $type, status: $status, elapsed: $elapsed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerState && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
