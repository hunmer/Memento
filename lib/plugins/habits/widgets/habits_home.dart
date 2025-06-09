import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/widgets/habits_list.dart';
import 'package:Memento/plugins/habits/widgets/skills_list.dart';

class HabitsHome extends StatefulWidget {
  final HabitController habitController;
  final SkillController skillController;
  final CompletionRecordController recordController;

  const HabitsHome({
    super.key,
    required this.habitController,
    required this.skillController,
    required this.recordController,
  });

  @override
  State<HabitsHome> createState() => _HabitsHomeState();
}

class _HabitsHomeState extends State<HabitsHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HabitsList(controller: widget.habitController),
      SkillsList(
        skillController: widget.skillController,
        recordController: widget.recordController,
      ),
    ];
    final l10n = HabitsLocalizations.of(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: l10n.habits,
          ),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: l10n.skills),
        ],
      ),
    );
  }
}
