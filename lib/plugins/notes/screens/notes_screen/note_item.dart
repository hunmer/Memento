import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
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
          SmoothBottomSheet.show(
            context: context,
            builder:
                (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text('app_edit'.tr),
                      onTap: () {
                        Navigator.pop(context);
                        editNote(note);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text('notes_moveTo'.tr),
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
