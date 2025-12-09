import 'package:get/get.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/nodes/l10n/nodes_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/screens/note_edit_screen.dart';
import 'notes_screen_state.dart';

mixin NoteOperations on NotesMainViewState {
  Future<void> createNewNote() async {
    await NavigationHelper.push(context, NoteEditScreen(
              onSave: (title, content) async {
                await plugin.controller.createNote(
                  title,
                  content,
                  currentFolderId,
                );
              },),
    );
    loadCurrentFolder();
  }

  Future<void> editNote(Note note) async {
    await NavigationHelper.push(context, NoteEditScreen(
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
                await plugin.controller.updateNote(updatedNote);
              },),
    );
    loadCurrentFolder();
  }

  Future<void> deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'notes_deleteNote'.tr,
            ),
            content: Text(
              'notes_deleteNoteConfirm'.tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  NodesLocalizations.of(context).delete,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await plugin.controller.deleteNote(note.id);
      loadCurrentFolder();
    }
  }
}
