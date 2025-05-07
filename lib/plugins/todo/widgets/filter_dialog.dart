
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/models.dart';

class FilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilter;
  final List<String> availableTags;

  const FilterDialog({
    Key? key,
    required this.onFilter,
    required this.availableTags,
  }) : super(key: key);

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
      title: const Text('Filter Tasks'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 关键词搜索
              TextFormField(
                controller: _keywordController,
                decoration: const InputDecoration(
                  labelText: 'Keyword',
                  hintText: 'Search in title & description',
                ),
              ),
              const SizedBox(height: 16),

              // 优先级选择
              DropdownButtonFormField<TaskPriority>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                ),
                items: TaskPriority.values.map((priority) {
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
                label: const Text('Tags'),
                onSelected: (_) => _showTagSelector(context),
                selected: _selectedTags.isNotEmpty,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: _selectedTags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() {
                      _selectedTags.remove(tag);
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),

              // 日期范围
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(_startDate == null 
                          ? 'Start Date' 
                          : 'Start: ${_startDate!.toLocal()}'),
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
                      title: Text(_endDate == null 
                          ? 'End Date' 
                          : 'End: ${_endDate!.toLocal()}'),
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
                  const Text('Show Completed'),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _showIncomplete,
                    onChanged: (value) {
                      setState(() {
                        _showIncomplete = value ?? true;
                      });
                    },
                  ),
                  const Text('Show Incomplete'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Future<void> _showTagSelector(BuildContext context) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => MultiSelectDialog(
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
    Key? key,
    required this.items,
    required this.initialSelected,
  }) : super(key: key);

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
      title: const Text('Select Tags'),
      content: SingleChildScrollView(
        child: Column(
          children: widget.items.map((item) {
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
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedItems),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
