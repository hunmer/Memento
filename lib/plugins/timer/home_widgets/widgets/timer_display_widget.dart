/// 实时计时显示小组件
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/event/event_manager.dart';
import '../../models/timer_task.dart';
import '../../models/timer_item.dart';
import '../../timer_plugin.dart';
import '../utils.dart';

/// 实时计时显示小组件
class TimerDisplayWidget extends StatefulWidget {
  final String taskId;
  final Color taskColor;

  const TimerDisplayWidget({
    super.key,
    required this.taskId,
    required this.taskColor,
  });

  @override
  State<TimerDisplayWidget> createState() => TimerDisplayWidgetState();
}

class TimerDisplayWidgetState extends State<TimerDisplayWidget> {
  Duration _displayedDuration = Duration.zero;
  int _targetDuration = 0;
  int _type = 0; // 0: 正计时, 1: 倒计时, 2: 番茄钟

  TimerTask? _currentTask;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
    _subscribeToEvents();
  }

  @override
  void dispose() {
    _unsubscribeFromEvents();
    super.dispose();
  }

  void _loadTaskData() {
    try {
      final plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
      if (plugin == null) return;

      final tasks = plugin.getTasks();
      _currentTask = tasks.firstWhere((task) => task.id == widget.taskId);

      if (_currentTask!.timerItems.isNotEmpty) {
        final firstTimer = _currentTask!.timerItems.first;
        _type = firstTimer.type.index;
        _targetDuration = firstTimer.duration.inSeconds;
        _displayedDuration = firstTimer.completedDuration;
      }
    } catch (e) {
      // 任务不存在，不更新
    }
  }

  void _subscribeToEvents() {
    EventManager.instance.subscribe('timer_item_progress', _onTimerProgress);
    EventManager.instance.subscribe('timer_task_changed', _onTaskChanged);
  }

  void _unsubscribeFromEvents() {
    EventManager.instance.unsubscribe('timer_item_progress', _onTimerProgress);
    EventManager.instance.unsubscribe('timer_task_changed', _onTaskChanged);
  }

  void _onTaskChanged(EventArgs args) {
    if (args is TimerTaskEventArgs && args.task.id == widget.taskId) {
      _currentTask = args.task;
      if (args.task.timerItems.isNotEmpty) {
        final firstTimer = args.task.timerItems.first;
        _type = firstTimer.type.index;
        _targetDuration = firstTimer.duration.inSeconds;
        _displayedDuration = firstTimer.completedDuration;
      }
      if (mounted) setState(() {});
    }
  }

  void _onTimerProgress(EventArgs args) {
    if (args is TimerItemEventArgs) {
      // 检查是否是当前任务的计时器
      if (_currentTask != null) {
        final timerItems = _currentTask!.timerItems;
        if (timerItems.any((item) => item.id == args.timer.id)) {
          _displayedDuration = args.timer.completedDuration;
          if (mounted) setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String displayText;

    if (_type == 1) {
      // 倒计时
      final remaining = Duration(seconds: _targetDuration) - _displayedDuration;
      if (remaining.isNegative) {
        displayText = '-${formatDuration(remaining.abs())}';
      } else {
        displayText = formatDuration(remaining);
      }
    } else {
      // 正计时和番茄钟
      displayText = formatDuration(_displayedDuration);
    }

    return Text(
      displayText,
      style: theme.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: widget.taskColor,
        fontFamily: 'monospace',
      ),
    );
  }
}
