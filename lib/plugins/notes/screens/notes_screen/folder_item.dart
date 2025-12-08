import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'folder_operations.dart';
import 'notes_screen_state.dart';

mixin FolderItem on NotesMainViewState, FolderOperations {
  Widget buildFolderItem(Folder folder, int index) {
    return ListTile(
      key: Key('folder_${folder.id}'),
      leading: const Icon(Icons.folder),
      title: Text(folder.name),
      onTap: () => navigateToFolder(folder),
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
                      title: Text(AppLocalizations.of(context)!.rename),
                      onTap: () {
                        Navigator.pop(context);
                        renameFolder(folder);
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
                        deleteFolder(folder);
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
