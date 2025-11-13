import 'package:flutter/material.dart';
import '../models/filter_sort_config.dart';
import '../l10n/contact_localizations.dart';

class FilterDialog extends StatefulWidget {
  final FilterConfig initialFilter;
  final List<String> availableTags;
  final Function(FilterConfig) onApply;

  const FilterDialog({
    super.key,
    required this.initialFilter,
    required this.availableTags,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late TextEditingController _nameController;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _uncontactedDays;
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialFilter.nameKeyword,
    );
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _uncontactedDays = widget.initialFilter.uncontactedDays;
    _selectedTags = List.from(widget.initialFilter.selectedTags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _nameController.clear();
      _startDate = null;
      _endDate = null;
      _uncontactedDays = null;
      _selectedTags.clear();
    });
  }

  void _applyFilters() {
    final filter = FilterConfig(
      nameKeyword: _nameController.text.isEmpty ? null : _nameController.text,
      startDate: _startDate,
      endDate: _endDate,
      uncontactedDays: _uncontactedDays,
      selectedTags: _selectedTags,
    );
    widget.onApply(filter);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(ContactLocalizations.of(context).filter),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: ContactLocalizations.of(context).nameKeyword,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Text(ContactLocalizations.of(context).dateRange),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate == null
                          ? ContactLocalizations.of(context).startDate
                          : '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}',
                    ),
                  ),
                ),
                const Text(' - '),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _endDate == null
                          ? ContactLocalizations.of(context).endDate
                          : '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('${ContactLocalizations.of(context).uncontactedDays}:'),
            Slider(
              value: _uncontactedDays?.toDouble() ?? 0,
              min: 0,
              max: 365,
              divisions: 73,
              label:
                  _uncontactedDays == null || _uncontactedDays == 0
                      ? ContactLocalizations.of(context).noLimit
                      : '$_uncontactedDays ${ContactLocalizations.of(context).days}',
              onChanged: (value) {
                setState(() {
                  _uncontactedDays = value == 0 ? null : value.toInt();
                });
              },
            ),
            const SizedBox(height: 16),
            Text('${ContactLocalizations.of(context).tags}:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  widget.availableTags.map((tag) {
                    return FilterChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (selected) => _toggleTag(tag),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetFilters,
          child: Text(ContactLocalizations.of(context).reset ?? 'Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(ContactLocalizations.of(context).cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _applyFilters,
          child: Text(ContactLocalizations.of(context).save ?? 'Save'),
        ),
      ],
    );
  }
}
