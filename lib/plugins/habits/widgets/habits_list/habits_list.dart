import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:Memento/plugins/habits/widgets/habit_form.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habits_history_list.dart';
import 'package:Memento/plugins/habits/widgets/timer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habits_app_bar.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habits_card_view.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habits_list_view.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habits_list_view.dart';

class HabitsList extends StatefulWidget {
  final HabitController controller;

  const HabitsList({super.key, required this.controller});

  @override
  State<HabitsList> createState() => _HabitsListState();
}

class _HabitsListState extends State<HabitsList> {
  List<Habit> _habits = [];
  String? _selectedGroup;
  bool _isCardView = false;
  late TimerController _timerController;

  @override
  void initState() {
    super.initState();
    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    _timerController = habitsPlugin?.timerController ?? TimerController();
    widget.controller.addTimerModeListener(_onTimerModeChanged);
    _loadHabits();
  }

  void _onTimerModeChanged(String habitId, bool isCountdown) {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadHabits() async {
    final habits = await widget.controller.getHabits();
    if (mounted) {
      setState(() => _habits = habits);
    }
  }

  Future<void> _showHistory(BuildContext context, Habit habit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => HabitsHistoryList(
              habitId: habit.id,
              controller:
                  (PluginManager.instance.getPlugin('habits') as HabitsPlugin?)
                      ?.getRecordController() ??
                  CompletionRecordController(widget.controller.storage),
            ),
      ),
    );
  }

  Future<void> _startTimer(BuildContext context, Habit habit) async {
    final timerData = _timerController.getTimerData(habit.id);
    final isTiming = timerData != null;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => TimerDialog(
            habit: habit,
            controller: widget.controller,

            initialTimerData: timerData,
          ),
    );

    if (result != null) {
      _timerController.stopTimer(habit.id);
    }
  }

  Future<void> _showHabitForm(BuildContext context, [Habit? habit]) async {
    final l10n = HabitsLocalizations.of(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(habit == null ? l10n.createHabit : l10n.editHabit),
                actions: [
                  if (habit != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await widget.controller.deleteHabit(habit.id);
                        Navigator.pop(context);
                        _loadHabits();
                      },
                    ),
                ],
              ),
              body: HabitForm(
                initialHabit: habit,
                onSave: (habit) async {
                  await widget.controller.saveHabit(habit);
                  Navigator.pop(context);
                  _loadHabits();
                },
              ),
            ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeTimerModeListener(_onTimerModeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);
    final groups = HabitsUtils.getGroups(_habits, []);
    final filteredHabits =
        _selectedGroup == null
            ? _habits
            : _habits.where((h) => h.group == _selectedGroup).toList();

    return Column(
      children: [
        HabitsAppBar(
          l10n: l10n,
          groups: groups,
          selectedGroup: _selectedGroup,
          isCardView: _isCardView,
          onGroupChanged: (group) => setState(() => _selectedGroup = group),
          onViewChanged: () => setState(() => _isCardView = !_isCardView),
          onAddPressed: () => _showHabitForm(context),
          onBackPressed: () => PluginManager.toHomeScreen(context),
        ),
        Expanded(
          child:
              _isCardView
                  ? HabitsCardView(
                    habits: filteredHabits,
                    l10n: l10n,
                    onHabitPressed: (habit) => _showHabitForm(context, habit),
                    onTimerPressed: (habit) => _startTimer(context, habit),
                  )
                  : HabitsListView(
                    habits: filteredHabits,
                    l10n: l10n,
                    onHabitPressed: (habit) => _showHabitForm(context, habit),
                    onTimerPressed: (habit) => _startTimer(context, habit),
                    onHistoryPressed: (habit) => _showHistory(context, habit),
                  ),
        ),
      ],
    );
  }
}
