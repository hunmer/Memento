import 'package:get/get.dart';
import 'dart:async';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/services/timer/events/timer_events.dart';
import 'package:Memento/plugins/tracker/utils/tracker_notification_utils.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/services/timer/unified_timer_controller.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/models/record.dart';
import 'package:Memento/plugins/tracker/controllers/tracker_controller.dart';

class TimerDialog extends StatefulWidget {
  final Goal goal;
  final TrackerController controller;

  const TimerDialog({super.key, required this.goal, required this.controller});

  @override
  State<TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<TimerDialog> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _notificationInitialized = false;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _valueController = TextEditingController(
    text: '1',
  );

  @override
  void initState() {
    super.initState();
    // 在计时器对话框打开时初始化通知系统
    _initializeNotification();

    // 订阅统一计时器事件
    _subscribeToTimerEvents();
  }

  Future<void> _initializeNotification() async {
    if (!_notificationInitialized) {
      await TrackerNotificationUtils.initialize();
      _notificationInitialized = true;
    }
  }

  /// 订阅统一计时器事件
  void _subscribeToTimerEvents() {
    EventManager.instance.subscribe('unified_timer_updated', (args) {
      if (args is UnifiedTimerEventArgs) {
        final state = args.timerState as TimerState;
        if (state.id == widget.goal.id) {
          setState(() {
            _seconds = state.elapsed.inSeconds;
            _isRunning = state.status == TimerStatus.running;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _startTimer();
      } else {
        _pauseTimer();
      }
    });
  }

  /// 启动计时器（委托给统一控制器）
  void _startTimer() {
    unifiedTimerController.startTimer(
      id: widget.goal.id,
      name: widget.goal.name,
      type: TimerType.countUp,
      color: Colors.orange,
      icon: Icons.track_changes,
      pluginId: 'tracker',
    );
  }

  /// 暂停计时器（委托给统一控制器）
  void _pauseTimer() {
    unifiedTimerController.pauseTimer(widget.goal.id);
  }

  /// 重置计时器（委托给统一控制器）
  void _resetTimer() {
    unifiedTimerController.stopTimer(widget.goal.id);

    setState(() {
      _seconds = 0;
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveRecord() async {
    if (_seconds > 0) {
      // 获取用户输入的记录值
      final recordValue = double.tryParse(_valueController.text) ?? 1;

      final record = Record(
        id: const Uuid().v4(),
        goalId: widget.goal.id,
        value: recordValue,
        note: _noteController.text,
        recordedAt: DateTime.now(),
        durationSeconds: _seconds,
      );

      final newGoal = widget.goal.copyWith(
        currentValue: widget.goal.currentValue + recordValue,
      );

      await widget.controller.updateGoal(widget.goal.id, newGoal);
      await widget.controller.addRecord(record, newGoal);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${'tracker_timer'.tr} - ${widget.goal.name}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(_seconds),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                onPressed: _toggleTimer,
              ),
              IconButton(icon: const Icon(Icons.stop), onPressed: _resetTimer),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: 'tracker_recordValueWithUnit'.tr
                  .replaceFirst('\${unit}', widget.goal.unitType),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText:
                  '${'tracker_note'.tr} (${'tracker_noteHint'.tr})',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('app_cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _seconds > 0 ? _saveRecord : null,
          child: Text('app_save'.tr),
        ),
      ],
    );
  }
}
