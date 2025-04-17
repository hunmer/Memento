import 'package:flutter/material.dart';
import '../../controllers/notes_controller.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import 'note_operations.dart';

class NoteListTile extends StatelessWidget {
  final Note note;
  final NotesController controller;
  final VoidCallback onReload;
  final Future<Folder?> Function(Note?, {Folder? parentFolder}) onShowFolderSelectionDialog;

  const NoteListTile({
    super.key,
    required this.note,
    required this.controller,
    required this.onReload,
    required this.onShowFolderSelectionDialog,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.note),
      title: Text(note.title),
      subtitle: Text(
        note.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => editNote(context, controller, note, onReload),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('编辑'),
                  onTap: () {
                    Navigator.pop(context);
                    editNote(context, controller, note, onReload);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('移动到'),
                  onTap: () async {
                    Navigator.pop(context);
                    await moveNoteDialog(context, controller, note, onReload, onShowFolderSelectionDialog);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('删除', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await deleteNoteDialog(context, controller, note, onReload);
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