import 'package:Memento/plugins/nodes/l10n/nodes_localizations.dart';
import 'package:Memento/plugins/notes/l10n/notes_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/notes/controllers/notes_controller.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/screens/note_edit_screen.dart';
import 'package:Memento/core/services/toast_service.dart';

// 创建新笔记
Future<void> createNewNote(
  BuildContext context,
  NotesController controller,
  String currentFolderId,
  VoidCallback onReload,
) async {
  await NavigationHelper.push(context, NoteEditScreen(
            onSave: (title, content) async {
              await controller.createNote(title, content, currentFolderId);
            },),
  );
  onReload();
}

// 编辑笔记
Future<void> editNote(
  BuildContext context,
  NotesController controller,
  Note note,
  VoidCallback onReload,
) async {
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
              await controller.updateNote(updatedNote);
            },),
  );
  onReload();
}

// 移动笔记
Future<void> moveNoteDialog(
  BuildContext context,
  NotesController controller,
  Note note,
  VoidCallback onReload,
  Future<Folder?> Function(Note?, {Folder? parentFolder})
  onShowFolderSelectionDialog,
) async {
  final targetFolder = await onShowFolderSelectionDialog(note);
  if (targetFolder != null) {
    await controller.moveNote(note.id, targetFolder.id);
    onReload();
    if (context.mounted) {
      toastService.showToast(
        NotesLocalizations.of(
          context,
        ).movedToFolder.replaceFirst('{folderName}', targetFolder.name),
      );
    }
  }
}

// 删除笔记
Future<void> deleteNoteDialog(
  BuildContext context,
  NotesController controller,
  Note note,
  VoidCallback onReload,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(NodesLocalizations.of(context).deleteNote),
          content: Text(NodesLocalizations.of(context).deleteNoteConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('app_cancel'.tr),
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
    await controller.deleteNote(note.id);
    onReload();
  }
}
