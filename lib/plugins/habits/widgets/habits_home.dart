import 'package:Memento/plugins/habits/widgets/habits_list/habits_list.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/widgets/skills_list.dart';
import 'package:Memento/core/widgets/keep_alive_wrapper.dart';

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

class _HabitsHomeState extends State<HabitsHome>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // 禁止手动滑动切换
        children: [
          KeepAliveWrapper(
            child: HabitsList(controller: widget.habitController),
          ),
          KeepAliveWrapper(
            child: SkillsList(
              skillController: widget.skillController,
              recordController: widget.recordController,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.ease,
          );
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
