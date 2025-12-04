
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/widgets/habit_form.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habits_app_bar.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habit_card.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class CombinedHabitsView extends StatefulWidget {
  final HabitController controller;

  const CombinedHabitsView({super.key, required this.controller});

  @override
  State<CombinedHabitsView> createState() => _CombinedHabitsViewState();
}

class _CombinedHabitsViewState extends State<CombinedHabitsView>
    with WidgetsBindingObserver {
  List<Habit> _habits = [];
  final Map<String, bool> _timingStatus = {};
  int _refreshKey = 0; // 用于强制刷新 HabitCard

  @override
  void initState() {
    super.initState();
    // 添加生命周期监听
    WidgetsBinding.instance.addObserver(this);
    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    widget.controller.addTimerModeListener(_onTimerModeChanged);
    final activeTimers = habitsPlugin!.timerController.getActiveTimers();
    _timingStatus.addAll(activeTimers);
    EventManager.instance.subscribe('habit_timer_started', _onTimerStarted);
    EventManager.instance.subscribe('habit_timer_stopped', _onTimerStopped);
    _loadHabits();
  }

  @override
  void dispose() {
    // 移除生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    EventManager.instance.unsubscribe('habit_timer_started', _onTimerStarted);
    EventManager.instance.unsubscribe('habit_timer_stopped', _onTimerStopped);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 应用从后台恢复时重新加载数据
    if (state == AppLifecycleState.resumed) {
      debugPrint('CombinedHabitsView: 应用恢复，重新加载习惯数据');
      _reloadHabits();
    }
  }

  /// 从存储重新加载习惯数据（用于应用恢复时）
  Future<void> _reloadHabits() async {
    // 等待同步完成
    await Future.delayed(const Duration(milliseconds: 300));
    // 从存储重新加载
    final habits = await widget.controller.loadHabits();
    if (mounted) {
      setState(() {
        _habits = habits;
        _refreshKey++; // 增加 key 强制重建所有 HabitCard
      });
    }
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
    final habits = widget.controller.getHabits();
    if (mounted) {
      setState(() => _habits = habits);
    }
  }

  Future<void> _showHabitForm(BuildContext context, [Habit? habit]) async {
    final l10n = HabitsLocalizations.of(context);
    await NavigationHelper.push(context, Scaffold(
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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: HabitForm(
                initialHabit: habit,
                onSave: (habit) async {
                  await widget.controller.saveHabit(habit);
                  Navigator.pop(context);
                  _loadHabits();
                },),
      ),
    );
  }

  Widget _buildCardView(List<Habit> habits, HabitsLocalizations l10n) {
    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    final skillController = habitsPlugin?.getSkillController();

    return MasonryGridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final skill =
            habit.skillId != null
                ? skillController?.getSkillById(habit.skillId!)
                : null;

        return HabitCard(
          key: ValueKey('${habit.id}_$_refreshKey'),
          habit: habit,
          skill: skill,
          controller: widget.controller,
          onTap: () => _showHabitForm(context, habit),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);
    return Column(
      children: [
        HabitsAppBar(
          l10n: l10n,
          onAddPressed: () => _showHabitForm(context),
          onBackPressed: () => PluginManager.toHomeScreen(context),
        ),
        Expanded(
          child: _buildCardView(_habits, l10n),
        ),
      ],
    );
  }
}