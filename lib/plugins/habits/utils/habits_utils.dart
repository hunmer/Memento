import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/models/skill.dart';

class HabitsUtils {
  static List<String> getGroups(List<Habit> habits, List<Skill> skills) {
    final groups = <String>{};

    for (final habit in habits) {
      if (habit.group != null && habit.group!.isNotEmpty) {
        groups.add(habit.group!);
      }
    }

    for (final skill in skills) {
      if (skill.group != null && skill.group!.isNotEmpty) {
        groups.add(skill.group!);
      }
    }

    return groups.toList()..sort();
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours h ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}'
          .trim();
    }
  }
}
