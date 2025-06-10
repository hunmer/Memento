import 'package:Memento/core/event/event_args.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/habit.dart';

class HabitsListView extends StatefulWidget {
  final List<Habit> habits;
  final HabitsLocalizations l10n;
  final Function(Habit) onHabitPressed;
  final Function(Habit) onTimerPressed;
  final Function(Habit) onHistoryPressed;

  const HabitsListView({
    super.key,
    required this.habits,
    required this.l10n,
    required this.onHabitPressed,
    required this.onTimerPressed,
    required this.onHistoryPressed,
  });

  @override
  _HabitsListViewState createState() => _HabitsListViewState();
}

class _HabitsListViewState extends State<HabitsListView> {
  final Map<String, bool> _timingStatus = {};
  final habitsPlugin =
      PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
  @override
  void initState() {
    super.initState();
    // 初始化时从TimerController获取所有正在计时的习惯状态
    final activeTimers = habitsPlugin!.timerController.getActiveTimers();
    _timingStatus.addAll(activeTimers);
    EventManager.instance.subscribe('habit_timer_started', _onTimerStarted);
    EventManager.instance.subscribe('habit_timer_stopped', _onTimerStopped);
  }

  @override
  void dispose() {
    EventManager.instance.unsubscribe('habit_timer_started', _onTimerStarted);
    EventManager.instance.unsubscribe('habit_timer_stopped', _onTimerStopped);
    super.dispose();
  }

  void _onTimerStarted(EventArgs args) {
    if (args is HabitTimerEventArgs) {
      setState(() {
        _timingStatus[args.habitId] = args.isRunning;
      });
    }
  }

  void _onTimerStopped(EventArgs args) {
    if (args is HabitTimerEventArgs) {
      setState(() {
        _timingStatus[args.habitId] = args.isRunning;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.habits.length,
      itemBuilder: (context, index) {
        final habit = widget.habits[index];
        final isTiming =
            _timingStatus[habit.id] ??
            (habitsPlugin?.timerController.isHabitTiming(habit.id) ?? false);
        _timingStatus[habit.id] = isTiming;

        return ListTile(
          leading:
              habit.icon != null
                  ? Icon(
                    IconData(
                      int.parse(habit.icon!),
                      fontFamily: 'MaterialIcons',
                    ),
                  )
                  : null,
          title: Text(habit.title),
          subtitle: Text('${habit.durationMinutes} ${widget.l10n.minutes}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => widget.onHistoryPressed(habit),
              ),
              IconButton(
                icon: Icon(isTiming ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  widget.onTimerPressed(habit);
                },
              ),
            ],
          ),
          onTap: () => widget.onHabitPressed(habit),
        );
      },
    );
  }
}
