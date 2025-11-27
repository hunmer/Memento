import 'dart:async';

import 'package:Memento/core/plugin_manager.dart';
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
  late Color _themeColor;

  // ignore: prefer_typing_uninitialized_variables
  var _timer;

  @override
  void initState() {
    super.initState();
    _themeColor = _getColor(widget.habit.skillId ?? widget.habit.id);
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

  Color _getColor(String id) {
    final colors = [
      const Color(0xFF607AFB), // Read (Blue)
      const Color(0xFFFF6B6B), // Workout (Red)
      const Color(0xFF4ECDC4), // Water (Teal)
      const Color(0xFF9D81E8), // Sleep (Purple)
      const Color(0xFFFFD93D), // Yellow
      const Color(0xFFFF8D29), // Orange
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1323) : const Color(0xFFF5F6F8);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Close Button (Top Right)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: subTextColor),
                  onPressed: () => _completeTimer(context), // Save and close
                ),
              ),

              // Habit Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  widget.habit.icon != null
                      ? IconData(
                          int.parse(widget.habit.icon!),
                          fontFamily: 'MaterialIcons',
                        )
                      : Icons.auto_stories, // Fallback
                  color: _themeColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              // Habit Title
              Text(
                widget.habit.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Timer Display
              GestureDetector(
                onTap: _toggleTimerMode,
                child: Text(
                  _formatDuration(
                      _isCountdown ? _duration - _elapsed : _elapsed),
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pause/Play Button
                  SizedBox(
                    height: 64,
                    width: 160,
                    child: ElevatedButton(
                      onPressed: _toggleTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isRunning ? 'Pause' : 'Start',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Restart Button
                  SizedBox(
                    height: 64,
                    width: 64,
                    child: ElevatedButton(
                      onPressed: _resetTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[200],
                        foregroundColor: subTextColor,
                        elevation: 0,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.refresh, size: 32),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Quick Notes Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: subTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, size: 20, color: subTextColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Add a quick note...',
                          hintStyle: TextStyle(color: subTextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        style: TextStyle(color: textColor),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            ?.getRecordController();
    await recordController.saveCompletionRecord(widget.habit.id, record);

    Navigator.pop(context, true);
  }
}
