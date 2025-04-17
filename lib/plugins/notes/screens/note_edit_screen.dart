import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;
  final Function(String title, String content) onSave;

  const NoteEditScreen({
    Key? key,
    this.note,
    required this.onSave,
  }) : super(key: key);

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isPreviewMode = false;
  final FocusNode _contentFocusNode = FocusNode();
  int _currentCursorPosition = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _contentController.addListener(() {
      _currentCursorPosition = _contentController.selection.baseOffset;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _insertMarkdownSyntax(String syntax, {String? closingSyntax}) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final beforeText = text.substring(0, selection.start);
      final afterText = text.substring(selection.end);
      
      final newText = closingSyntax != null
          ? '$beforeText$syntax$selectedText$closingSyntax$afterText'
          : '$beforeText$syntax$selectedText$afterText';
      
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + syntax.length + selectedText.length + (closingSyntax?.length ?? 0),
        ),
      );
    } else {
      final beforeText = text.substring(0, _currentCursorPosition);
      final afterText = text.substring(_currentCursorPosition);
      
      final newText = closingSyntax != null
          ? '$beforeText$syntax$closingSyntax$afterText'
          : '$beforeText$syntax$afterText';
      
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: _currentCursorPosition + syntax.length,
        ),
      );
    }
    
    _contentFocusNode.requestFocus();
  }

  Widget _buildMarkdownToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.format_bold),
            tooltip: '粗体',
            onPressed: () => _insertMarkdownSyntax('**', closingSyntax: '**'),
          ),
          IconButton(
            icon: const Icon(Icons.format_italic),
            tooltip: '斜体',
            onPressed: () => _insertMarkdownSyntax('*', closingSyntax: '*'),
          ),
          IconButton(
            icon: const Icon(Icons.format_strikethrough),
            tooltip: '删除线',
            onPressed: () => _insertMarkdownSyntax('~~', closingSyntax: '~~'),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted),
            tooltip: '无序列表',
            onPressed: () => _insertMarkdownSyntax('- '),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            tooltip: '有序列表',
            onPressed: () => _insertMarkdownSyntax('1. '),
          ),
          IconButton(
            icon: const Icon(Icons.format_quote),
            tooltip: '引用',
            onPressed: () => _insertMarkdownSyntax('> '),
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: '代码块',
            onPressed: () => _insertMarkdownSyntax('```\\n', closingSyntax: '\\n```'),
          ),
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: '链接',
            onPressed: () => _insertMarkdownSyntax('[链接文字](', closingSyntax: ')'),
          ),
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: '图片',
            onPressed: () => _insertMarkdownSyntax('![图片描述](', closingSyntax: ')'),
          ),
          IconButton(
            icon: const Icon(Icons.title),
            tooltip: '标题',
            onPressed: () => _insertMarkdownSyntax('# '),
          ),
          IconButton(
            icon: const Icon(Icons.horizontal_rule),
            tooltip: '分隔线',
            onPressed: () => _insertMarkdownSyntax('---\\n'),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: '表格',
            onPressed: () => _insertMarkdownSyntax('''
| 列1 | 列2 | 列3 |
|-----|-----|-----|
| 内容 | 内容 | 内容 |
'''),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            hintText: '输入标题...',
            hintStyle: TextStyle(color: Colors.black54),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.preview),
            tooltip: _isPreviewMode ? '编辑模式' : '预览模式',
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              final title = _titleController.text.trim();
              final content = _contentController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入标题')),
                );
                return;
              }
              widget.onSave(title, content);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isPreviewMode) _buildMarkdownToolbar(),
          Expanded(
            child: _isPreviewMode
                ? Markdown(
                    data: _contentController.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      tableColumnWidth: const IntrinsicColumnWidth(),
                    ),
                  )
                : TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      hintText: '输入内容...',
                      border: InputBorder.none,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}