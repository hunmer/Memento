import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:intl/intl.dart';

class MementoEditor extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent; // JSON Delta or Plain Text
  final String pageTitle; // e.g. "Create Diary"
  final DateTime? date;
  final String? mood; // Emoji
  final VoidCallback? onMoodTap;
  final Function(String title, String content) onSave;
  final VoidCallback? onClose;
  final String titleHint;
  final String contentHint;
  final List<Widget>? actions;

  const MementoEditor({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.pageTitle = 'Create Entry',
    this.date,
    this.mood,
    this.onMoodTap,
    required this.onSave,
    this.onClose,
    this.titleHint = 'Title',
    this.contentHint = 'Start writing...',
    this.actions,
  });

  @override
  State<MementoEditor> createState() => _MementoEditorState();
}

class _MementoEditorState extends State<MementoEditor> {
  late TextEditingController _titleController;
  late quill.QuillController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  final ScrollController _pageScrollController = ScrollController();
  
  // Word count state could be added here if needed, 
  // but QuillController has a listener we can use.
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = _initializeQuillController(widget.initialContent);
    
    _contentController.document.changes.listen((event) {
      _updateWordCount();
    });
    _updateWordCount();
  }

  void _updateWordCount() {
    final text = _contentController.document.toPlainText();
    // Simple word count approximation
    // Or character count for CJK? The HTML example says "108 字" which usually means characters in Chinese context.
    // Let's just use length for now or a smarter count.
    // For simplicity/common usage in Chinese apps:
    setState(() {
      _wordCount = text.trim().length; 
    });
  }

  quill.QuillController _initializeQuillController(String? content) {
    if (content == null || content.isEmpty) {
      return quill.QuillController.basic();
    }

    try {
      final json = jsonDecode(content);
      final document = quill.Document.fromJson(json);
      return quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
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
    _pageScrollController.dispose();
    super.dispose();
  }

  String _getContentAsJson() {
    final delta = _contentController.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = widget.date ?? DateTime.now();
    DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(date);
    DateFormat.EEEE(Localizations.localeOf(context).toString()).format(date);
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurface,
                      shape: const CircleBorder(),
                    ),
                  ),
                  Text(
                    widget.pageTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.actions != null)
                    Row(children: widget.actions!)
                  else
                    const SizedBox(width: 48), // Balance for the close button
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Input with Mood
                    Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        GestureDetector(
                          onTap: widget.onMoodTap,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              widget.mood ?? '😊',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.titleHint,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(left: 40),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          child: GestureDetector(
                            onTap: widget.onMoodTap,
                            child: Container( // Invisible hit target improvement
                              color: Colors.transparent,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Editor Container
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Toolbar
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // H1, H2
                                    quill.QuillToolbarSelectHeaderStyleDropdownButton(
                                      controller: _contentController,
                                    ),
                                    const SizedBox(width: 4),
                                    // Styles
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
                                    // Lists
                                    quill.QuillToolbarToggleStyleButton(
                                      controller: _contentController,
                                      attribute: quill.Attribute.ul,
                                    ),
                                    quill.QuillToolbarToggleStyleButton(
                                      controller: _contentController,
                                      attribute: quill.Attribute.ol,
                                    ),
                                    // Media
                                    QuillToolbarImageButton(
                                      controller: _contentController,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Editor Area
                            Expanded(
                              child: quill.QuillEditor.basic(
                                controller: _contentController,
                                focusNode: _contentFocusNode,
                                config: quill.QuillEditorConfig(
                                  placeholder: widget.contentHint,
                                  padding: const EdgeInsets.all(16),
                                  embedBuilders: kIsWeb
                                      ? FlutterQuillEmbeds.editorWebBuilders()
                                      : FlutterQuillEmbeds.editorBuilders(),
                                ),
                              ),
                            ),

                            // Word Count Footer
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '$_wordCount 字',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Save Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(_titleController.text, _getContentAsJson());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
