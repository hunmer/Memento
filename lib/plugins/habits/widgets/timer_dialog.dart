import 'dart:async';

import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';

class TimerDialog extends StatefulWidget {
  final Habit habit;
  final HabitController controller;
  final Map<String, dynamic>? initialTimerData;

  const TimerDialog({
    super.key,
    required this.habit,
    required this.controller,
    this.initialTimerData,
  });

  @override
  State<TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<TimerDialog> {
  bool _isCountdown = true;
  bool _isRunning = false;
  Duration _duration = const Duration(minutes: 25);
  Duration _elapsed = Duration.zero;
  final TextEditingController _notesController = TextEditingController();
  String _lastSavedNotes = '';

  var _timer;

  @override
  void initState() {
    super.initState();
    _duration = Duration(minutes: widget.habit.durationMinutes);

    if (widget.initialTimerData != null) {
      _isCountdown = widget.initialTimerData!['isCountdown'] ?? true;
      _elapsed = Duration(
        seconds: widget.initialTimerData!['elapsedSeconds'] ?? 0,
      );
      _notesController.text = widget.initialTimerData!['notes'] ?? '';
      // 不初始化_isRunning，因为会在_toggleTimer中初始化，此处仅用于判断是否需要启动计时器。
      if (widget.initialTimerData!['isRunning']) _toggleTimer();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.habit.title} Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer display
          Text(
            _formatDuration(_isCountdown ? _duration - _elapsed : _elapsed),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          // Timer controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                onPressed: _toggleTimer,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetTimer,
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: _toggleTimerMode,
                tooltip:
                    'Switch to ${_isCountdown ? 'Stopwatch' : 'Countdown'}',
              ),
            ],
          ),
          // Notes field
          TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context, false),
        ),
        TextButton(
          child: const Text('Complete'),
          onPressed: () => _completeTimer(context),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours > 0 ? '${twoDigits(hours)}:' : ''}'
        '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _toggleTimer() {
    if (!mounted) return;
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        widget.controller.timerController.startTimer(widget.habit, (elapsed) {
          if (!mounted) return;
          setState(() {
            _elapsed = Duration(seconds: elapsed);
            if (_isCountdown && _elapsed >= _duration) {
              _isRunning = false;
              // TODO 完成提示
            }
          });
          // 只在笔记内容变更时更新
          if (_notesController.text != _lastSavedNotes) {
            _lastSavedNotes = _notesController.text;
            widget.controller.timerController.updateTimerData(widget.habit.id, {
              'notes': _notesController.text,
            });
          }
        }, initialDuration: _elapsed);
      } else {
        widget.controller.timerController.pauseTimer(widget.habit.id);
        widget.controller.timerController.updateTimerData(widget.habit.id, {
          'elapsedSeconds': _elapsed.inSeconds,
          'isRunning': false,
        });
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _elapsed = Duration.zero;
      _isRunning = false;
    });
    // 完全清除计时器状态，确保重新打开对话框时不会恢复
    widget.controller.timerController.stopTimer(widget.habit.id);
    widget.controller.timerController.clearTimerData(widget.habit.id);
  }

  void _toggleTimerMode() {
    if (_isCountdown && _elapsed >= _duration) return;
    setState(() {
      _isCountdown = !_isCountdown;
      widget.controller.timerController.setCountdownMode(
        widget.habit.id,
        _isCountdown,
      );
      widget.controller.notifyTimerModeChanged(widget.habit.id, _isCountdown);
    });
  }

  Future<void> _completeTimer(BuildContext context) async {
    _timer?.cancel();

    final record = CompletionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      parentId: widget.habit.id,
      date: DateTime.now(),
      duration: _elapsed,
      notes: _notesController.text,
    );

    final recordController =
        (PluginManager.instance.getPlugin('habits') as HabitsPlugin?)
            ?.getRecordController() ??
        CompletionRecordController(widget.controller.storage);
    await recordController.saveCompletionRecord(widget.habit.id, record);

    Navigator.pop(context, true);
  }
}
