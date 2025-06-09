import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';

class HabitForm extends StatefulWidget {
  final Habit? initialHabit;
  final Function(Habit) onSave;

  const HabitForm({super.key, this.initialHabit, required this.onSave});

  @override
  State<HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<HabitForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _groupController;
  late final TextEditingController _durationController;
  String? _icon;
  String? _image;

  @override
  void initState() {
    super.initState();
    final habit = widget.initialHabit;
    _titleController = TextEditingController(text: habit?.title);
    _notesController = TextEditingController(text: habit?.notes);
    _groupController = TextEditingController(text: habit?.group);
    _durationController = TextEditingController(
      text: habit?.durationMinutes.toString() ?? '30',
    );
    _icon = habit?.icon;
    _image = habit?.image;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: l10n.title),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.notes),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _groupController,
            decoration: InputDecoration(labelText: l10n.group),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: '${l10n.duration} (${l10n.minutes})',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => ImagePickerDialog(initialUrl: _image),
              );
              if (result != null && result['url'] != null) {
                setState(() {
                  _image = result['url'];
                });
              }
            },
            child: const Text('选择图片'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _saveHabit, child: Text(l10n.save)),
        ],
      ),
    );
  }

  void _saveHabit() {
    final habit = Habit(
      id: widget.initialHabit?.id ?? HabitsUtils.generateId(),
      title: _titleController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      group: _groupController.text.isEmpty ? null : _groupController.text,
      icon: _icon,
      image: _image,
      durationMinutes: int.tryParse(_durationController.text) ?? 30,
    );
    widget.onSave(habit);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _groupController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
