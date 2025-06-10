import 'dart:io';

import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/utils/image_utils.dart';

class HabitsCardView extends StatefulWidget {
  final List<Habit> habits;
  final HabitsLocalizations l10n;
  final Function(Habit) onHabitPressed;
  final Function(Habit) onTimerPressed;

  const HabitsCardView({
    super.key,
    required this.habits,
    required this.l10n,
    required this.onHabitPressed,
    required this.onTimerPressed,
  });

  @override
  _HabitsCardViewState createState() => _HabitsCardViewState();
}

class _HabitsCardViewState extends State<HabitsCardView> {
  final Map<String, bool> _timingStatus = {};

  @override
  Widget build(BuildContext context) {
    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
      ),
      itemCount: widget.habits.length,
      itemBuilder: (context, index) {
        final habit = widget.habits[index];
        final isTiming =
            _timingStatus[habit.id] ??
            (habitsPlugin?.timerController.isHabitTiming(habit.id) ?? false);
        _timingStatus[habit.id] = isTiming;

        return Card(
          child: InkWell(
            onTap: () => widget.onHabitPressed(habit),
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
                                return Center(
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: ClipOval(
                                      child:
                                          habit.image!.startsWith('http')
                                              ? Image.network(
                                                snapshot.data!,
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.broken_image,
                                                    ),
                                              )
                                              : Image.file(
                                                File(snapshot.data!),
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.broken_image,
                                                    ),
                                              ),
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return const Icon(Icons.broken_image);
                              } else {
                                return const CircularProgressIndicator();
                              }
                            },
                          )
                          : const Icon(Icons.auto_awesome, size: 48),
                ),
                Text(habit.title),
                Text('${habit.durationMinutes} ${widget.l10n.minutes}'),
                IconButton(
                  icon: Icon(isTiming ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (!isTiming) {
                      widget.onTimerPressed(habit);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
