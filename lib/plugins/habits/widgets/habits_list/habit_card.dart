import 'dart:async';
import 'package:Memento/core/event/event_args.dart';
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
  Timer? _uiUpdateTimer;
  late Habit _currentHabit; // 缓存当前习惯对象，用于获取最新的 totalDurationMinutes

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit;
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
    EventManager.instance.subscribe('habit_data_changed', _onHabitDataChanged);
  }

  @override
  void dispose() {
    _stopUIUpdateTimer();
    EventManager.instance.unsubscribe(
      'habit_timer_started',
      _onTimerStateChanged,
    );
    EventManager.instance.unsubscribe(
      'habit_timer_stopped',
      _onTimerStateChanged,
    );
    EventManager.instance.unsubscribe(
      'habit_data_changed',
      _onHabitDataChanged,
    );
    super.dispose();
  }

  void _onHabitDataChanged(EventArgs args) {
    if (args is Value) {
      final data = args.value;
      if (data is Map && data.containsKey('habit')) {
        final updatedHabit = data['habit'] as Habit;
        // 只更新当前习惯的数据
        if (updatedHabit.id == widget.habit.id && mounted) {
          setState(() {
            _currentHabit = updatedHabit;
          });
        }
      }
    }
  }

  void _onTimerStateChanged(EventArgs args) {
    if (args is HabitTimerEventArgs && args.habitId == widget.habit.id) {
      if (mounted) {
        setState(() {
          _isTiming = args.isRunning;
          // 更新计时器文本
          _timerText = _formatDuration(args.elapsedSeconds);

          if (!_isTiming) {
            // 停止UI更新定时器
            // 注意: 统计数据的加载由 _handleTimerAction 根据对话框返回值决定
            _stopUIUpdateTimer();
          } else {
            _startUIUpdateTimer(); // 启动UI更新定时器
          }
        });
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

    // 启动或停止实时更新定时器
    if (isTiming) {
      _startUIUpdateTimer();
    } else {
      _stopUIUpdateTimer();
    }
  }

  /// 启动UI更新定时器(每秒更新一次)
  void _startUIUpdateTimer() {
    _stopUIUpdateTimer();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final timerData = _timerController.getTimerData(widget.habit.id);
      if (timerData != null) {
        final elapsed = timerData['elapsedSeconds'] ?? 0;
        final newText = _formatDuration(elapsed);
        if (mounted) {
          setState(() {
            _timerText = newText;
          });
        }
      }
    });
  }

  /// 停止UI更新定时器
  void _stopUIUpdateTimer() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = null;
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  // 文本：累计时长(完成次数) / 目标时长 | 总累计时长
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_formatTotalDuration(_totalDurationMinutes)}($_completionCount)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      Text(
                        ' / ${widget.habit.durationMinutes}m',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                      if (_currentHabit.totalDurationMinutes > 0) ...[
                        Text(
                          ' | ',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                        ),
                        Text(
                          '总${_formatTotalDuration(_currentHabit.totalDurationMinutes)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value:
                          widget.habit.durationMinutes > 0
                              ? (_totalDurationMinutes /
                                      widget.habit.durationMinutes)
                                  .clamp(0.0, 1.0)
                              : 0.0,
                      backgroundColor:
                          isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
                      minHeight: 3,
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
    // 无论计时器是否运行,都显示对话框
    // 对话框内可以暂停、恢复或停止计时器
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
      // 计时已完成并保存记录，重新加载统计数据
      await _loadStats();
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
