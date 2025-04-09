import 'package:flutter/material.dart';
import '../../models/memorial_day.dart';
import '../../l10n/day_localizations.dart';
import 'information_tab.dart';
import 'notes_tab.dart';
import 'appearance_tab.dart';

class EditMemorialDayDialog extends StatefulWidget {
  final MemorialDay? memorialDay;

  const EditMemorialDayDialog({
    super.key,
    this.memorialDay,
  });

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
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e', // 海滩
    'https://images.unsplash.com/photo-1519681393784-d120267933ba', // 星空
    'https://images.unsplash.com/photo-1554080353-a576cf803bda', // 山脉
    'https://images.unsplash.com/photo-1490750967868-88aa4486c946', // 花朵
    'https://images.unsplash.com/photo-1513151233558-d860c5398176', // 城市
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470', // 日落
    'https://images.unsplash.com/photo-1515266591878-f93e32bc5937', // 雪景
    'https://images.unsplash.com/photo-1500964757637-c85e8a162699', // 田野
    'https://images.unsplash.com/photo-1532274402911-5a369e4c4bb5', // 森林
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
    final localizations = DayLocalizations.of(context);

    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.memorialDay == null
              ? localizations.addMemorialDay
              : localizations.editMemorialDay),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.info_outline),
                text: localizations.information,
              ),
              Tab(
                icon: const Icon(Icons.notes),
                text: localizations.notes,
              ),
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(localizations.save),
        ),
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
    final filteredNotes = _notes.where((note) => note.trim().isNotEmpty).toList();

    final memorialDay = MemorialDay(
      id: widget.memorialDay?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      targetDate: _selectedDate,
      notes: filteredNotes,
      backgroundColor: _selectedColor,
      backgroundImageUrl: _backgroundImageUrl,
      creationDate: widget.memorialDay?.creationDate ?? DateTime.now(),
    );

    Navigator.of(context).pop(memorialDay);
  }
}