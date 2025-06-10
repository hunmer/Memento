import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/habit.dart';

class HabitsListView extends StatelessWidget {
  final List<Habit> habits;
  final HabitsLocalizations l10n;
  final Function(Habit) onHabitPressed;
  final Function(Habit) onTimerPressed;

  const HabitsListView({
    super.key,
    required this.habits,
    required this.l10n,
    required this.onHabitPressed,
    required this.onTimerPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return ListTile(
          leading: habit.icon != null
              ? Icon(
                  IconData(
                    int.parse(habit.icon!),
                    fontFamily: 'MaterialIcons',
                  ),
                )
              : null,
          title: Text(habit.title),
          subtitle: Text('${habit.durationMinutes} ${l10n.minutes}'),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => onTimerPressed(habit),
          ),
          onTap: () => onHabitPressed(habit),
        );
      },
    );
  }
}
