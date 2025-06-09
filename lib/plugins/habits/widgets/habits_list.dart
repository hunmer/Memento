import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:Memento/plugins/habits/widgets/habit_form.dart';

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

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await widget.controller.getHabits();
    setState(() => _habits = habits);
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
        _buildAppBar(context, l10n, groups),
        Expanded(
          child:
              _isCardView
                  ? _buildCardView(filteredHabits, l10n)
                  : _buildListView(filteredHabits, l10n),
        ),
      ],
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    HabitsLocalizations l10n,
    List<String> groups,
  ) {
    return AppBar(
      title: Text(l10n.habits),
      actions: [
        if (groups.isNotEmpty)
          DropdownButton<String>(
            value: _selectedGroup,
            hint: Text(l10n.group),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...groups.map(
                (group) => DropdownMenuItem(value: group, child: Text(group)),
              ),
            ],
            onChanged: (group) => setState(() => _selectedGroup = group),
          ),
        IconButton(icon: const Icon(Icons.sort), onPressed: _showSortMenu),
        IconButton(
          icon: Icon(_isCardView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => _isCardView = !_isCardView),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showHabitForm(context),
        ),
      ],
    );
  }

  Widget _buildListView(List<Habit> habits, HabitsLocalizations l10n) {
    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return ListTile(
          title: Text(habit.title),
          subtitle: Text('${habit.durationMinutes} ${l10n.minutes}'),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _startTimer(context, habit),
          ),
          onTap: () => _showHabitForm(context, habit),
        );
      },
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
        return Card(
          child: Column(
            children: [
              Expanded(
                child:
                    habit.image != null
                        ? Image.network(habit.image!)
                        : const Icon(Icons.auto_awesome, size: 48),
              ),
              Text(habit.title),
              Text('${habit.durationMinutes} ${l10n.minutes}'),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _startTimer(context, habit),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortMenu() {
    // TODO: Implement sorting logic
  }

  void _startTimer(BuildContext context, Habit habit) {
    // TODO: Implement timer dialog
  }

  Future<void> _showHabitForm(BuildContext context, [Habit? habit]) async {
    final l10n = HabitsLocalizations.of(context);
    final result = await Navigator.push(
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
}
