import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/widgets/markdown_editor/quill_editor.dart';

class NoteEditScreen extends StatelessWidget {
  final Note? note;
  final Function(String title, String content) onSave;

  const NoteEditScreen({super.key, this.note, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MarkdownEditor(
        initialTitle: note?.title,
        initialContent: note?.content,
        onSave: (title, content) {
          onSave(title, content);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
