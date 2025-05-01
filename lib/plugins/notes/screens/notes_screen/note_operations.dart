import 'package:flutter/material.dart';
import '../../l10n/notes_localizations.dart';
import '../../models/note.dart';
import '../note_edit_screen.dart';
import 'notes_screen_state.dart';

mixin NoteOperations on NotesScreenState {
  Future<void> createNewNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          onSave: (title, content) async {
            await widget.controller.createNote(
              title,
              content,
              currentFolderId,
            );
          },
        ),
      ),
    );
    loadCurrentFolder();
  }

  Future<void> editNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          note: note,
          onSave: (title, content) async {
            final updatedNote = Note(
              id: note.id,
              title: title,
              content: content,
              folderId: note.folderId,
              createdAt: note.createdAt,
              updatedAt: DateTime.now(),
              tags: note.tags,
            );
            await widget.controller.updateNote(updatedNote);
          },
        ),
      ),
    );
    loadCurrentFolder();
  }

  Future<void> deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(NotesLocalizations.of(context)?.deleteNote ?? 'Delete Note'),
        content: Text(NotesLocalizations.of(context)?.deleteNoteConfirm ?? 
          'Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.controller.deleteNote(note.id);
      loadCurrentFolder();
    }
  }
}