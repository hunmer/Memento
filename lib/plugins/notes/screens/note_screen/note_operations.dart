import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/nodes/l10n/nodes_localizations.dart';
import 'package:Memento/plugins/notes/l10n/notes_localizations.dart';
import 'package:flutter/material.dart';
import '../../controllers/notes_controller.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import '../note_edit_screen.dart';

// 创建新笔记
Future<void> createNewNote(
  BuildContext context,
  NotesController controller,
  String currentFolderId,
  VoidCallback onReload,
) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (context) => NoteEditScreen(
            onSave: (title, content) async {
              await controller.createNote(title, content, currentFolderId);
            },
          ),
    ),
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
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (context) => NoteEditScreen(
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
            },
          ),
    ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            NotesLocalizations.of(
              context,
            )!.movedToFolder.replaceFirst('{folderName}', targetFolder.name),
          ),
        ),
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
    await controller.deleteNote(note.id);
    onReload();
  }
}
