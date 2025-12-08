import 'package:Memento/plugins/notes/l10n/notes_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/controllers/notes_controller.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'folder_list_tile.dart';
import 'note_list_tile.dart';

class NotesListView extends StatelessWidget {
  final List<Folder> subFolders;
  final List<Note> notes;
  final NotesController controller;
  final Function(Folder) onNavigateToFolder;
  final VoidCallback onReload;
  final Future<Folder?> Function(Note?, {Folder? parentFolder})
  onShowFolderSelectionDialog;

  const NotesListView({
    super.key,
    required this.subFolders,
    required this.notes,
    required this.controller,
    required this.onNavigateToFolder,
    required this.onReload,
    required this.onShowFolderSelectionDialog,
  });

  @override
  Widget build(BuildContext context) {
    if (subFolders.isEmpty && notes.isEmpty) {
      return Center(child: Text(NotesLocalizations.of(context).emptyFolder));
    }

    return ReorderableListView.builder(
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }

        if (oldIndex < subFolders.length && newIndex < subFolders.length) {
          // 文件夹之间的排序
          final item = subFolders.removeAt(oldIndex);
          subFolders.insert(newIndex, item);
        } else if (oldIndex >= subFolders.length &&
            newIndex >= subFolders.length) {
          // 笔记之间的排序
          final noteOldIndex = oldIndex - subFolders.length;
          final noteNewIndex = newIndex - subFolders.length;
          final item = notes.removeAt(noteOldIndex);
          notes.insert(noteNewIndex, item);
        }
        // 不允许文件夹和笔记之间混排
      },
      itemCount: subFolders.length + notes.length,
      itemBuilder: (context, index) {
        if (index < subFolders.length) {
          return FolderListTile(
            key: Key('folder_${subFolders[index].id}'),
            folder: subFolders[index],
            controller: controller,
            onNavigateToFolder: onNavigateToFolder,
            onReload: onReload,
          );
        } else {
          final note = notes[index - subFolders.length];
          return NoteListTile(
            key: Key('note_${note.id}'),
            note: note,
            controller: controller,
            onReload: onReload,
            onShowFolderSelectionDialog: onShowFolderSelectionDialog,
          );
        }
      },
    );
  }
}
