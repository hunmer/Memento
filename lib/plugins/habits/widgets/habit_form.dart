import 'dart:io';

import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/circle_icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:path/path.dart' as path;

class HabitForm extends StatefulWidget {
  final Habit? initialHabit;
  final Function(Habit) onSave;

  const HabitForm({super.key, this.initialHabit, required this.onSave});

  @override
  State<HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<HabitForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _groupController;
  late final TextEditingController _durationController;
  late String? _selectedSkillId;
  List<Skill> _skills = [];
  IconData? _icon;
  String? _image;
  Color _iconColor = Colors.blue;
  final List<String> _tags = [];

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
    _selectedSkillId = habit?.skillId;
    _loadSkills();
    _icon =
        habit?.icon != null
            ? IconData(int.parse(habit!.icon!), fontFamily: 'MaterialIcons')
            : null;
    _image = habit?.image;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 图片和图标选择
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder:
                          (context) => ImagePickerDialog(
                            initialUrl: _image,
                            saveDirectory:
                                'habits${path.separator}habit_images',
                            enableCrop: true,
                            cropAspectRatio: 1.0,
                          ),
                    );
                    if (result != null && result['url'] != null) {
                      setState(() {
                        _image = result['url'] as String;
                      });
                    }
                  },
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child:
                          _image != null && _image!.isNotEmpty
                              ? FutureBuilder<String>(
                                future:
                                    _image!.startsWith('http')
                                        ? Future.value(_image!)
                                        : ImageUtils.getAbsolutePath(_image!),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Center(
                                      child: AspectRatio(
                                        aspectRatio: 1.0,
                                        child: ClipOval(
                                          child:
                                              _image!.startsWith('http')
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
                              : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '选择图片',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                CircleIconPicker(
                  currentIcon: _icon ?? Icons.check_rounded,
                  backgroundColor: _iconColor,
                  onIconSelected: (icon) {
                    setState(() {
                      _icon = icon;
                    });
                  },
                  onColorSelected: (color) {
                    setState(() {
                      _iconColor = color;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.title),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterTitle;
                }
                return null;
              },
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
            DropdownButtonFormField<String>(
              value:
                  _skills.any((s) => s.id == _selectedSkillId)
                      ? _selectedSkillId
                      : null,
              decoration: InputDecoration(labelText: '选择技能'),
              items: [
                DropdownMenuItem<String>(value: null, child: Text('请选择技能')),
                ..._skills.map((skill) {
                  return DropdownMenuItem<String>(
                    value: skill.id,
                    child: Text(skill.title),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSkillId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return '请选择技能';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _saveHabit();
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _saveHabit() {
    final habit = Habit(
      id: widget.initialHabit?.id ?? HabitsUtils.generateId(),
      title: _titleController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      group: _groupController.text.isEmpty ? null : _groupController.text,
      icon: _icon?.codePoint.toString(),
      image: _image,
      durationMinutes: int.tryParse(_durationController.text) ?? 30,
      skillId: _selectedSkillId,
      tags: _tags,
    );
    widget.onSave(habit);
  }

  Future<void> _loadSkills() async {
    try {
      final habitsPlugin = PluginManager.instance.getPlugin('habits');
      if (habitsPlugin != null && habitsPlugin is HabitsPlugin) {
        final controller = habitsPlugin.getSkillController();
        final skills = await controller.getSkills();
        setState(() {
          _skills = skills;
        });
      } else {
        debugPrint('Habits plugin not found or invalid');
        setState(() {
          _skills = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading skills: $e');
      setState(() {
        _skills = [];
      });
    }
  }
}
