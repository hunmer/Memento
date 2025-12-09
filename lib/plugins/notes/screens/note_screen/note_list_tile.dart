import 'package:Memento/plugins/nodes/l10n/nodes_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/notes/controllers/notes_controller.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'note_operations.dart';

class NoteListTile extends StatelessWidget {
  final Note note;
  final NotesController controller;
  final VoidCallback onReload;
  final Future<Folder?> Function(Note?, {Folder? parentFolder})
  onShowFolderSelectionDialog;

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
            builder:
                (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text('app_edit'.tr),
                      onTap: () {
                        Navigator.pop(context);
                        editNote(context, controller, note, onReload);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(NodesLocalizations.of(context).moveTo),
                      onTap: () async {
                        Navigator.pop(context);
                        await moveNoteDialog(
                          context,
                          controller,
                          note,
                          onReload,
                          onShowFolderSelectionDialog,
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text(
                        '删除',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await deleteNoteDialog(
                          context,
                          controller,
                          note,
                          onReload,
                        );
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
