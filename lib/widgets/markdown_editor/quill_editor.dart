import 'dart:convert';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

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
  final ScrollController _toolbarScrollController = ScrollController();

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
    _toolbarScrollController.dispose();
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
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Listener(
            // 监听鼠标滚轮事件，将垂直滚动转换为水平滚动
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                // 计算滚动偏移量
                final offset = _toolbarScrollController.offset +
                    event.scrollDelta.dy;
                // 应用水平滚动
                _toolbarScrollController.jumpTo(
                  offset.clamp(
                    0.0,
                    _toolbarScrollController.position.maxScrollExtent,
                  ),
                );
              }
            },
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false, // 隐藏滚动条
              ),
              child: SingleChildScrollView(
                controller: _toolbarScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                // 历史操作
                quill.QuillToolbarHistoryButton(
                  isUndo: true,
                  controller: _contentController,
                ),
                quill.QuillToolbarHistoryButton(
                  isUndo: false,
                  controller: _contentController,
                ),
                const VerticalDivider(),

                // 文本样式
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
                quill.QuillToolbarToggleStyleButton(
                  controller: _contentController,
                  attribute: quill.Attribute.subscript,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _contentController,
                  attribute: quill.Attribute.superscript,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _contentController,
                  attribute: quill.Attribute.small,
                ),
                quill.QuillToolbarClearFormatButton(
                  controller: _contentController,
                ),
                const VerticalDivider(),

                // 字体和大小
                quill.QuillToolbarFontFamilyButton(
                  controller: _contentController,
                ),
                quill.QuillToolbarFontSizeButton(
                  controller: _contentController,
                ),
                const VerticalDivider(),

                // 颜色
                quill.QuillToolbarColorButton(
                  controller: _contentController,
                  isBackground: false,
                ),
                quill.QuillToolbarColorButton(
                  controller: _contentController,
                  isBackground: true,
                ),
                const VerticalDivider(),

                // 标题样式
                quill.QuillToolbarSelectHeaderStyleDropdownButton(
                  controller: _contentController,
                ),
                const VerticalDivider(),

                // 对齐方式
                quill.QuillToolbarSelectAlignmentButton(
                  controller: _contentController,
                ),
                const VerticalDivider(),

                // 列表
                quill.QuillToolbarToggleCheckListButton(
                  controller: _contentController,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _contentController,
                  attribute: quill.Attribute.ul,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _contentController,
                  attribute: quill.Attribute.ol,
                ),
                const VerticalDivider(),

                // 代码和引用
                quill.QuillToolbarToggleStyleButton(
                  controller: _contentController,
                  attribute: quill.Attribute.inlineCode,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _contentController,
                  attribute: quill.Attribute.codeBlock,
                ),
                quill.QuillToolbarToggleStyleButton(
                  controller: _contentController,
                  attribute: quill.Attribute.blockQuote,
                ),
                const VerticalDivider(),

                // 缩进
                quill.QuillToolbarIndentButton(
                  controller: _contentController,
                  isIncrease: true,
                ),
                quill.QuillToolbarIndentButton(
                  controller: _contentController,
                  isIncrease: false,
                ),
                const VerticalDivider(),

                // 链接和媒体
                quill.QuillToolbarLinkStyleButton(
                  controller: _contentController,
                ),
                QuillToolbarImageButton(
                  controller: _contentController,
                ),
                QuillToolbarVideoButton(
                  controller: _contentController,
                ),
                const VerticalDivider(),

                    // 搜索
                    quill.QuillToolbarSearchButton(
                      controller: _contentController,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Quill 编辑器
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: quill.QuillEditor.basic(
              controller: _contentController,
              focusNode: _contentFocusNode,
              config: quill.QuillEditorConfig(
                placeholder: widget.contentHint,
                embedBuilders: kIsWeb
                    ? FlutterQuillEmbeds.editorWebBuilders()
                    : FlutterQuillEmbeds.editorBuilders(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 为了向后兼容,提供 MarkdownEditor 别名
typedef MarkdownEditor = QuillEditorWidget;
