import 'package:flutter/material.dart';
import '../../models/task_item.dart';
import '../../services/todo_service.dart';

class TaskFormFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController notesController;
  final String group;
  final Priority priority;
  final List<String> selectedTags;
  final TodoService todoService;
  final Function(String) onGroupChanged;
  final Function(Priority) onPriorityChanged;
  final Function(String, bool) onTagSelected;

  const TaskFormFields({
    super.key,
    required this.titleController,
    required this.subtitleController,
    required this.notesController,
    required this.group,
    required this.priority,
    required this.selectedTags,
    required this.todoService,
    required this.onGroupChanged,
    required this.onPriorityChanged,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleField(),
        const SizedBox(height: 16),
        _buildSubtitleField(),
        const SizedBox(height: 16),
        _buildGroupField(context),
        const SizedBox(height: 16),
        _buildPriorityField(context),
        const SizedBox(height: 16),
        _buildTagsField(context),
        const SizedBox(height: 16),
        _buildNotesField(),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: titleController,
      decoration: const InputDecoration(
        labelText: '任务标题',
        prefixIcon: Icon(Icons.task_alt),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入任务标题';
        }
        return null;
      },
    );
  }

  Widget _buildSubtitleField() {
    return TextFormField(
      controller: subtitleController,
      decoration: const InputDecoration(
        labelText: '副标题（可选）',
        prefixIcon: Icon(Icons.short_text),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  Widget _buildGroupField(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: group,
      decoration: const InputDecoration(
        labelText: '分组',
        prefixIcon: Icon(Icons.folder),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      items: [
        ...todoService.groups
            .map((group) => DropdownMenuItem(value: group, child: Text(group))),
        if (!todoService.groups.contains(''))
          const DropdownMenuItem(value: '', child: Text('无分组')),
      ],
      onChanged: (value) {
        if (value != null) {
          onGroupChanged(value);
        }
      },
    );
  }

  Widget _buildPriorityField(BuildContext context) {
    return DropdownButtonFormField<Priority>(
      value: priority,
      decoration: const InputDecoration(
        labelText: '优先级',
        prefixIcon: Icon(Icons.priority_high),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      items: Priority.values.map((priority) {
        String label;
        switch (priority) {
          case Priority.importantUrgent:
            label = '重要且紧急';
            break;
          case Priority.importantNotUrgent:
            label = '重要不紧急';
            break;
          case Priority.notImportantUrgent:
            label = '紧急不重要';
            break;
          case Priority.notImportantNotUrgent:
            label = '不重要不紧急';
            break;
        }
        return DropdownMenuItem(
          value: priority,
          child: Text(label),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onPriorityChanged(value);
        }
      },
    );
  }

  Widget _buildTagsField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.label, size: 20),
            SizedBox(width: 8),
            Text('标签', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: todoService.tags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
                showCheckmark: false,
                selectedColor:
                    Theme.of(context).primaryColor.withAlpha(51),
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                onSelected: (selected) => onTagSelected(tag, selected),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: notesController,
      decoration: const InputDecoration(
        labelText: '备注（可选）',
        prefixIcon: Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      maxLines: 21,
    );
  }
}