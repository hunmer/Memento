import 'dart:async';

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
  Timer? _timer;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _duration = Duration(minutes: widget.habit.durationMinutes);

    if (widget.initialTimerData != null) {
      _isCountdown = widget.initialTimerData!['isCountdown'] ?? true;
      _elapsed = Duration(
        seconds: widget.initialTimerData!['elapsedSeconds'] ?? 0,
      );
      _isRunning = widget.initialTimerData!['isRunning'] ?? false;
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
      widget.controller.timerController.toggleTimer(
        widget.habit.id,
        _isRunning,
      );
      if (_isRunning && _elapsed >= _duration) {
        _showTimerComplete();
      }
    });
  }

  void _showTimerComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Timer for ${widget.habit.title} completed'),
        duration: const Duration(seconds: 5),
      ),
    );
    if (_isCountdown) {
      setState(() => _isCountdown = false);
    }
  }

  void _resetTimer() {
    setState(() {
      _elapsed = Duration.zero;
      _isRunning = false;
    });
    widget.controller.timerController.stopTimer(widget.habit.id);
  }

  void _toggleTimerMode() {
    if (_isCountdown && _elapsed >= _duration) return;
    setState(() {
      _isCountdown = !_isCountdown;
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

    await widget.controller.saveCompletionRecord(widget.habit.id, record);

    Navigator.pop(context, true);
  }
}
