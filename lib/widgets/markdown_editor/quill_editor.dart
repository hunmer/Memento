import 'dart:convert';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class QuillEditorWidget extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent; // 支持 JSON Delta 格式或纯文本
  final bool showTitle;
  final String titleHint;
  final String contentHint;
  final Function(String title, String content) onSave;
  final VoidCallback? onCancel;
  final bool showSaveButton;
  final bool autofocus;
  final List<Widget>? actions;
  final List<Widget>? extraActions;

  const QuillEditorWidget({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.showTitle = true,
    this.titleHint = '输入标题...',
    this.contentHint = '输入内容...',
    required this.onSave,
    this.onCancel,
    this.showSaveButton = true,
    this.autofocus = true,
    this.actions,
    this.extraActions,
  });

  @override
  State<QuillEditorWidget> createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  late TextEditingController _titleController;
  late quill.QuillController _contentController;
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');

    // 初始化 Quill 控制器
    _contentController = _initializeQuillController(widget.initialContent);

    if (widget.autofocus) {
      _contentFocusNode.requestFocus();
    }
  }

  quill.QuillController _initializeQuillController(String? content) {
    if (content == null || content.isEmpty) {
      return quill.QuillController.basic();
    }

    try {
      // 尝试解析 JSON Delta 格式
      final json = jsonDecode(content);
      final document = quill.Document.fromJson(json);
      return quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // 如果不是 JSON，作为纯文本处理
      final document = quill.Document()..insert(0, content);
      return quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  String _getContentAsJson() {
    // 将 Delta 转换为 JSON 字符串
    final delta = _contentController.document.toDelta();
    return jsonEncode(delta.toJson());
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
    // 如果提供了自定义actions,则使用自定义actions
    if (widget.actions != null && widget.actions!.isNotEmpty) {
      return widget.actions!;
    }

    // 否则使用默认actions
    final defaultActions = <Widget>[
      if (widget.showSaveButton)
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () {
            final title = _titleController.text.trim();
            final content = _getContentAsJson();
            if (widget.showTitle && title.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.pleaseEnterTitle),
                ),
              );
              return;
            }
            widget.onSave(title, content);
          },
        ),
      if (widget.onCancel != null)
        IconButton(icon: const Icon(Icons.close), onPressed: widget.onCancel),
    ];

    // 如果有额外的actions,添加到默认actions后面
    if (widget.extraActions != null && widget.extraActions!.isNotEmpty) {
      defaultActions.addAll(widget.extraActions!);
    }

    return defaultActions;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: widget.showTitle ? _buildTitleField() : null,
          actions: _buildActions(),
        ),
        // Quill 工具栏
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            children: [
              quill.QuillToolbarHistoryButton(
                isUndo: true,
                controller: _contentController,
              ),
              quill.QuillToolbarHistoryButton(
                isUndo: false,
                controller: _contentController,
              ),
              quill.QuillToolbarToggleStyleButton(
                controller: _contentController,
                attribute: quill.Attribute.bold,
              ),
              quill.QuillToolbarToggleStyleButton(
                controller: _contentController,
                attribute: quill.Attribute.italic,
              ),
              quill.QuillToolbarToggleStyleButton(
                controller: _contentController,
                attribute: quill.Attribute.underline,
              ),
              quill.QuillToolbarToggleStyleButton(
                controller: _contentController,
                attribute: quill.Attribute.strikeThrough,
              ),
              quill.QuillToolbarClearFormatButton(
                controller: _contentController,
              ),
              const VerticalDivider(),
              quill.QuillToolbarColorButton(
                controller: _contentController,
                isBackground: false,
              ),
              quill.QuillToolbarColorButton(
                controller: _contentController,
                isBackground: true,
              ),
              const VerticalDivider(),
              quill.QuillToolbarSelectHeaderStyleDropdownButton(
                controller: _contentController,
              ),
              const VerticalDivider(),
              quill.QuillToolbarToggleCheckListButton(
                controller: _contentController,
              ),
              quill.QuillToolbarToggleStyleButton(
                controller: _contentController,
                attribute: quill.Attribute.ol,
              ),
              quill.QuillToolbarToggleStyleButton(
                controller: _contentController,
                attribute: quill.Attribute.ul,
              ),
              quill.QuillToolbarToggleStyleButton(
                controller: _contentController,
                attribute: quill.Attribute.inlineCode,
              ),
              quill.QuillToolbarToggleStyleButton(
                controller: _contentController,
                attribute: quill.Attribute.blockQuote,
              ),
              quill.QuillToolbarIndentButton(
                controller: _contentController,
                isIncrease: true,
              ),
              quill.QuillToolbarIndentButton(
                controller: _contentController,
                isIncrease: false,
              ),
              const VerticalDivider(),
              quill.QuillToolbarLinkStyleButton(
                controller: _contentController,
              ),
            ],
          ),
        ),
        // Quill 编辑器
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: quill.QuillEditor.basic(
              controller: _contentController,
              focusNode: _contentFocusNode,
            ),
          ),
        ),
      ],
    );
  }
}

// 为了向后兼容,提供 MarkdownEditor 别名
typedef MarkdownEditor = QuillEditorWidget;
