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

class _HabitsHomeState extends State<HabitsHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.habits),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: l10n.habits), Tab(text: l10n.skills)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HabitsList(controller: widget.habitController),
          SkillsList(
            skillController: widget.skillController,
            recordController: widget.recordController,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
