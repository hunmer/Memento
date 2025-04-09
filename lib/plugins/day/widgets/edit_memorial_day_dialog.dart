import 'package:flutter/material.dart';
import '../models/memorial_day.dart';
import '../l10n/day_localizations.dart';

class EditMemorialDayDialog extends StatefulWidget {
  final MemorialDay? memorialDay;

  const EditMemorialDayDialog({
    super.key,
    this.memorialDay,
  });

  @override
  State<EditMemorialDayDialog> createState() => _EditMemorialDayDialogState();
}

class _EditMemorialDayDialogState extends State<EditMemorialDayDialog> {
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late List<String> _notes;
  late Color _selectedColor;
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memorialDay?.title);
    _selectedDate = widget.memorialDay?.targetDate ?? DateTime.now();
    _notes = List.from(widget.memorialDay?.notes ?? []);
    _selectedColor = widget.memorialDay?.backgroundColor ?? Colors.blue[300]!;
    _backgroundImageUrl = widget.memorialDay?.backgroundImageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = DayLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.memorialDay == null
          ? localizations.addMemorialDay
          : localizations.editMemorialDay),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: localizations.title,
                hintText: localizations.enterTitle,
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),

            // 日期选择
            Row(
              children: [
                Text(localizations.targetDate),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _selectDate,
                  child: Text(_formatDate(_selectedDate)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 笔记列表
            Text(localizations.notes),
            const SizedBox(height: 8),
            ..._buildNotesList(),
            TextButton.icon(
              onPressed: _addNote,
              icon: const Icon(Icons.add),
              label: Text(localizations.addNote),
            ),
            const SizedBox(height: 16),

            // 背景颜色选择
            Text(localizations.backgroundColor),
            const SizedBox(height: 8),
            _buildColorPicker(),
            const SizedBox(height: 16),

            // 背景图片URL输入
            TextField(
              decoration: InputDecoration(
                labelText: localizations.backgroundImage,
                hintText: 'https://',
              ),
              onChanged: (value) {
                setState(() {
                  _backgroundImageUrl = value.isEmpty ? null : value;
                });
              },
              controller: TextEditingController(text: _backgroundImageUrl),
            ),
          ],
        ),
      ),
      actions: [
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop('cancel'),
          child: Text(localizations.cancel),
        ),
        // 删除按钮（仅编辑时显示）
        if (widget.memorialDay != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop('delete');
            },
            child: Text(
              localizations.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        // 保存按钮
        TextButton(
          onPressed: _save,
          child: Text(localizations.save),
        ),
      ],
    );
  }

  List<Widget> _buildNotesList() {
    return _notes.asMap().entries.map((entry) {
      final index = entry.key;
      final note = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: DayLocalizations.of(context).enterNote,
                ),
                controller: TextEditingController(text: note),
                onChanged: (value) {
                  _notes[index] = value;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() {
                  _notes.removeAt(index);
                });
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.red[300]!,
      Colors.pink[300]!,
      Colors.purple[300]!,
      Colors.deepPurple[300]!,
      Colors.indigo[300]!,
      Colors.blue[300]!,
      Colors.lightBlue[300]!,
      Colors.cyan[300]!,
      Colors.teal[300]!,
      Colors.green[300]!,
      Colors.lightGreen[300]!,
      Colors.amber[300]!,
      Colors.orange[300]!,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedColor == color ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (_selectedColor == color)
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _addNote() {
    setState(() {
      _notes.add('');
    });
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(DayLocalizations.of(context).titleRequired),
        ),
      );
      return;
    }

    final memorialDay = MemorialDay(
      id: widget.memorialDay?.id,
      title: _titleController.text.trim(),
      targetDate: _selectedDate,
      notes: _notes.where((note) => note.trim().isNotEmpty).toList(),
      backgroundColor: _selectedColor,
      backgroundImageUrl: _backgroundImageUrl,
    );

    Navigator.of(context).pop(memorialDay);
  }
}