import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/nodes/l10n/nodes_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'folder_selection_dialog.dart';
import 'note_operations.dart';
import 'notes_screen_state.dart';

mixin NoteItem on NotesMainViewState, NoteOperations, FolderSelectionDialog {
  Widget buildNoteItem(Note note, int index) {
    return ListTile(
      key: Key('note_${note.id}'),
      title: Text(note.title),
      subtitle: Text(
        note.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => editNote(note),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder:
                (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text(AppLocalizations.of(context)!.edit),
                      onTap: () {
                        Navigator.pop(context);
                        editNote(note);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(NodesLocalizations.of(context).moveTo),
                      onTap: () {
                        Navigator.pop(context);
                        moveNote(note);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text(
                        '删除',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        deleteNote(note);
                      },
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }
}
