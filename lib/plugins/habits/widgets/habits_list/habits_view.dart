import 'dart:io';

import 'package:Memento/core/event/event_manager.dart';
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
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/utils/image_utils.dart';

class CombinedHabitsView extends StatefulWidget {
  final HabitController controller;

  const CombinedHabitsView({super.key, required this.controller});

  @override
  State<CombinedHabitsView> createState() => _CombinedHabitsViewState();
}

class _CombinedHabitsViewState extends State<CombinedHabitsView> {
  List<Habit> _habits = [];
  String? _selectedGroup;
  bool _isCardView = false;
  late TimerController _timerController;
  final Map<String, bool> _timingStatus = {};

  @override
  void initState() {
    super.initState();
    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    _timerController = habitsPlugin?.timerController ?? TimerController();
    widget.controller.addTimerModeListener(_onTimerModeChanged);
    final activeTimers = habitsPlugin!.timerController.getActiveTimers();
    _timingStatus.addAll(activeTimers);
    EventManager.instance.subscribe('habit_timer_started', _onTimerStarted);
    EventManager.instance.subscribe('habit_timer_stopped', _onTimerStopped);
    _loadHabits();
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
                      ?.getRecordController(),
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

  Widget _buildCardView(List<Habit> habits, HabitsLocalizations l10n) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
      ),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final isTiming =
            _timingStatus[habit.id] ?? _timerController.isHabitTiming(habit.id);
        _timingStatus[habit.id] = isTiming;

        return Card(
          child: InkWell(
            onTap: () => _showHabitForm(context, habit),
            child: Column(
              children: [
                Expanded(
                  child:
                      habit.image != null && habit.image!.isNotEmpty
                          ? FutureBuilder<String>(
                            future:
                                habit.image!.startsWith('http')
                                    ? Future.value(habit.image!)
                                    : ImageUtils.getAbsolutePath(habit.image!),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image:
                                          habit.image!.startsWith('http')
                                              ? NetworkImage(snapshot.data!)
                                              : FileImage(File(snapshot.data!))
                                                  as ImageProvider,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.3),
                                        BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          habit.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${habit.durationMinutes} ${l10n.minutes}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image),
                                );
                              } else {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            },
                          )
                          : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.auto_awesome, size: 48),
                          ),
                ),
                IconButton(
                  icon: Icon(isTiming ? Icons.pause : Icons.play_arrow),
                  onPressed: () => _startTimer(context, habit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Habit> habits, HabitsLocalizations l10n) {
    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final isTiming =
            _timingStatus[habit.id] ?? _timerController.isHabitTiming(habit.id);
        _timingStatus[habit.id] = isTiming;

        return ListTile(
          leading:
              habit.image != null && habit.image!.isNotEmpty
                  ? FutureBuilder<String>(
                    future:
                        habit.image!.startsWith('http')
                            ? Future.value(habit.image!)
                            : ImageUtils.getAbsolutePath(habit.image!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return CircleAvatar(
                          backgroundImage:
                              habit.image!.startsWith('http')
                                  ? NetworkImage(snapshot.data!)
                                  : FileImage(File(snapshot.data!))
                                      as ImageProvider,
                        );
                      }
                      return const CircleAvatar(
                        child: Icon(Icons.auto_awesome),
                      );
                    },
                  )
                  : const CircleAvatar(child: Icon(Icons.auto_awesome)),
          title: Text(habit.title),
          subtitle: Text('${habit.durationMinutes} ${l10n.minutes}'),
          trailing: IconButton(
            icon: Icon(isTiming ? Icons.pause : Icons.play_arrow),
            onPressed: () => _startTimer(context, habit),
          ),
          onTap: () => _showHabitForm(context, habit),
          onLongPress: () => _showHistory(context, habit),
        );
      },
    );
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
                  ? _buildCardView(filteredHabits, l10n)
                  : _buildListView(filteredHabits, l10n),
        ),
      ],
    );
  }
}
