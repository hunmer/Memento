import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/day/models/memorial_day.dart';
import 'information_tab.dart';
import 'notes_tab.dart';
import 'appearance_tab.dart';

class EditMemorialDayDialog extends StatefulWidget {
  final MemorialDay? memorialDay;

  const EditMemorialDayDialog({super.key, this.memorialDay});

  @override
  State<EditMemorialDayDialog> createState() => _EditMemorialDayDialogState();
}

class _EditMemorialDayDialogState extends State<EditMemorialDayDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late List<String> _notes;
  late Color _selectedColor;
  String? _backgroundImageUrl;
  late TabController _tabController;

  // 预定义的背景图片列表
  final List<String> _predefinedBackgroundImages = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb', // 自然风景
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memorialDay?.title);
    _selectedDate = widget.memorialDay?.targetDate ?? DateTime.now();
    _notes = List.from(widget.memorialDay?.notes ?? []);
    _selectedColor = widget.memorialDay?.backgroundColor ?? Colors.blue[300]!;
    _backgroundImageUrl = widget.memorialDay?.backgroundImageUrl;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = ;

    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.memorialDay == null
                ? localizations.addMemorialDay
                : localizations.editMemorialDay,
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.info_outline),
                text: localizations.information,
              ),
              Tab(icon: const Icon(Icons.notes), text: localizations.notes),
              Tab(
                icon: const Icon(Icons.palette_outlined),
                text: localizations.appearance,
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: TabBarView(
          controller: _tabController,
          children: [
            // 信息标签页
            InformationTab(
              titleController: _titleController,
              selectedDate: _selectedDate,
              onSelectDate: _selectDate,
              formatDate: _formatDate,
            ),

            // 笔记标签页
            NotesTab(
              notes: _notes,
              onAddNote: _addNote,
              onNoteChanged: _updateNote,
              onNoteRemoved: _removeNote,
            ),

            // 外观标签页
            AppearanceTab(
              selectedColor: _selectedColor,
              onColorSelected: _selectColor,
              backgroundImageUrl: _backgroundImageUrl,
              onBackgroundImageSelected: _selectBackgroundImage,
              predefinedBackgroundImages: _predefinedBackgroundImages,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              () => Navigator.of(
                context,
              ).pop(const DialogResult(action: DialogAction.cancel)),
          child: Text(localizations.cancel),
        ),
        if (widget.memorialDay != null)
          TextButton(
            onPressed: _confirmDelete,
            child: Text(
              localizations.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ElevatedButton(onPressed: _save, child: Text(localizations.save)),
      ],
    );
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
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

  void _updateNote(int index, String value) {
    setState(() {
      _notes[index] = value;
    });
  }

  void _removeNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _selectBackgroundImage(String? imageUrl) {
    setState(() {
      _backgroundImageUrl = imageUrl;
    });
  }

  void _save() {
    // 移除空笔记
    final filteredNotes =
        _notes.where((note) => note.trim().isNotEmpty).toList();

    final memorialDay = MemorialDay(
      id:
          widget.memorialDay?.id ??
          const Uuid().v4(),
      title: _titleController.text.trim(),
      targetDate: _selectedDate,
      notes: filteredNotes,
      backgroundColor: _selectedColor,
      backgroundImageUrl: _backgroundImageUrl,
      creationDate: widget.memorialDay?.creationDate ?? DateTime.now(),
    );

    Navigator.of(
      context,
    ).pop(DialogResult(action: DialogAction.save, memorialDay: memorialDay));
  }

  void _confirmDelete() {
    // 直接返回删除操作，具体的删除确认逻辑由外部处理
    Navigator.of(context).pop(const DialogResult(action: DialogAction.delete));
  }
}

/// 对话框操作结果
enum DialogAction { save, delete, cancel }

/// 对话框返回结果
class DialogResult {
  final DialogAction action;
  final MemorialDay? memorialDay;

  const DialogResult({required this.action, this.memorialDay});
}
