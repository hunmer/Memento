import 'package:get/get.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/todo/models/models.dart';

class FilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilter;
  final List<String> availableTags;

  const FilterDialog({
    super.key,
    required this.onFilter,
    required this.availableTags,
  });

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keywordController = TextEditingController();
  List<String> _selectedTags = [];
  TaskPriority? _selectedPriority;
  bool _showCompleted = true;
  bool _showIncomplete = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('todo_filterTasksTitle'.tr),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 关键词搜索
              TextFormField(
                controller: _keywordController,
                decoration: InputDecoration(
                  labelText: 'todo_searchIn'.tr,
                  hintText:
                      '${'todo_searchIn'.tr} ${'todo_title'.tr} & ${'todo_description'.tr}',
                ),
              ),
              const SizedBox(height: 16),

              // 优先级选择
              DropdownButtonFormField<TaskPriority>(
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'todo_priority'.tr,
                ),
                items:
                    TaskPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority.toString().split('.').last),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 标签选择
              InputChip(
                label: Text('todo_tags'.tr),
                onSelected: (_) => _showTagSelector(context),
                selected: _selectedTags.isNotEmpty,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children:
                    _selectedTags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            onDeleted: () {
                              setState(() {
                                _selectedTags.remove(tag);
                              });
                            },
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),

              // 日期范围
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _startDate == null
                            ? 'todo_startDate'.tr
                            : '${'todo_startDate'.tr}: ${_startDate!.toLocal()}',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        _endDate == null
                            ? 'todo_dueDate'.tr
                            : '${'todo_dueDate'.tr}: ${_endDate!.toLocal()}',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 完成状态
              Row(
                children: [
                  Checkbox(
                    value: _showCompleted,
                    onChanged: (value) {
                      setState(() {
                        _showCompleted = value ?? true;
                      });
                    },
                  ),
                  Text('todo_showCompleted'.tr),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _showIncomplete,
                    onChanged: (value) {
                      setState(() {
                        _showIncomplete = value ?? true;
                      });
                    },
                  ),
                  Text('todo_showIncomplete'.tr),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            final filter = {
              'keyword': _keywordController.text.trim(),
              'priority': _selectedPriority,
              'tags': _selectedTags,
              'startDate': _startDate,
              'endDate': _endDate,
              'showCompleted': _showCompleted,
              'showIncomplete': _showIncomplete,
            };
            widget.onFilter(filter);
          },
          child: Text('todo_ok'.tr),
        ),
      ],
    );
  }

  Future<void> _showTagSelector(BuildContext context) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder:
          (context) => MultiSelectDialog(
            items: widget.availableTags,
            initialSelected: _selectedTags,
          ),
    );
    if (selected != null) {
      setState(() {
        _selectedTags = selected;
      });
    }
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<String> items;
  final List<String> initialSelected;

  const MultiSelectDialog({
    super.key,
    required this.items,
    required this.initialSelected,
  });

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('todo_selectTagsTitle'.tr),
      content: SingleChildScrollView(
        child: Column(
          children:
              widget.items.map((item) {
                return CheckboxListTile(
                  title: Text(item),
                  value: _selectedItems.contains(item),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedItems.add(item);
                      } else {
                        _selectedItems.remove(item);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedItems),
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}
