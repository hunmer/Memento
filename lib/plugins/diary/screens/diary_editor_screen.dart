import 'package:flutter/material.dart';
import '../../../core/storage/storage_manager.dart';
import '../../../widgets/markdown_editor/markdown_editor.dart';
import '../utils/diary_utils.dart';

class DiaryEditorScreen extends StatefulWidget {
  final DateTime date;
  final StorageManager storage;
  final String initialTitle;
  final String initialContent;

  const DiaryEditorScreen({
    super.key,
    required this.date,
    required this.storage,
    this.initialTitle = '',
    required this.initialContent,
  });

  @override
  State<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends State<DiaryEditorScreen> {
  String? _selectedMood;

  // 心情表情列表
  final List<String> _moods = [
    '😊', '😢', '😡', '😴', '🤔',
    '😎', '😍', '🤮', '😱', '🥳',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentEntry();
  }

  Future<void> _loadCurrentEntry() async {
    final entry = await DiaryUtils.loadDiaryEntry(widget.storage, widget.date);
    if (entry != null && mounted) {
      setState(() {
        _selectedMood = entry.mood;
      });
    }
  }

  void _showMoodSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择今天的心情'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _moods.map((mood) {
            return InkWell(
              onTap: () {
                setState(() => _selectedMood = mood);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: mood == _selectedMood
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(mood, style: const TextStyle(fontSize: 24)),
              ),
            );
          }).toList(),
        ),
        actions: [
          if (_selectedMood != null)
            TextButton(
              onPressed: () {
                setState(() => _selectedMood = null);
                Navigator.pop(context);
              },
              child: const Text('清除选择'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MarkdownEditor(
        initialTitle: widget.initialTitle,
        initialContent: widget.initialContent,
        titleHint: '给今天的日记起个标题...',
        contentHint: '写下今天的故事...',
        showTitle: true,
        onSave: (title, content) async {
          await DiaryUtils.saveDiaryEntry(
            widget.storage,
            widget.date,
            content,
            title: title,
            mood: _selectedMood,
          );
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        extraActions: [
          IconButton(
            icon: _selectedMood != null
                ? Text(_selectedMood!, style: const TextStyle(fontSize: 24))
                : const Icon(Icons.mood),
            onPressed: _showMoodSelector,
            tooltip: '选择心情',
          ),
        ],
      ),
    );
  }
}
