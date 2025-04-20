import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownEditor extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final bool showTitle;
  final String titleHint;
  final String contentHint;
  final Function(String title, String content) onSave;
  final VoidCallback? onCancel;
  final bool showSaveButton;
  final bool showPreviewButton;
  final bool autofocus;

  const MarkdownEditor({
    Key? key,
    this.initialTitle,
    this.initialContent,
    this.showTitle = true,
    this.titleHint = '输入标题...',
    this.contentHint = '输入内容...',
    required this.onSave,
    this.onCancel,
    this.showSaveButton = true,
    this.showPreviewButton = true,
    this.autofocus = true,
  }) : super(key: key);

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isPreviewMode = false;
  final FocusNode _contentFocusNode = FocusNode();
  int _currentCursorPosition = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _contentController.addListener(() {
      _currentCursorPosition = _contentController.selection.baseOffset;
    });
    if (widget.autofocus) {
      _contentFocusNode.requestFocus();
    }
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

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: widget.titleHint,
        hintStyle: const TextStyle(color: Colors.black54),
        border: InputBorder.none,
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      if (widget.showPreviewButton)
        IconButton(
          icon: Icon(_isPreviewMode ? Icons.edit : Icons.preview),
          tooltip: _isPreviewMode ? '编辑模式' : '预览模式',
          onPressed: () {
            setState(() {
              _isPreviewMode = !_isPreviewMode;
            });
          },
        ),
      if (widget.showSaveButton)
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () {
            final title = _titleController.text.trim();
            final content = _contentController.text.trim();
            if (widget.showTitle && title.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入标题')),
              );
              return;
            }
            widget.onSave(title, content);
          },
        ),
      if (widget.onCancel != null)
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: widget.showTitle ? _buildTitleField() : null,
          actions: _buildActions(),
        ),
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
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(16),
                    hintText: widget.contentHint,
                    border: InputBorder.none,
                  ),
                ),
        ),
      ],
    );
  }
}