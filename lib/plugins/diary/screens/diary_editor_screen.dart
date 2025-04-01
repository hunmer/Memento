import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/storage/storage_manager.dart';
import '../utils/diary_utils.dart';

class DiaryEditorScreen extends StatefulWidget {
  final DateTime date;
  final StorageManager storage;
  final String initialContent;

  const DiaryEditorScreen({
    super.key,
    required this.date,
    required this.storage,
    required this.initialContent,
  });

  @override
  State<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends State<DiaryEditorScreen> {
  late TextEditingController _controller;
  bool _isPreview = false;
  final FocusNode _focusNode = FocusNode();
  String? _selectedMood;

  // 心情表情列表
  final List<String> _moods = [
    '😊',
    '😢',
    '😡',
    '😴',
    '🤔',
    '😎',
    '😍',
    '🤮',
    '😱',
    '🥳',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _loadCurrentMood();
  }

  Future<void> _loadCurrentMood() async {
    final entries = await DiaryUtils.loadDiaryEntries(widget.storage);
    final normalizedDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );

    if (entries.containsKey(normalizedDate)) {
      setState(() {
        _selectedMood = entries[normalizedDate]!.mood;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertMarkdownText(String markdown) {
    final text = _controller.text;
    final selection = _controller.selection;

    // 获取markdown格式的基本结构（不包含示例文本）
    String format = markdown;
    if (markdown.contains('**')) {
      format = '**';
    } else if (markdown.contains('*'))
      format = '*';
    else if (markdown.startsWith('- '))
      format = '- ';
    else if (markdown.startsWith('1. '))
      format = '1. ';
    else if (markdown.startsWith('> '))
      format = '> ';
    else if (markdown.contains('`'))
      format = '`';

    final newText = text.replaceRange(selection.start, selection.end, format);
    final newCursorPosition = selection.baseOffset + format.length;

    // 如果是表格，保持原有行为
    if (markdown.contains('|')) {
      _controller.value = TextEditingValue(
        text: text.replaceRange(selection.start, selection.end, markdown),
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + markdown.length,
        ),
      );
      return;
    }

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  Future<void> _saveDiary() async {
    final content = _controller.text;
    await DiaryUtils.saveDiaryEntry(
      widget.storage,
      widget.date,
      content,
      mood: _selectedMood,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showMoodSelector() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('选择今天的心情'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _moods.map((mood) {
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedMood = mood);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                mood == _selectedMood
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
      appBar: AppBar(
        title: Text(
          '${widget.date.year}年${widget.date.month}月${widget.date.day}日',
        ),
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.remove_red_eye),
            onPressed: () {
              setState(() {
                _isPreview = !_isPreview;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.mood),
            onPressed: _showMoodSelector,
            tooltip: '选择心情',
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.save),
                if (_selectedMood != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Text(
                      _selectedMood!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            onPressed: _saveDiary,
            tooltip: '保存日记',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isPreview
                    ? Markdown(data: _controller.text, selectable: true)
                    : TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(16),
                        hintText: '写下今天的故事...',
                        border: InputBorder.none,
                      ),
                    ),
          ),
          if (!_isPreview)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold),
                      onPressed: () => _insertMarkdownText('**粗体文字**'),
                      tooltip: '粗体',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic),
                      onPressed: () => _insertMarkdownText('*斜体文字*'),
                      tooltip: '斜体',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted),
                      onPressed: () => _insertMarkdownText('- 列表项\n'),
                      tooltip: '无序列表',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_numbered),
                      onPressed: () => _insertMarkdownText('1. 列表项\n'),
                      tooltip: '有序列表',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_quote),
                      onPressed: () => _insertMarkdownText('> 引用文字\n'),
                      tooltip: '引用',
                    ),
                    IconButton(
                      icon: const Icon(Icons.code),
                      onPressed: () => _insertMarkdownText('`代码`'),
                      tooltip: '代码',
                    ),
                    IconButton(
                      icon: const Icon(Icons.table_chart),
                      onPressed:
                          () => _insertMarkdownText('''
| 表头1 | 表头2 |
|-------|-------|
| 内容1 | 内容2 |
'''),
                      tooltip: '表格',
                    ),
                    IconButton(
                      icon: const Icon(Icons.insert_emoticon),
                      onPressed: () => _insertMarkdownText('😊'),
                      tooltip: '表情',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
