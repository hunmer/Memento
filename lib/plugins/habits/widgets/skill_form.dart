import 'dart:io';

import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/circle_icon_picker.dart';
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
  IconData? _icon;
  String? _image;
  Color _iconColor = Colors.blue;

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
    _icon =
        skill?.icon != null
            ? IconData(int.parse(skill!.icon!), fontFamily: 'MaterialIcons')
            : null;
    _image = skill?.image;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                          saveDirectory: 'habits/skill_images',
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
              SizedBox(
                width: 64,
                height: 64,
                child: CircleIconPicker(
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
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: HabitsLocalizations.of(context).skillName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: HabitsLocalizations.of(context).skillDescription,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _groupController,
            decoration: InputDecoration(
              labelText: HabitsLocalizations.of(context).skillGroup,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxDurationController,
            decoration: InputDecoration(
              labelText:
                  '${HabitsLocalizations.of(context).maxDuration} (${HabitsLocalizations.of(context).minutes})',
              hintText: HabitsLocalizations.of(context).noLimitHint,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
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
      icon: _icon?.codePoint.toString(),
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
