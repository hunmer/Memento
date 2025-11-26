import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/widgets/timer_dialog.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;
  final Skill? skill;
  final HabitController controller;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.habit,
    this.skill,
    required this.controller,
    this.onTap,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  late Color _themeColor;
  int _completionCount = 0;
  int _todayCount = 0;
  int _totalDurationMinutes = 0;
  List<bool> _last7DaysStatus = List.filled(7, false);
  bool _isTiming = false;
  String _timerText = "00:00";
  late TimerController _timerController;

  @override
  void initState() {
    super.initState();
    _themeColor = _getColor(widget.habit.skillId ?? widget.habit.id);

    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    _timerController = habitsPlugin?.timerController ?? TimerController();

    _loadStats();
    _checkTimerStatus();

    EventManager.instance.subscribe(
      'habit_timer_started',
      _onTimerStateChanged,
    );
    EventManager.instance.subscribe(
      'habit_timer_stopped',
      _onTimerStateChanged,
    );
  }

  @override
  void dispose() {
    EventManager.instance.unsubscribe(
      'habit_timer_started',
      _onTimerStateChanged,
    );
    EventManager.instance.unsubscribe(
      'habit_timer_stopped',
      _onTimerStateChanged,
    );
    super.dispose();
  }

  void _onTimerStateChanged(EventArgs args) {
    if (args is HabitTimerEventArgs && args.habitId == widget.habit.id) {
      if (mounted) {
        setState(() {
          _isTiming = args.isRunning;
          if (!_isTiming) {
            _loadStats(); // Reload stats when timer stops (habit completed?)
          }
        });
        _checkTimerStatus(); // Refresh timer text
      }
    }
  }

  void _checkTimerStatus() {
    final isTiming = _timerController.isHabitTiming(widget.habit.id);
    final timerData = _timerController.getTimerData(widget.habit.id);

    if (mounted) {
      setState(() {
        _isTiming = isTiming;
        if (timerData != null) {
          _timerText = _formatDuration(timerData['elapsedSeconds'] ?? 0);
        }
      });
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    if (habitsPlugin == null) return;

    final recordController = habitsPlugin.getRecordController();

    try {
      final count = await recordController.getCompletionCount(widget.habit.id);
      final duration = await recordController.getTotalDuration(widget.habit.id);

      // Get last 7 days records
      // This is a bit heavier, ideally optimize this query
      final records = await recordController.getHabitCompletionRecords(
        widget.habit.id,
      );
      final now = DateTime.now();
      final last7Days = List.generate(7, (index) {
        return now.subtract(Duration(days: 6 - index));
      });

      final status =
          last7Days
              .map((date) {
                return records.any(
                  (r) =>
                      r.date.year == date.year &&
                      r.date.month == date.month &&
                      r.date.day == date.day,
                );
              })
              .cast<bool>()
              .toList();

      final today = DateTime.now();
      final todayRecords = records.where(
        (r) =>
            r.date.year == today.year &&
            r.date.month == today.month &&
            r.date.day == today.day,
      );

      if (mounted) {
        setState(() {
          _completionCount = count;
          _todayCount = todayRecords.length;
          _totalDurationMinutes = duration;
          _last7DaysStatus = status;
        });
      }
    } catch (e) {
      debugPrint('Error loading habit stats: $e');
    }
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

  String _formatTotalDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _themeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.habit.icon != null
                        ? IconData(
                          int.parse(widget.habit.icon!),
                          fontFamily: 'MaterialIcons',
                        )
                        : (widget.skill?.icon != null
                            ? IconData(
                              int.parse(widget.skill!.icon!),
                              fontFamily: 'MaterialIcons',
                            )
                            : Icons.auto_awesome),
                    color: _themeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.skill?.title ?? 'Uncategorized',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Heatmap
            SizedBox(
              height:
                  24, // Give it a fixed height to avoid layout issues in Stack
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children:
                        _last7DaysStatus.asMap().entries.map((entry) {
                          final index = entry.key;
                          final isActive = entry.value;
                          // Calculate date for this slot (Same logic as in _loadStats)
                          // last7Days is [Today-6, Today-5, ..., Today]
                          final date = DateTime.now().subtract(
                            Duration(days: 6 - index),
                          );

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              height: 20,
                              decoration: BoxDecoration(
                                color:
                                    isActive
                                        ? _themeColor
                                        : (isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.1,
                                            )
                                            : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isActive
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white30
                                                : Colors.grey[400]),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  if (_todayCount > 0)
                    Positioned(
                      right: -4,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _themeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$_todayCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    _formatTotalDuration(_totalDurationMinutes),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '/ $_completionCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: Material(
                color:
                    _isTiming
                        ? _themeColor
                        : _themeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () {
                    // Start/Stop Logic
                    // This requires calling back to parent or using controller
                    // We'll use the controller passed in
                    // But we need context to show dialog if not timing

                    // If timing, stop (or pause)
                    // If not timing, start (show dialog?)
                    _handleTimerAction();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child:
                        _isTiming
                            ? Text(
                              _timerText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                            : Icon(
                              Icons.play_arrow,
                              color: _themeColor,
                              size: 24,
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTimerAction() async {
    if (_isTiming) {
      _timerController.stopTimer(widget.habit.id);
    } else {
      // Use the start timer logic from the parent or replicate it here.
      // Since we need context for dialogs, and the logic is slightly complex,
      // it's better to expose a callback or replicate the logic.
      // I'll replicate the minimal logic or use a callback property if I added one.
      // For now, I'll assume I can call the start logic directly if I had access to _startTimer from view.
      // Or I can implement a simple start here.

      // Ideally, we emit an event or call a passed callback.
      // But to keep it simple within this refactor:
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => _TimerDialogWrapper(
              habit: widget.habit,
              controller: widget.controller,
              timerController: _timerController,
            ),
      );

      if (result == true) {
        // Timer stopped via dialog
        _timerController.stopTimer(widget.habit.id);
      }
    }
  }
}

// Simple wrapper to avoid circular imports or duplication if TimerDialog is complex
// But TimerDialog is imported in habits_view.dart.
// I need to import TimerDialog here.

class _TimerDialogWrapper extends StatelessWidget {
  final Habit habit;
  final HabitController controller;
  final TimerController timerController;

  const _TimerDialogWrapper({
    required this.habit,
    required this.controller,
    required this.timerController,
  });

  @override
  Widget build(BuildContext context) {
    final timerData = timerController.getTimerData(habit.id);
    return TimerDialog(
      habit: habit,
      controller: controller,
      initialTimerData: timerData,
    );
  }
}
