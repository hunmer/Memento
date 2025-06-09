import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';

class SkillForm extends StatefulWidget {
  final Skill? initialSkill;
  final Function(Skill) onSave;

  const SkillForm({super.key, this.initialSkill, required this.onSave});

  @override
  State<SkillForm> createState() => _SkillFormState();
}

class _SkillFormState extends State<SkillForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _groupController;
  late final TextEditingController _maxDurationController;
  String? _icon;
  String? _image;

  @override
  void initState() {
    super.initState();
    final skill = widget.initialSkill;
    _titleController = TextEditingController(text: skill?.title);
    _notesController = TextEditingController(text: skill?.notes);
    _groupController = TextEditingController(text: skill?.group);
    _maxDurationController = TextEditingController(
      text: skill?.maxDurationMinutes.toString() ?? '0',
    );
    _icon = skill?.icon;
    _image = skill?.image;
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
            controller: _maxDurationController,
            decoration: InputDecoration(
              labelText: '${l10n.maxDuration} (${l10n.minutes})',
              hintText: '0 for no limit',
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
          ElevatedButton(onPressed: _saveSkill, child: Text(l10n.save)),
        ],
      ),
    );
  }

  void _saveSkill() {
    final skill = Skill(
      id: widget.initialSkill?.id ?? HabitsUtils.generateId(),
      title: _titleController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      group: _groupController.text.isEmpty ? null : _groupController.text,
      icon: _icon,
      image: _image,
      maxDurationMinutes: int.tryParse(_maxDurationController.text) ?? 0,
    );
    widget.onSave(skill);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _groupController.dispose();
    _maxDurationController.dispose();
    super.dispose();
  }
}
